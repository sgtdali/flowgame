class_name FactorySim
extends RefCounted

## Fabrikanın simülasyonu. Sahne ağacının TAMAMEN dışında.
##
## `Node` değil `RefCounted`: `_process` kullanmaz, GraphEdit'i tanımaz,
## headless koşabilir. Tick'i dışarıdan biri (Faz 3'te GameController) çağırır.
##
## DETERMİNİZM SÖZÜ: aynı durumdan başlayıp aynı sayıda tick koşan iki
## simülasyon bit bit aynı sonucu verir. Buna dayanan üç şey var —
## denge koşumu, kaydet/yükle tutarlılığı ve ileride offline kazanç.
## Bunu koruyan üç kural:
##   1. Tüm süreler tamsayı tick (float birikimli hata yapar)
##   2. İstasyonlar her zaman id sırasına göre işlenir (sözlük sırasına değil)
##   3. Rastgelelik yok — fire bile sayaçla belirlenir

## Sevkiyat bir ürünü yuttuğunda yayılır. Faz 4'te Economy buna bağlanacak.
signal item_sold(item: ItemType, count: int)

var tick_count: int = 0

## Faz 2'de sim kendi geliri sayar; Faz 4'te bu Economy'ye taşınacak.
##
## Bu, HARCANABİLİR (tahsil edilmiş) toplam — Sevkiyat'ta bekleyen tahsil
## edilmemiş para BURAYA sayılmaz (bkz. `SimStation.accrued`, `collect()`).
## `ProgressionState.balance()` bu alanı okur; tahsil edilmemiş para asla
## harcanamaz.
var revenue: int = 0
var sold_counts: Dictionary = {}

## Erken oyun deneyi: tahsilat OTOMATİK mi? Kapalıyken satış geliri her
## Sevkiyat istasyonunda BİRİKİR (`SimStation.accrued`), oyuncu `collect()`
## çağırana kadar `revenue`'ya eklenmez. Bir araştırma bunu açar (bkz.
## `ResearchNode.unlocks_auto_collect`) — sim kendisi ARAŞTIRMA bilmez,
## yalnızca bu düz bayrağı taşır (bkz. D8: sim ilerleme durumunu bilmez).
var auto_collect: bool = false

## Ürün id'si (String) -> satış fiyatı çarpanı. `auto_collect` İLE AYNI
## desen: sim kendisi ARAŞTIRMA/geliştirme bilmez, yalnızca dışarıdan
## (GameController, bkz. ProgressionState.item_sale_multiplier) verilen bu
## düz sözlüğe bakar. Eksik anahtar = çarpan 1.0 (taban fiyat).
var item_sale_multipliers: Dictionary = {}

## Ar-Ge Laboratuvarı'na akıtılan toplam ürün (kümülatif).
## Araştırma ilerlemesi buradan okunur — simülasyon araştırma DURUMUNU
## bilmez, sadece ne aktığını sayar. Böylece sim saf ve deterministik kalır.
var research_counts: Dictionary = {}


var _stations: Dictionary = {}        # id -> SimStation
var _ordered_ids: Array[int] = []     # her zaman artan sırada
var _links: Array[SimLink] = []
var _links_by_port: Dictionary = {}   # "from_id:port" -> Array[SimLink]

## Güç bağlantıları — malzeme `_links`'ten AYRI liste (bkz. `PowerLink`).
var _power_links: Array[PowerLink] = []

## Kompleksler istasyon listesinden ayrı tutulur: kompleks kurmak yeni bir
## üretim istasyonu yaratmaz, yalnızca mevcut istasyonların organizasyonudur.
var _complexes: Dictionary = {} # complex id -> IronworksComplex
var _station_complex: Dictionary = {} # station id -> complex id
var _next_complex_id: int = 1
var _complex_power_used: Dictionary = {} # generator id -> int, türetilmiş

## Bu tick'te her istasyona TESLİM EDİLEN güç: station id -> int.
## Sunum verisi değil, `_phase_power`'ın `_phase_produce`'a geçirdiği
## GEÇİCİ hesap — her tick baştan kurulur, kaydedilmez (bkz. `SimStation.
## status` gibi diğer türetilmiş alanlar).
var _delivered_power: Dictionary = {}

## Son GERÇEKTEN aktarılan ürün: "from_id:from_port" -> item_id.
##
## Tipsiz istasyonların (Dağıtıcı, Ara Depo) çıktısı bir tick içinde
## üret-fazında dolup taşı-fazında hemen boşalır — dışarıdan (sunum
## katmanından) o anki tamponu okumak neredeyse HER ZAMAN boş görür.
## Araştırma takip panelinin "bu hat hangi ürünü taşıyor" sorusu (bkz.
## `item_id_on_link`) bu yüzden ANLIK duruma değil, GERÇEKLEŞMİŞ son
## aktarıma bakar. Sunum verisi — kayıtta yer almaz, yeniden dolmasına bir
## iki tick yeter.
var _last_transferred_item: Dictionary = {}

## Bağlı portlar: "id:port" -> true. Her karede sorulduğu için önbellekte
## tutulur, bağlantı değişince yeniden kurulur.
var _wired_in: Dictionary = {}
var _wired_out: Dictionary = {}
var _next_id: int = 1


## --- Kurulum ----------------------------------------------------------------

func add_station(type: BlockType) -> int:
	var station := SimStation.new(_next_id, type)
	_next_id += 1
	_stations[station.id] = station
	_ordered_ids.append(station.id)
	_ordered_ids.sort()
	return station.id


func remove_station(id: int) -> void:
	if not _stations.has(id):
		return
	_stations.erase(id)
	_ordered_ids.erase(id)
	for i in range(_links.size() - 1, -1, -1):
		if _links[i].from_id == id or _links[i].to_id == id:
			_links.remove_at(i)
	for i in range(_power_links.size() - 1, -1, -1):
		if _power_links[i].from_id == id or _power_links[i].to_id == id:
			_power_links.remove_at(i)
	_delivered_power.erase(id)
	_remove_station_from_complex(id)
	for complex: IronworksComplex in complexes():
		complex.power_source_ids.erase(id)
	_rebuild_link_index()


func get_station(id: int) -> SimStation:
	return _stations.get(id, null)


func stations() -> Array[SimStation]:
	var out: Array[SimStation] = []
	for id: int in _ordered_ids:
		out.append(_stations[id])
	return out


func station_count() -> int:
	return _ordered_ids.size()


func link_count() -> int:
	return _links.size()


## Sevkiyattan çıkan toplam ürün adedi. Üst çubuğun hız göstergesi için.
func total_sold() -> int:
	var total: int = 0
	for count: int in sold_counts.values():
		total += count
	return total


func links() -> Array[SimLink]:
	var out: Array[SimLink] = []
	out.assign(_links)
	return out


## Belirli bir istasyona giren bağlantılar. Araştırma takip panelinin
## "bu ürünü laboratuvara hangi hat getiriyor" sorusu için.
func links_into(to_id: int) -> Array[SimLink]:
	var out: Array[SimLink] = []
	for link: SimLink in _links:
		if link.to_id == to_id:
			out.append(link)
	return out


