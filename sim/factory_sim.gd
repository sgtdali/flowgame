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
var revenue: int = 0
var sold_counts: Dictionary = {}

var _stations: Dictionary = {}        # id -> SimStation
var _ordered_ids: Array[int] = []     # her zaman artan sırada
var _links: Array[SimLink] = []
var _links_by_port: Dictionary = {}   # "from_id:port" -> Array[SimLink]
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


## Bağlantı kurulabilir mi? Portlardaki ürünlerin uyuşmasını kontrol eder.
## Faz 3'te arayüz bunu kullanarak geçersiz bağlantıyı en baştan engelleyecek.
func can_connect(from_id: int, from_port: int, to_id: int, to_port: int) -> bool:
	if from_id == to_id:
		return false
	var src: SimStation = get_station(from_id)
	var dst: SimStation = get_station(to_id)
	if src == null or dst == null:
		return false
	var out_items: Array[ItemType] = src.type.output_items()
	# Jenerik çıkışlı istasyon (tampon) her şeyi verebilir.
	if not out_items.is_empty():
		if from_port >= out_items.size():
			return false
	var in_items: Array[ItemType] = dst.type.input_items()
	if in_items.is_empty():
		return true  # jenerik giriş: tampon ve sevkiyat her ürünü kabul eder
	if to_port >= in_items.size():
		return false
	if out_items.is_empty():
		return true  # tamponun çıkışı: tip bilinmiyor, taşıma anında bakılır
	return out_items[from_port] == in_items[to_port]


func connect_stations(from_id: int, from_port: int, to_id: int, to_port: int) -> bool:
	if not can_connect(from_id, from_port, to_id, to_port):
		return false
	for link: SimLink in _links:
		if link.matches(from_id, from_port, to_id, to_port):
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
	_next_id = 1
	tick_count = 0
	revenue = 0
	sold_counts.clear()


func _rebuild_link_index() -> void:
	_links_by_port.clear()
	for link: SimLink in _links:
		var key: String = "%d:%d" % [link.from_id, link.from_port]
		if not _links_by_port.has(key):
			_links_by_port[key] = []
		_links_by_port[key].append(link)


## --- Tick -------------------------------------------------------------------

func tick() -> void:
	tick_count += 1
	_phase_produce()
	_phase_transfer()


## Faz 1: üret / ilerlet.
func _phase_produce() -> void:
	for id: int in _ordered_ids:
		var station: SimStation = _stations[id]
		match station.type.category:
			BlockType.Category.BUFFER:
				_run_buffer(station)
			BlockType.Category.SINK:
				_run_sink(station)
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
		for port in port_count:
			_transfer_from_port(station, port)


## --- Üretim -----------------------------------------------------------------

func _run_producer(station: SimStation) -> void:
	var recipe: Recipe = station.recipe()
	if recipe == null:
		return

	if not station.producing:
		if not _try_start(station, recipe):
			# Girdi eksik: bu istasyon AÇ, tıkalı değil. Suç ÖNCEKİNDE.
			station.status = SimStation.Status.STARVED
			return

	station.status = SimStation.Status.RUNNING

	# Süre dolduktan sonra saymaya devam etmeyiz: istasyon "bitmiş ama
	# boşaltamıyor" durumunda bekler, ilerleme çubuğu %100'de kalır.
	if station.progress_ticks < recipe.duration_ticks:
		station.progress_ticks += 1
		if station.progress_ticks < recipe.duration_ticks:
			return

	# Üretim bitti — boşaltmayı dene.
	if _try_emit(station, recipe):
		station.producing = false
		station.progress_ticks = 0
	else:
		# Çıktı tamponu dolu: istasyon bitmiş parçayı elinde tutar ve DURUR.
		# Suç SONRAKİNDE. Tıkanma zinciri buradan geriye doğru yürür.
		station.status = SimStation.Status.BLOCKED


## Girdiler reçeteyi karşılıyorsa tüketir ve üretimi başlatır.
func _try_start(station: SimStation, recipe: Recipe) -> bool:
	if station.type.category != BlockType.Category.SOURCE:
		for slot: RecipeSlot in recipe.inputs:
			if int(station.input.get(slot.item.id, 0)) < slot.count:
				return false
		for slot: RecipeSlot in recipe.inputs:
			station.take_item(station.input, slot.item.id, slot.count)

	station.producing = true
	station.progress_ticks = 0
	return true


## Çıktıyı tampona koyar. Yer yoksa hiçbir şey yapmaz ve false döner.
func _try_emit(station: SimStation, recipe: Recipe) -> bool:
	var planned: Dictionary = _planned_output(station, recipe)
	var capacity: int = station.type.output_capacity
	for item_id: StringName in planned:
		if int(station.output.get(item_id, 0)) + int(planned[item_id]) > capacity:
			return false
	for item_id: StringName in planned:
		station.add_item(station.output, item_id, planned[item_id])
	station.produced_total += 1
	return true


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
	for slot: RecipeSlot in recipe.outputs:
		out[slot.item.id] = int(out.get(slot.item.id, 0)) + slot.count
	return out