## Bir bağlantı üzerinde HANGİ ürünün aktığı.
##
## Önce GERÇEKTEN AKTARILMIŞ son ürüne bakar (`_last_transferred_item`) —
## tipsiz istasyonların (Dağıtıcı, Ara Depo) anlık çıktı tamponu bir tick
## içinde dolup boşaldığı için dışarıdan okunduğunda neredeyse hep BOŞ
## görünür. Hiç aktarım olmadıysa (yeni kurulmuş, henüz akmamış bağlantı)
## `_port_item_id`'ye düşer — tipli kaynaklarda (reçeteden türeyen) bu zaten
## anlık duruma bakmaz, sabittir.
func item_id_on_link(link: SimLink) -> StringName:
	var key: String = "%d:%d" % [link.from_id, link.from_port]
	if _last_transferred_item.has(key):
		return _last_transferred_item[key]
	var src: SimStation = get_station(link.from_id)
	if src == null:
		return &""
	return _port_item_id(src, link.from_port)


## Bağlantı neden kurulamıyor? Boş string = sorun yok.
##
## Kural ve mesaj TEK yerde. Arayüz kendi kopyasını tutsaydı er geç ayrışırdı.
func connection_problem(from_id: int, from_port: int, to_id: int, to_port: int) -> String:
	if from_id == to_id:
		return "A workshop cannot connect to itself."
	var src: SimStation = get_station(from_id)
	var dst: SimStation = get_station(to_id)
	if src == null or dst == null:
		return "Workshop not found."
	if to_port < 0 or to_port >= dst.input_port_count:
		return "Invalid input port."
	for link: SimLink in _links:
		if link.matches(from_id, from_port, to_id, to_port):
			return "This route already exists."

	# Kaynaklar tek çıkış portunu istediği kadar hatta bölebilir. Diğer
	# istasyonlarda tek port = tek hat kuralı sürer; bunları bölmek için
	# Crossroads kullanılmalıdır.
	if not src.type.splits_output:
		for link: SimLink in _links:
			if link.from_id == from_id and link.from_port == from_port:
				return "This output is already linked. Use a Crossroads to split a route."

	var out_items: Array[ItemType] = src.type.output_items()
	if not out_items.is_empty() and from_port >= out_items.size():
		return "Invalid output port."

	# Trade Depot gibi TALEP KAPILI bloklar: port 0 herhangi bir satılabilir
	# ürünü kabul eder (Talep hariç), port 1 SADECE Talep kabul eder. Jenerik
	# giriş kuralının (bkz. altta) port başına ikiye ayrışmış hâli — normal
	# jenerik bloklarda (Ara Depo, Sevkiyat) TÜM portlar aynı kuralı paylaşır.
	if dst.type.demand_item != null:
		var demand_port: int = 0 if dst.type.power_trade_item != null else 1
		if to_port == demand_port:
			if not out_items.is_empty() and out_items[from_port].id != dst.type.demand_item.id:
				return "%s cannot enter here. This input expects %s." % [
					out_items[from_port].display_name, dst.type.demand_item.display_name]
			return ""
		if dst.type.power_trade_item == null and to_port == 0:
			if not out_items.is_empty() and out_items[from_port].id == dst.type.demand_item.id:
				return "Demand cannot enter the goods input — use the Demand port."
			return ""
		return "Invalid input port."

	var in_items: Array[ItemType] = dst.type.input_items()
	if in_items.is_empty():
		return ""  # jenerik giriş: tampon ve sevkiyat her ürünü kabul eder
	if to_port >= in_items.size():
		return "Invalid input port."
	if out_items.is_empty():
		return ""  # tamponun çıkışı: tip belli değil, taşıma anında bakılır
	if out_items[from_port] != in_items[to_port]:
		return "%s cannot enter here. This input expects %s." % [
			out_items[from_port].display_name, in_items[to_port].display_name]
	return ""


func can_connect(from_id: int, from_port: int, to_id: int, to_port: int) -> bool:
	return connection_problem(from_id, from_port, to_id, to_port).is_empty()


func connect_stations(from_id: int, from_port: int, to_id: int, to_port: int) -> bool:
	if not can_connect(from_id, from_port, to_id, to_port):
		return false
	_links.append(SimLink.new(from_id, from_port, to_id, to_port))
	_rebuild_link_index()
	return true


func disconnect_stations(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	for i in range(_links.size() - 1, -1, -1):
		if _links[i].matches(from_id, from_port, to_id, to_port):
			_links.remove_at(i)
	_rebuild_link_index()


func clear() -> void:
	_stations.clear()
	_ordered_ids.clear()
	_links.clear()
	_links_by_port.clear()
	_wired_in.clear()
	_wired_out.clear()
	_last_transferred_item.clear()
	_power_links.clear()
	_complexes.clear()
	_station_complex.clear()
	_complex_power_used.clear()
	_next_complex_id = 1
	_delivered_power.clear()
	_next_id = 1
	tick_count = 0
	revenue = 0
	sold_counts.clear()
	research_counts.clear()
	auto_collect = false


## --- Güç bağlantıları ---------------------------------------------------

## Bir güç bağlantısı neden kurulamıyor? Boş string = sorun yok.
## Malzeme bağlantılarındaki `connection_problem` ile aynı desen: kural TEK
## yerde yaşar, arayüz kopyasını tutmaz.
func power_connection_problem(from_id: int, to_id: int) -> String:
	if from_id == to_id:
		return "A workshop cannot connect to itself."
	var src: SimStation = get_station(from_id)
	var dst: SimStation = get_station(to_id)
	if src == null or dst == null:
		return "Workshop not found."
	if not src.type.is_power_generator():
		return "%s does not generate power." % src.type.display_name
	if not (dst.type.is_power_consumer() or dst.type.sells_power):
		return "%s cannot use power." % dst.type.display_name
	if _station_uses_power_bus(to_id):
		return "%s already uses its complex Power Bus." % dst.type.display_name
	for link: PowerLink in _power_links:
		if link.matches(from_id, to_id):
			return "This power line already exists."
	# Basit paylaşım kuralı: bir tüketici yalnızca TEK jeneratörden beslenir.
	# Birden fazla jeneratör bağlansaydı paylaşım kuralı belirsizleşirdi
	# (bkz. D5: bu turda karmaşık öncelik/oran yönetimi eklenmiyor).
	for link: PowerLink in _power_links:
		if link.to_id == to_id:
			return "This workshop already draws power from another generator."
	return ""


func can_connect_power(from_id: int, to_id: int) -> bool:
	return power_connection_problem(from_id, to_id).is_empty()


func connect_power(from_id: int, to_id: int) -> bool:
	if not can_connect_power(from_id, to_id):
		return false
	_power_links.append(PowerLink.new(from_id, to_id))
	return true


func disconnect_power(from_id: int, to_id: int) -> void:
	for i in range(_power_links.size() - 1, -1, -1):
		if _power_links[i].matches(from_id, to_id):
			_power_links.remove_at(i)


func power_links() -> Array[PowerLink]:
	var out: Array[PowerLink] = []
	out.assign(_power_links)
	return out


## Bu istasyona BU TICK teslim edilen güç. Sunum katmanı canlı "X / Y kW"
## göstergesi için bunu okur.
func delivered_power(station_id: int) -> int:
	return int(_delivered_power.get(station_id, 0))


func power_capacity(station_id: int) -> int:
	var station: SimStation = get_station(station_id)
	if station == null or not station.type.is_power_generator():
		return 0
	return station.type.power_output_at_level(station.level)


## Bir jeneratörün BU TICK dağıttığı toplam güç (üretim + satış dahil).
## Sunum katmanının "X / Y kW kullanımda" göstergesi için.
func power_used(station_id: int) -> int:
	var total: int = 0
	for link: PowerLink in _power_links:
		if link.from_id == station_id:
			total += delivered_power(link.to_id)
	return total + int(_complex_power_used.get(station_id, 0))


## --- Ironworks Complex -----------------------------------------------------

func complexes() -> Array[IronworksComplex]:
	var out: Array[IronworksComplex] = []
	var ids: Array = _complexes.keys()
	ids.sort()
	for complex_id: int in ids:
		out.append(_complexes[complex_id])
	return out


func get_complex(complex_id: int) -> IronworksComplex:
	return _complexes.get(complex_id, null)


func complex_for_station(station_id: int) -> IronworksComplex:
	return get_complex(int(_station_complex.get(station_id, -1)))


func create_complex(station_ids: Array[int], display_name: String = "") -> int:
	var unique: Array[int] = []
	for station_id: int in station_ids:
		if not unique.has(station_id):
			unique.append(station_id)
	unique.sort()
	if unique.size() < 2 or not _selected_stations_form_network(unique):
		return -1
	for station_id: int in unique:
		if not _can_join_complex(station_id):
			return -1
	var complex := IronworksComplex.new(_next_complex_id, display_name)
	_next_complex_id += 1
	complex.station_ids.assign(unique)
	_complexes[complex.id] = complex
	for station_id: int in unique:
		_station_complex[station_id] = complex.id
	return complex.id


func create_empty_complex(display_name: String = "") -> int:
	var complex := IronworksComplex.new(_next_complex_id, display_name)
	_next_complex_id += 1
	_complexes[complex.id] = complex
	return complex.id


func add_station_to_complex(complex_id: int, station_id: int) -> String:
	var complex: IronworksComplex = get_complex(complex_id)
	if complex == null:
		return "Complex not found."
	if not _can_join_complex(station_id):
		return "Only unassigned Extractors, Smelting Hearths, and Rolling Mills can join this complex."
	complex.station_ids.append(station_id)
	complex.station_ids.sort()
	_station_complex[station_id] = complex_id
	return ""


func set_complex_material_mode(complex_id: int, station_id: int, port: int, is_input: bool, shared: bool) -> String:
	var complex: IronworksComplex = get_complex(complex_id)
	if complex == null or not complex.contains(station_id):
		return "Workshop is not inside this complex."
	var key: String = IronworksComplex.port_key(station_id, port)
	if shared and _has_direct_material_link(station_id, port, is_input):
		return "Disconnect the direct material route before using the Material Bus."
	var modes: Dictionary = complex.shared_inputs if is_input else complex.shared_outputs
	if shared:
		modes[key] = true
	else:
		modes.erase(key)
	return ""


func set_complex_power_bus_member(complex_id: int, station_id: int, enabled: bool) -> String:
	var complex: IronworksComplex = get_complex(complex_id)
	var station: SimStation = get_station(station_id)
	if complex == null or station == null or not complex.contains(station_id) or not station.type.is_power_consumer():
		return "Only a powered workshop inside this complex can use its Power Bus."
	if enabled:
		for link: PowerLink in _power_links:
			if link.to_id == station_id:
				return "Disconnect the direct power line before using the Power Bus."
		complex.power_bus_members[station_id] = true
	else:
		complex.power_bus_members.erase(station_id)
	return ""


func connect_power_to_complex(generator_id: int, complex_id: int) -> String:
	var generator: SimStation = get_station(generator_id)
	var complex: IronworksComplex = get_complex(complex_id)
	if generator == null or complex == null:
		return "Generator or complex not found."
	if not generator.type.is_power_generator() or complex.contains(generator_id):
		return "An external Generator is required."
	if not complex.power_source_ids.has(generator_id):
		complex.power_source_ids.append(generator_id)
		complex.power_source_ids.sort()
	return ""


func set_complex_strategy(complex_id: int, strategy: IronworksComplex.Strategy) -> void:
	var complex: IronworksComplex = get_complex(complex_id)
	if complex != null:
		complex.strategy = strategy


func _can_join_complex(station_id: int) -> bool:
	if _station_complex.has(station_id):
		return false
	var station: SimStation = get_station(station_id)
	if station == null:
		return false
	return station.type.id in [&"mine_extractor", &"eritme", &"pres"]


func _selected_stations_form_network(ids: Array[int]) -> bool:
	var seen: Dictionary = {ids[0]: true}
	var pending: Array[int] = [ids[0]]
	while not pending.is_empty():
		var current: int = pending.pop_front()
		for link: SimLink in _links:
			var neighbour: int = -1
			if link.from_id == current and ids.has(link.to_id):
				neighbour = link.to_id
			elif link.to_id == current and ids.has(link.from_id):
				neighbour = link.from_id
			if neighbour >= 0 and not seen.has(neighbour):
				seen[neighbour] = true
				pending.append(neighbour)
	return seen.size() == ids.size()


func _remove_station_from_complex(station_id: int) -> void:
	var complex: IronworksComplex = complex_for_station(station_id)
	if complex == null:
		return
	complex.station_ids.erase(station_id)
	complex.shared_inputs.erase(IronworksComplex.port_key(station_id, 0))
	complex.shared_outputs.erase(IronworksComplex.port_key(station_id, 0))
	complex.power_bus_members.erase(station_id)
	_station_complex.erase(station_id)


func _has_direct_material_link(station_id: int, port: int, is_input: bool) -> bool:
	for link: SimLink in _links:
		if is_input and link.to_id == station_id and link.to_port == port:
			return true
		if not is_input and link.from_id == station_id and link.from_port == port:
			return true
	return false


func _station_uses_power_bus(station_id: int) -> bool:
	var complex: IronworksComplex = complex_for_station(station_id)
	return complex != null and complex.power_bus_members.has(station_id)


func _uses_shared_input(station: SimStation, port: int) -> bool:
	var complex: IronworksComplex = complex_for_station(station.id)
	return complex != null and complex.shared_inputs.has(IronworksComplex.port_key(station.id, port))


func _uses_shared_output(station: SimStation, port: int) -> bool:
	var complex: IronworksComplex = complex_for_station(station.id)
	return complex != null and complex.shared_outputs.has(IronworksComplex.port_key(station.id, port))


func _rebuild_link_index() -> void:
	_links_by_port.clear()
	_wired_in.clear()
	_wired_out.clear()
	for link: SimLink in _links:
		var key: String = "%d:%d" % [link.from_id, link.from_port]
		if not _links_by_port.has(key):
			_links_by_port[key] = []
		_links_by_port[key].append(link)
		_wired_out[key] = true
		_wired_in["%d:%d" % [link.to_id, link.to_port]] = true
	# Artık bağlı olmayan portların eski "son aktarılan ürün" izi kalmasın —
	# port başka bir ürüne yeniden bağlanırsa yanıltıcı olurdu.
	for key: String in _last_transferred_item.keys():
		if not _links_by_port.has(key):
			_last_transferred_item.erase(key)
	_sync_collector_input_ports()


## Collector her zaman bağlı son girişin altında BİR boş port tutar. Böylece
## satış hattı bağlanır bağlanmaz oyuncu ikinci hattı ekleyebilir; port sayısı
## sabit bir veri limiti değildir.
func _sync_collector_input_ports() -> void:
	for station: SimStation in _stations.values():
		if station.type.category != BlockType.Category.SINK:
			continue
		var highest_connected_port: int = -1
		for link: SimLink in _links:
			if link.to_id == station.id:
				highest_connected_port = maxi(highest_connected_port, link.to_port)
		station.input_port_count = highest_connected_port + 2


## Bu istasyonun kaç portu boşta?
##
## Boşta port = kurulum hatası, akış sorunu değil. Girişi olan her port bir
## yerden beslenmeli, çıkışı olan her port bir yere gitmeli. Bağlamayı
## unutulan bir port sessizce üretim kaybettirir — özellikle Kalite
## Kontrol'ün Ret portu.
##
## Yanlış TİPTE bağlantı burada aranmaz; `connection_problem` onu zaten
## en baştan engelliyor, yani kurulmuş bir bağlantı her zaman geçerlidir.
func unwired_port_count(id: int) -> int:
	var station: SimStation = get_station(id)
	if station == null:
		return 0
	# Collector'daki girişler isteğe bağlı satış hatlarıdır. Boşta duran
	# "bir sonraki" port kurulum hatası değildir.
	if station.type.category == BlockType.Category.SINK:
		return 0
	var missing: int = 0
	for port in station.input_port_count:
		if not _wired_in.has("%d:%d" % [id, port]):
			missing += 1
	for port in station.output_port_count:
		if not _wired_out.has("%d:%d" % [id, port]):
			missing += 1
	return missing


## --- Tick -------------------------------------------------------------------

func tick() -> void:
	tick_count += 1
	_phase_power()
	_phase_produce()
	_phase_transfer()


## Faz 0: güç dağıtımı. Üretimden ÖNCE çalışmalı — güç tüketen bir istasyon
## bu tick ne kadar enerji alacağını bilmeden ilerleyemez (bkz. `_run_producer`).
##
## Paylaşım kuralı basit ve deterministik (D5): her jeneratör kapasitesini
## KENDİNE bağlı tüketicilere id sırasına göre dağıtır, ÜRETİM tüketicileri
## (Elektrikli Hadde gibi) önce doyurulur, kalan kapasite satış noktalarına
## gider. Aynı elektrik iki kez sayılmaz — her tüketici en fazla bir
## jeneratöre bağlıdır (bkz. `power_connection_problem`).
func _phase_power() -> void:
	_delivered_power.clear()
	_complex_power_used.clear()
	for id: int in _ordered_ids:
		var generator: SimStation = _stations[id]
		if not generator.type.is_power_generator():
			continue
		var direct_ids: Array[int] = []
		for link: PowerLink in _power_links:
			if link.from_id != id:
				continue
			var dst: SimStation = get_station(link.to_id)
			if dst == null:
				continue
			direct_ids.append(dst.id)
		direct_ids.sort()

		# Generator bir kaynak çıkışıdır: iki doğrudan hat varsa kapasitesini
		# 2'ye, üç hat varsa 3'e böler. Tamsayı bölünmeyen birimler sabit id
		# sırasıyla ilk kollara gider; toplam asla kapasiteyi aşmaz.
		if not direct_ids.is_empty():
			var capacity: int = generator.type.power_output_at_level(generator.level)
			var share: int = capacity / direct_ids.size()
			var extra: int = capacity % direct_ids.size()
			for index in direct_ids.size():
				_delivered_power[direct_ids[index]] = share + (1 if index < extra else 0)
			continue

		var remaining: int = generator.type.power_output_at_level(generator.level)

		# Kompleks tüketicileri dış jeneratörden TEK bir kapasite havuzu olarak
		# pay alır. Doğrudan bağlı makinelerin eski öncelik davranışı korunur;
		# güç satışı ise yalnızca kompleks ve doğrudan üretimden sonra kalanı alır.
		var complex_consumers: Array[Dictionary] = []
		for complex: IronworksComplex in complexes():
			if not complex.power_source_ids.has(id):
				continue
			for station_id: int in complex.station_ids:
				if not complex.power_bus_members.has(station_id):
					continue
				var member: SimStation = get_station(station_id)
				if member != null and _wants_power(member):
					complex_consumers.append({"id": station_id, "request": member.type.power_required_per_tick})
		complex_consumers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
		if not complex_consumers.is_empty() and remaining > 0:
			var requested: int = 0
			for consumer: Dictionary in complex_consumers:
				requested += int(consumer["request"])
			var budget: int = mini(remaining, requested)
			var assigned: int = 0
			for consumer: Dictionary in complex_consumers:
				var share: int = budget * int(consumer["request"]) / requested
				_delivered_power[int(consumer["id"])] = int(_delivered_power.get(int(consumer["id"]), 0)) + share
				assigned += share
			# Bölünmeyen birimler sabit id sırasıyla dağıtılır; aynı başlangıç
			# durumundan her koşumda aynı sonuç çıkar.
			var remainder: int = budget - assigned
			for i in remainder:
				var target_id: int = int(complex_consumers[i % complex_consumers.size()]["id"])
				_delivered_power[target_id] = int(_delivered_power.get(target_id, 0)) + 1
			_complex_power_used[id] = int(_complex_power_used.get(id, 0)) + budget
			remaining -= budget



## Bir üretim tüketicisi BU TICK güç istiyor mu? Yalnızca zaten üretiyorsa
## veya reçetesini başlatacak malzemesi hazırsa istekte bulunur — bağlı ama
## boşta duran bir istasyon jeneratörü boşuna kilitlemez, kapasite satışa gider.
func _wants_power(station: SimStation) -> bool:
	if station.producing:
		return true
	var recipe: Recipe = station.recipe()
	if recipe == null:
		return false
	for port in recipe.inputs.size():
		var slot: RecipeSlot = recipe.inputs[port]
		if _uses_shared_input(station, port):
			if not _can_consume_from_bus(station, slot.item.id, slot.count):
				return false
		elif int(station.input.get(slot.item.id, 0)) < slot.count:
			return false
	return true


## Faz 1: üret / ilerlet.
func _phase_produce() -> void:
	for id: int in _ordered_ids:
		var station: SimStation = _stations[id]
		match station.type.category:
			BlockType.Category.BUFFER, BlockType.Category.SPLITTER:
				_run_buffer(station)
			BlockType.Category.SINK:
				_run_sink(station)
			BlockType.Category.RESEARCH:
				_run_research(station)
			_:
				_run_producer(station)


## Faz 2: çıktıdan komşunun girdisine taşı.
##
## Üretimden AYRI olması şart. Tek fazda olsaydı id'si küçük zincirler bir
## tick'te baştan sona akar, büyükler beklerdi — sonuç istasyon sırasına
## bağlı olurdu. Ayırınca "bir tick'te her ürün en fazla bir adım" garantisi
## doğar; boru hattı hissi de buradan gelir.
func _phase_transfer() -> void:
	for id: int in _ordered_ids:
		var station: SimStation = _stations[id]
		if station.output.is_empty():
			continue
		var port_count: int = maxi(1, station.type.output_labels().size())

		if port_count <= 1:
			_transfer_from_port(station, 0)
			continue

		# Dağıtıcı gibi birden fazla ÇIKIŞ PORTU olan istasyonlarda, hangi
		# portun bu tick ÖNCE denendiğini döndürüyoruz. Sabit sırayla
		# (0, sonra 1) denenseydi tek bir parça birikince port 0 HER
		# SEFERİNDE kazanır, port 1 hiç beslenmezdi — ölçüldü. Başlangıç
		# noktasını bir gönderim başarılı olduğunda kaydırınca, seyrek gelen
		# parçalar bile portlar arasında adil dönüşümlü dağılıyor.
		var start_port: int = station.next_output_port
		var sent: bool = false
		for offset in port_count:
			var port: int = (start_port + offset) % port_count
			if _transfer_from_port(station, port):
				sent = true
		if sent:
			station.next_output_port = (start_port + 1) % port_count


## --- Üretim -----------------------------------------------------------------

func _run_producer(station: SimStation) -> void:
	var recipe: Recipe = station.recipe()
	if recipe == null:
		# Jeneratörün reçetesi yok — gücü `_phase_power` zaten dağıttı, burada
		# yalnızca durum rozetini yansıtıyoruz (aksi hâlde her zaman "aç"
		# görünür, oysa kapasitesi varsa fiilen ÇALIŞIYORdur).
		if station.type.is_power_generator():
			station.status = SimStation.Status.RUNNING if station.type.power_output_at_level(station.level) > 0 else SimStation.Status.STARVED
		return

	if not station.producing:
		if not _try_start(station, recipe):
			# Girdi eksik: bu istasyon AÇ, tıkalı değil. Suç ÖNCEKİNDE.
			station.status = SimStation.Status.STARVED
			return

	if station.type.is_power_consumer():
		_run_powered_producer(station, recipe)
		return

	station.status = SimStation.Status.RUNNING

	# Süre GELİŞTİRME SEVİYESİNE göre değişir (bkz. SimStation.effective_
	# duration_ticks) — geliştirilmemiş istasyonda reçetenin kendi süresiyle
	# özdeştir. Süre dolduktan sonra saymaya devam etmeyiz: istasyon "bitmiş
	# ama boşaltamıyor" durumunda bekler, ilerleme çubuğu %100'de kalır.
	var duration: float = station.effective_duration_ticks()
	if station.progress_ticks < duration:
		station.progress_ticks += 1.0
		if station.progress_ticks < duration:
			return

	# Üretim bitti — boşaltmayı dene. Süre KESİRLİYSE (ör. 1.25 tick) tam
	# sayıya yuvarlamadan düşülür — `= 0` değil `-= duration` — ki küsurat
	# kaybolmasın ve uzun vadeli hız tam formüle otursun (bkz. SimStation.
	# progress_ticks).
	if _try_emit(station, recipe):
		station.producing = false
		station.progress_ticks = maxf(0.0, station.progress_ticks - duration)
	else:
		# Çıktı tamponu dolu: istasyon bitmiş parçayı elinde tutar ve DURUR.
		# Suç SONRAKİNDE. Tıkanma zinciri buradan geriye doğru yürür.
		station.status = SimStation.Status.BLOCKED


## Güç tüketen bir istasyonun üretimi. `progress_ticks` yerine ENERJİ
## birikir: her tick teslim edilen güç kadar `energy_ticks` artar, tam hızda
## ihtiyaç duyulan toplam enerjiye (`duration * power_required_per_tick`)
## ulaşınca üretim biter. Bu yüzden yarım güç YARI HIZ, sıfır güç HİÇ
## İLERLEME demektir — ayrı bir zamanlayıcı gerekmez, tek sayaç yeter.
##
## `energy_ticks` üretim biteceği eşiğin (`required_energy`) ÜSTÜNE
## ÇIKMAZ — tıpkı `progress_ticks`'in `duration`'ı aşmaması gibi (bkz.
## `_run_producer`). Bu sınır olmasaydı, çıktı tamponu dolduğunda (TIKALI)
## enerji sınırsız birikir; tıkanıklık açılınca tek bir tick'te aslında
## karşılığı olmayan birden fazla parça birden boşalırdı.
func _run_powered_producer(station: SimStation, recipe: Recipe) -> void:
	var delivered: int = delivered_power(station.id)
	if delivered <= 0:
		# Malzeme hazır ama güç yok: AÇ değil, TIKALI değil — GÜÇSÜZ. Suç
		# bağlantıda veya jeneratörün başka yere paylaştırdığı kapasitede.
		station.status = SimStation.Status.UNPOWERED
		return

	var required_energy: int = station.effective_duration_ticks_rounded() * station.type.power_required_per_tick
	if required_energy <= 0:
		station.status = SimStation.Status.RUNNING
		return

	if station.energy_ticks < required_energy:
		station.energy_ticks = mini(required_energy, station.energy_ticks + delivered)
		if station.energy_ticks < required_energy:
			station.status = SimStation.Status.RUNNING
			return

	if _try_emit(station, recipe):
		station.producing = false
		station.progress_ticks = 0
		station.energy_ticks -= required_energy
		station.status = SimStation.Status.RUNNING
	else:
		station.status = SimStation.Status.BLOCKED


## Girdiler reçeteyi karşılıyorsa tüketir ve üretimi başlatır.
func _try_start(station: SimStation, recipe: Recipe) -> bool:
	if station.type.category != BlockType.Category.SOURCE:
		for port in recipe.inputs.size():
			var slot: RecipeSlot = recipe.inputs[port]
			if _uses_shared_input(station, port):
				if not _can_consume_from_bus(station, slot.item.id, slot.count):
					return false
			elif int(station.input.get(slot.item.id, 0)) < slot.count:
				return false
		for port in recipe.inputs.size():
			var slot: RecipeSlot = recipe.inputs[port]
			if _uses_shared_input(station, port):
				_take_from_bus(station, slot.item.id, slot.count)
			else:
				station.take_item(station.input, slot.item.id, slot.count)

	# `progress_ticks` BİLİNÇLİ OLARAK sıfırlanmaz: önceki döngüden kalan
	# kesirli küsurat (bkz. `_run_producer`) buraya taşınıyor olabilir —
	# sıfırlarsak her yeni döngüde o küsurat kaybolur ve kesirli süreli
	# bloklarda (bkz. `BlockType.duration_ticks_at_level`) gerçek hız
	# formülden yavaşça sapar.
	station.producing = true
	return true


## Çıktıyı tampona koyar. Yer yoksa hiçbir şey yapmaz ve false döner.
func _try_emit(station: SimStation, recipe: Recipe) -> bool:
	var planned: Dictionary = _planned_output(station, recipe)

	# Hurda kutusu doluysa kontrol istasyonu KİLİTLENMEZ, parçayı sağlam
	# olarak geçirir.
	#
	# Neden: Ret portu tıkandığında istasyon elindeki hurdaya takılıp kalıyor,
	# takıldığı için sağlam üretimi de duruyordu. Geri dönüşüm hattı bir
	# döngü oluşturduğu için hurda hiç boşalmıyor ve fabrikanın TAMAMI kalıcı
	# olarak kilitleniyordu — gelir sıfıra düşüyor ve oyuncunun çıkışı
	# kalmıyordu. Zarif bozulma: fire oranı tıkanma altında düşer, hat ölmez.
	if not _fits(station, planned) and station.type.category == BlockType.Category.INSPECT:
		planned = _recipe_output(recipe)

	if _uses_shared_output(station, 0):
		if not _bus_fits(station, planned):
			return false
		var complex: IronworksComplex = complex_for_station(station.id)
		for item_id: StringName in planned:
			complex.material_bus[item_id] = int(complex.material_bus.get(item_id, 0)) + int(planned[item_id])
		station.produced_total += 1
		return true
	if not _fits(station, planned):
		return false
	for item_id: StringName in planned:
		station.add_item(station.output, item_id, planned[item_id])
	station.produced_total += 1
	return true


func _fits(station: SimStation, planned: Dictionary) -> bool:
	var capacity: int = station.type.output_capacity
	for item_id: StringName in planned:
		if int(station.output.get(item_id, 0)) + int(planned[item_id]) > capacity:
			return false
	return true


static func _recipe_output(recipe: Recipe) -> Dictionary:
	var out: Dictionary = {}
	for slot: RecipeSlot in recipe.outputs:
		out[slot.item.id] = int(out.get(slot.item.id, 0)) + slot.count
	return out


## Bu üretimin ne çıkaracağı. Kontrol istasyonunda fire sayacı burada işler.
func _planned_output(station: SimStation, recipe: Recipe) -> Dictionary:
	var out: Dictionary = {}
	var is_scrap: bool = (
		station.type.category == BlockType.Category.INSPECT
		and station.type.scrap_every_n > 0
		and (station.produced_total + 1) % station.type.scrap_every_n == 0
	)
	if is_scrap and station.type.reject_item != null:
		out[station.type.reject_item.id] = 1
		return out
	return _recipe_output(recipe)


## Tampon üretmez: girdisini çıktısına geçirir.
func _run_buffer(station: SimStation) -> void:
	if station.type.demand_item != null:
		if station.type.power_trade_item != null:
			_run_power_trade(station)
			return
		_run_trade_depot(station)
		return
	if station.input.is_empty():
		station.status = SimStation.Status.STARVED
		return
	if station.total_output() >= station.type.output_capacity:
		station.status = SimStation.Status.BLOCKED
		return
	station.status = SimStation.Status.RUNNING
	# Her tick tek parça — tampon da bir boru, sonsuz hızlı değil.
	var item_id: StringName = station.input.keys()[0]
	station.take_item(station.input, item_id, 1)
	station.add_item(station.output, item_id, 1)
	# throughput_total() bu sayaca bakıyor — yoksa Hız göstergesi hep 0 kalır.
	station.produced_total += 1


## Elektrikli Trade Depot: 1 kW ve gereken Talep eşleşince 1 Electricity
## çıktısı oluşur. Çıktı, normal malzeme hattından Collector'a taşınır;
## bu düğümde `accrued` veya satış muhasebesi kesinlikle tutulmaz.
func _run_power_trade(station: SimStation) -> void:
	var delivered: int = delivered_power(station.id)
	if delivered <= 0:
		station.status = SimStation.Status.UNPOWERED
		return
	var demand_id: StringName = station.type.demand_item.id
	var required: int = maxi(1, station.type.demand_required)
	if int(station.input.get(demand_id, 0)) < required:
		station.status = SimStation.Status.STARVED
		return
	if station.total_output() >= station.type.output_capacity:
		station.status = SimStation.Status.BLOCKED
		return
	station.take_item(station.input, demand_id, required)
	station.add_item(station.output, station.type.power_trade_item.id, 1)
	station.produced_total += 1
	station.status = SimStation.Status.RUNNING


## Trade Depot gibi TALEP KAPILI geçiş noktaları: 0. porttan gelen HERHANGİ
## bir satılabilir üründen 1 tanesi, 1. porttan gelen Talep'ten
## `type.demand_required` kadar birikince karşıya geçer. Talep yetersizse mal
## elde bekler ama GEÇEMEZ — bu, Eritme Ocağı'nın "60. cevher gelene dek
## bekle" mantığıyla AYNI aile, tek fark Talep'in tükettiği ürünün TİPİNİN
## sabit olmaması.
func _run_trade_depot(station: SimStation) -> void:
	var demand_id: StringName = station.type.demand_item.id
	var required: int = maxi(1, station.type.demand_required)
	if int(station.input.get(demand_id, 0)) < required:
		station.status = SimStation.Status.STARVED
		return

	var goods_id: StringName = &""
	for key: StringName in station.input.keys():
		if key != demand_id:
			goods_id = key
			break
	if goods_id == &"":
		station.status = SimStation.Status.STARVED
		return

	if station.total_output() >= station.type.output_capacity:
		station.status = SimStation.Status.BLOCKED
		return

	station.status = SimStation.Status.RUNNING
	station.take_item(station.input, goods_id, 1)
	station.take_item(station.input, demand_id, required)
	station.add_item(station.output, goods_id, 1)
	station.produced_total += 1


## Sevkiyat gelen her ürünü yutar ve satar. Satış OTOMATİK; parası
## `auto_collect` kapalıyken KASAYA DEĞİL istasyonun kendi `accrued`
## sayacına gider — oyuncu `collect()` çağırana kadar harcanamaz. Satış
## HIZI göstergesi `sold_counts`'a bakar (bkz. RateMeter/SalesRateTracker),
## bu sayaç tahsilattan BAĞIMSIZ, satış anında artar — tahsilat tıklaması
## burada hiçbir şeyi artırmaz, yalnızca `collect()` parayı taşır.
func _run_sink(station: SimStation) -> void:
	if station.input.is_empty():
		station.status = SimStation.Status.STARVED
		return
	station.status = SimStation.Status.RUNNING
	for item_id: StringName in station.input.keys():
		var count: int = int(station.input[item_id])
		_sell(station, item_id, count)
	station.input.clear()

## Satış muhasebesinin TEK yeri: normal Sevkiyat ve Elektrik Satış Noktası
## AYNI kodu çağırır (bkz. D6 — tahsilat mantığı çoğaltılmaz).
func _sell(station: SimStation, item_id: StringName, count: int) -> void:
	station.consumed_total += count
	var item: ItemType = ItemCatalog.find_by_id(item_id)
	if item == null:
		return
	var item_multiplier: float = float(item_sale_multipliers.get(String(item_id), 1.0))
	var amount: int = roundi(
		float(item.base_price * count)
		* station.type.sale_value_multiplier_at_level(station.level)
		* item_multiplier
	)
	if auto_collect:
		revenue += amount
	else:
		station.accrued += amount
	sold_counts[item_id] = int(sold_counts.get(item_id, 0)) + count
	item_sold.emit(item, count)


## Bir Sevkiyat istasyonunda BİRİKMİŞ parayı harcanabilir kasaya taşır.
## Döndürdüğü miktar bildirimde ("X altın tahsil edildi") kullanılır.
func collect(station_id: int) -> int:
	var station: SimStation = get_station(station_id)
	if station == null or station.type.category != BlockType.Category.SINK:
		return 0
	var amount: int = station.accrued
	if amount > 0:
		revenue += amount
		station.accrued = 0
	return amount


## Tüm Sevkiyat istasyonlarını tek seferde tahsil eder. Üst bardaki tek
## "Tahsil Et" düğmesinin çağırdığı yer — oyuncu birden fazla market
## kursa bile tek tıkla hepsini toplar.
func collect_all() -> int:
	var total: int = 0
	for id: int in _ordered_ids:
		var station: SimStation = _stations[id]
		if station.type.category == BlockType.Category.SINK:
			total += collect(id)
	return total


## Tahsil edilmeyi bekleyen toplam — üst barda "Market" olarak gösterilir.
func total_uncollected() -> int:
	var total: int = 0
	for id: int in _ordered_ids:
		var station: SimStation = _stations[id]
		if station.type.category == BlockType.Category.SINK:
			total += station.accrued
	return total


## Ar-Ge Laboratuvarı yutar ama satmaz — gelen ürün araştırmaya sayılır.
func _run_research(station: SimStation) -> void:
	if station.input.is_empty():
		station.status = SimStation.Status.STARVED
		return
	station.status = SimStation.Status.RUNNING
	for item_id: StringName in station.input.keys():
		var count: int = int(station.input[item_id])
		station.consumed_total += count
		research_counts[item_id] = int(research_counts.get(item_id, 0)) + count
	station.input.clear()


## --- Taşıma -----------------------------------------------------------------

## Bir birim taşımayı dener; taşıdıysa true döner. Çağıran (`_phase_transfer`)
## bunu, çok portlu istasyonlarda hangi portun bir sonraki tick önce
## deneneceğine karar vermek için kullanır.
func _transfer_from_port(station: SimStation, port: int) -> bool:
	var key: String = "%d:%d" % [station.id, port]
	var links: Array = _links_by_port.get(key, [])
	if links.is_empty():
		return false

	var item_id: StringName = _port_item_id(station, port)
	if item_id == &"":
		return false
	if int(station.output.get(item_id, 0)) <= 0:
		return false

	# Her çıkış portu artık en fazla 1 bağlantı taşıyor (bkz.
	# connection_problem) — bu döngü pratikte hep tek turda biter. Round-robin
	# yapısı yine de duruyor: gelecekte gevşetilirse kod yolu bozulmaz.
	var start: int = int(station.next_link.get(port, 0))
	for offset in links.size():
		var index: int = (start + offset) % links.size()
		var link: SimLink = links[index]
		var dst: SimStation = get_station(link.to_id)
		if dst == null:
			continue
		if not _can_accept(dst, link.to_port, item_id):
			continue
		station.take_item(station.output, item_id, 1)
		dst.add_item(dst.input, item_id, 1)
		station.next_link[port] = (index + 1) % links.size()
		_last_transferred_item[key] = item_id
		return true
	return false


## Bu çıkış portundan hangi ürün akar?
## Tamponun tipi yoktur — elinde ne varsa onu verir.
func _port_item_id(station: SimStation, port: int) -> StringName:
	var items: Array[ItemType] = station.type.output_items()
	if items.is_empty():
		if station.output.is_empty():
			return &""
		return station.output.keys()[0]
	if port >= items.size() or items[port] == null:
		return &""
	return items[port].id


func _can_accept(dst: SimStation, port: int, item_id: StringName) -> bool:
	if _uses_shared_input(dst, port):
		return false
	# Trade Depot gibi TALEP KAPILI bloklar: port 0 Talep HARİÇ herhangi bir
	# ürünü kabul eder. Port 1 (Talep) ise İKİ şartla kabul eder: (1) elde
	# ZATEN bekleyen bir mal olmalı — Talep, mal gelmeden ÖNCEDEN
	# bankalanamaz, yoksa ilk mal geldiğinde eşik zaten aşılmış olur ve
	# ilerleme çubuğu hiç kademeli dolmadan anında atlar (bkz. oyuncu
	# geri bildirimi); (2) birikim `demand_required`'ı aşamaz — Eritme
	# Ocağı'nın "60. cevher gelene dek" eşiğiyle AYNI mantık, tek fark
	# burada sayaç mal geldiği ANDAN itibaren başlıyor.
	if dst.type.demand_item != null:
		var demand_id: StringName = dst.type.demand_item.id
		var demand_port: int = 0 if dst.type.power_trade_item != null else 1
		if port == demand_port:
			if item_id != demand_id:
				return false
			if dst.type.power_trade_item != null:
				return int(dst.input.get(item_id, 0)) < maxi(1, dst.type.demand_required)
			var has_goods: bool = false
			for key: StringName in dst.input.keys():
				if key != demand_id:
					has_goods = true
					break
			if not has_goods:
				return false
			return int(dst.input.get(item_id, 0)) < maxi(1, dst.type.demand_required)
		if dst.type.power_trade_item == null and port == 0:
			return item_id != demand_id and int(dst.input.get(item_id, 0)) < dst.type.input_capacity
		return false

	var expected: Array[ItemType] = dst.type.input_items()
	if expected.is_empty():
		# Jenerik giriş (tampon, sevkiyat): kapasite ürün başına değil toplam.
		return dst.total_input() < dst.type.input_capacity
	if port >= expected.size() or expected[port] == null:
		return false
	if expected[port].id != item_id:
		return false
	return int(dst.input.get(item_id, 0)) < dst.type.input_capacity


func _can_consume_from_bus(station: SimStation, item_id: StringName, count: int) -> bool:
	var complex: IronworksComplex = complex_for_station(station.id)
	if complex == null or int(complex.material_bus.get(item_id, 0)) < count:
		return false
	# Ingot strategy yalnızca ortak havuzdan beslenen haddeyi etkiler;
	# oyuncunun doğrudan bağladığı özel hatlara asla müdahale etmez.
	if station.type.id == &"pres" and item_id == &"kulce":
		if complex.strategy == IronworksComplex.Strategy.INGOT_FOCUS:
			return false
		if complex.strategy == IronworksComplex.Strategy.BALANCED and tick_count % 2 != 0:
			return false
	return true


func _take_from_bus(station: SimStation, item_id: StringName, count: int) -> void:
	var complex: IronworksComplex = complex_for_station(station.id)
	if complex == null:
		return
	var remaining: int = int(complex.material_bus.get(item_id, 0)) - count
	if remaining <= 0:
		complex.material_bus.erase(item_id)
	else:
		complex.material_bus[item_id] = remaining


func _bus_fits(station: SimStation, planned: Dictionary) -> bool:
	var complex: IronworksComplex = complex_for_station(station.id)
	if complex == null:
		return false
	for item_id: StringName in planned:
		if int(complex.material_bus.get(item_id, 0)) + int(planned[item_id]) > complex.material_capacity:
			return false
	return true


## --- Özet -------------------------------------------------------------------

## Belirli durumdaki istasyonların id listesi.
## Sunum katmanı bunları farklı rozetlerle gösterecek — aç ve tıkalı
## birbirinden ayırt edilebilmeli.
## Sayım için. Her karede çağrıldığından dizi ayırmaz.
func count_with_status(status: SimStation.Status) -> int:
	var total: int = 0
	for id: int in _ordered_ids:
		if _stations[id].status == status:
			total += 1
	return total


func ids_with_status(status: SimStation.Status) -> Array[int]:
	var out: Array[int] = []
	for id: int in _ordered_ids:
		if _stations[id].status == status:
			out.append(id)
	return out


## --- Kayıt ------------------------------------------------------------------

func to_dict() -> Dictionary:
	var station_data: Array = []
	for id: int in _ordered_ids:
		var st: SimStation = _stations[id]
		station_data.append({
			"id": st.id,
			"type_id": String(st.type.id),
			"input": _ids_to_strings(st.input),
			"output": _ids_to_strings(st.output),
			"producing": st.producing,
			"progress": st.progress_ticks,
			"produced_total": st.produced_total,
			"consumed_total": st.consumed_total,
			"next_link": st.next_link.duplicate(),
			"next_output_port": st.next_output_port,
			"level": st.level,
			"accrued": st.accrued,
			"energy_ticks": st.energy_ticks,
		})

	var link_data: Array = []
	for link: SimLink in _links:
		link_data.append({
			"from": link.from_id, "from_port": link.from_port,
			"to": link.to_id, "to_port": link.to_port,
		})

	var power_link_data: Array = []
	for link: PowerLink in _power_links:
		power_link_data.append({"from": link.from_id, "to": link.to_id})
	var complex_data: Array = []
	for complex: IronworksComplex in complexes():
		complex_data.append(complex.to_dict())

	return {
		"tick": tick_count,
		"next_id": _next_id,
		"revenue": revenue,
		"auto_collect": auto_collect,
		"sold": _ids_to_strings(sold_counts),
		"research": _ids_to_strings(research_counts),
		"stations": station_data,
		"links": link_data,
		"power_links": power_link_data,
		"complexes": complex_data,
		"next_complex_id": _next_complex_id,
	}


func from_dict(data: Dictionary) -> bool:
	clear()
	tick_count = int(data.get("tick", 0))
	_next_id = int(data.get("next_id", 1))
	revenue = int(data.get("revenue", 0))
	auto_collect = bool(data.get("auto_collect", false))
	for key: String in data.get("sold", {}):
		sold_counts[StringName(key)] = int(data["sold"][key])
	for key: String in data.get("research", {}):
		research_counts[StringName(key)] = int(data["research"][key])

	for entry: Dictionary in data.get("stations", []):
		var type := BlockCatalog.find_by_id(StringName(entry.get("type_id", "")))
		if type == null:
			if not BlockCatalog.is_removed_type_id(StringName(entry.get("type_id", ""))):
				push_warning("Unknown workshop type: %s" % entry.get("type_id", ""))
			continue
		var st := SimStation.new(int(entry.get("id", 0)), type)
		st.input = _strings_to_ids(entry.get("input", {}))
		st.output = _strings_to_ids(entry.get("output", {}))
		st.producing = bool(entry.get("producing", false))
		st.progress_ticks = float(entry.get("progress", 0.0))
		st.produced_total = int(entry.get("produced_total", 0))
		st.consumed_total = int(entry.get("consumed_total", 0))
		for port_key: Variant in entry.get("next_link", {}):
			st.next_link[int(port_key)] = int(entry["next_link"][port_key])
		st.next_output_port = int(entry.get("next_output_port", 0))
		st.level = int(entry.get("level", 1))
		st.accrued = int(entry.get("accrued", 0))
		st.energy_ticks = int(entry.get("energy_ticks", 0))
		_stations[st.id] = st
		_ordered_ids.append(st.id)

	_ordered_ids.sort()
	# Eski kayıtta Collector'ın ikinci/üçüncü portu ilk sırada yazılmış olsa
	# bile bağlantı geçersiz sayılmasın. Gerçek "bir boş port bırak" sayısı
	# aşağıdaki her bağlantıdan sonra `_sync_collector_input_ports` ile yeniden
	# hesaplanır.
	for entry: Dictionary in data.get("links", []):
		var dst: SimStation = get_station(int(entry.get("to", -1)))
		if dst != null and dst.type.category == BlockType.Category.SINK:
			dst.input_port_count = maxi(dst.input_port_count, int(entry.get("to_port", 0)) + 1)
	for entry: Dictionary in data.get("links", []):
		var from_id: int = int(entry.get("from", -1))
		var to_id: int = int(entry.get("to", -1))
		var from_port: int = int(entry.get("from_port", 0))
		var to_port: int = int(entry.get("to_port", 0))
		# Kaldırılmış gıda istasyonlarına veya artık geçersiz portlara giden
		# eski bağlantıları sessizce atla; demir hattında sahipsiz tel kalmaz.
		if connection_problem(from_id, from_port, to_id, to_port).is_empty():
			_links.append(SimLink.new(from_id, from_port, to_id, to_port))
	_rebuild_link_index()

	for entry: Dictionary in data.get("power_links", []):
		var from_id: int = int(entry.get("from", -1))
		var to_id: int = int(entry.get("to", -1))
		if can_connect_power(from_id, to_id):
			_power_links.append(PowerLink.new(from_id, to_id))

	_next_complex_id = maxi(1, int(data.get("next_complex_id", 1)))
	for entry: Dictionary in data.get("complexes", []):
		var complex_id: int = int(entry.get("id", -1))
		if complex_id < 1 or _complexes.has(complex_id):
			continue
		var complex := IronworksComplex.new(complex_id)
		complex.load_dict(entry)
		var valid_members: Array[int] = []
		for station_id: int in complex.station_ids:
			if _can_join_complex(station_id):
				valid_members.append(station_id)
		complex.station_ids = valid_members
		_complexes[complex_id] = complex
		for station_id: int in valid_members:
			_station_complex[station_id] = complex_id
		_next_complex_id = maxi(_next_complex_id, complex_id + 1)
	return true


## Determinizm kanıtı için durum parmak izi.
##
## İki koşum aynı tick sayısından sonra aynı hash'i vermiyorsa determinizm
## kırılmıştır ve offline kazanç, denge koşumu, kaydet/yükle hepsi güvenilmez
## hâle gelir. Bu yüzden testte her koşumda kontrol edilir.
func state_hash() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("t%d|r%d|c%d|g%s" % [tick_count, revenue, int(auto_collect), _stable_buffer(research_counts)])
	for id: int in _ordered_ids:
		var st: SimStation = _stations[id]
		parts.append("#%d:%s:%d/%d:%s:p%s:e%d%s:n%d:l%d:u%d:i%s:o%s" % [
			st.id, st.type.id, st.produced_total, st.consumed_total,
			"1" if st.producing else "0", "%.6f" % st.progress_ticks, st.energy_ticks,
			str(st.status), st.next_output_port,
			st.level, st.accrued,
			_stable_buffer(st.input), _stable_buffer(st.output),
		])
	var power_parts: PackedStringArray = PackedStringArray()
	for link: PowerLink in _power_links:
		power_parts.append("%d>%d" % [link.from_id, link.to_id])
	power_parts.sort()
	parts.append("pw:" + ",".join(power_parts))
	var complex_parts: PackedStringArray = PackedStringArray()
	for complex: IronworksComplex in complexes():
		complex_parts.append(complex.fingerprint())
	parts.append("cx:" + "|".join(complex_parts))
	return "|".join(parts).sha256_text()


## Sözlük sırası ekleme sırasına bağlı — hash için anahtarları sıralarız.
static func _stable_buffer(buffer: Dictionary) -> String:
	var keys: Array = buffer.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for key: StringName in keys:
		parts.append("%s=%d" % [key, buffer[key]])
	return ",".join(parts)


static func _ids_to_strings(buffer: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: StringName in buffer:
		out[String(key)] = buffer[key]
	return out


static func _strings_to_ids(buffer: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in buffer:
		out[StringName(key)] = int(buffer[key])
	return out