## Tampon üretmez: girdisini çıktısına geçirir.
func _run_buffer(station: SimStation) -> void:
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


## Sevkiyat gelen her ürünü yutar ve satar.
func _run_sink(station: SimStation) -> void:
	if station.input.is_empty():
		station.status = SimStation.Status.STARVED
		return
	station.status = SimStation.Status.RUNNING
	for item_id: StringName in station.input.keys():
		var count: int = int(station.input[item_id])
		var item: ItemType = ItemCatalog.find_by_id(item_id)
		if item != null:
			revenue += item.base_price * count
			sold_counts[item_id] = int(sold_counts.get(item_id, 0)) + count
			item_sold.emit(item, count)
	station.input.clear()


## --- Taşıma -----------------------------------------------------------------

func _transfer_from_port(station: SimStation, port: int) -> void:
	var key: String = "%d:%d" % [station.id, port]
	var links: Array = _links_by_port.get(key, [])
	if links.is_empty():
		return

	var item_id: StringName = _port_item_id(station, port)
	if item_id == &"":
		return
	if int(station.output.get(item_id, 0)) <= 0:
		return

	# Round-robin: aynı porttan çıkan birden fazla bağlantı varsa yük
	# kendiliğinden dengelenir ve sonuç deterministik kalır.
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
		return


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
	var expected: Array[ItemType] = dst.type.input_items()
	if expected.is_empty():
		# Jenerik giriş (tampon, sevkiyat): kapasite ürün başına değil toplam.
		return dst.total_input() < dst.type.input_capacity
	if port >= expected.size() or expected[port] == null:
		return false
	if expected[port].id != item_id:
		return false
	return int(dst.input.get(item_id, 0)) < dst.type.input_capacity


## --- Özet -------------------------------------------------------------------

## Belirli durumdaki istasyonların id listesi.
## Sunum katmanı bunları farklı rozetlerle gösterecek — aç ve tıkalı
## birbirinden ayırt edilebilmeli.
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
			"next_link": st.next_link.duplicate(),
		})

	var link_data: Array = []
	for link: SimLink in _links:
		link_data.append({
			"from": link.from_id, "from_port": link.from_port,
			"to": link.to_id, "to_port": link.to_port,
		})

	return {
		"tick": tick_count,
		"next_id": _next_id,
		"revenue": revenue,
		"sold": _ids_to_strings(sold_counts),
		"stations": station_data,
		"links": link_data,
	}


func from_dict(data: Dictionary) -> bool:
	clear()
	tick_count = int(data.get("tick", 0))
	_next_id = int(data.get("next_id", 1))
	revenue = int(data.get("revenue", 0))
	for key: String in data.get("sold", {}):
		sold_counts[StringName(key)] = int(data["sold"][key])

	for entry: Dictionary in data.get("stations", []):
		var type := BlockCatalog.find_by_id(StringName(entry.get("type_id", "")))
		if type == null:
			push_warning("Bilinmeyen istasyon türü: %s" % entry.get("type_id", ""))
			continue
		var st := SimStation.new(int(entry.get("id", 0)), type)
		st.input = _strings_to_ids(entry.get("input", {}))
		st.output = _strings_to_ids(entry.get("output", {}))
		st.producing = bool(entry.get("producing", false))
		st.progress_ticks = int(entry.get("progress", 0))
		st.produced_total = int(entry.get("produced_total", 0))
		for port_key: String in entry.get("next_link", {}):
			st.next_link[int(port_key)] = int(entry["next_link"][port_key])
		_stations[st.id] = st
		_ordered_ids.append(st.id)

	_ordered_ids.sort()

	for entry: Dictionary in data.get("links", []):
		_links.append(SimLink.new(
			int(entry.get("from", -1)), int(entry.get("from_port", 0)),
			int(entry.get("to", -1)), int(entry.get("to_port", 0))
		))
	_rebuild_link_index()
	return true


## Determinizm kanıtı için durum parmak izi.
##
## İki koşum aynı tick sayısından sonra aynı hash'i vermiyorsa determinizm
## kırılmıştır ve offline kazanç, denge koşumu, kaydet/yükle hepsi güvenilmez
## hâle gelir. Bu yüzden testte her koşumda kontrol edilir.
func state_hash() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("t%d|r%d" % [tick_count, revenue])
	for id: int in _ordered_ids:
		var st: SimStation = _stations[id]
		parts.append("#%d:%s:%d:%s:p%d%s:i%s:o%s" % [
			st.id, st.type.id, st.produced_total,
			"1" if st.producing else "0", st.progress_ticks,
			str(st.status),
			_stable_buffer(st.input), _stable_buffer(st.output),
		])
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
