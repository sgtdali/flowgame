class_name GameController
extends Control

const IndustrialTheme = preload("res://common/industrial_theme.gd")

## ORKESTRATÖR. Simülasyonu ve ilerlemeyi sahiplenir, tick'i sürer,
## görselleri besler.
##
## İş mantığı burada DEĞİL — üretim kuralları `FactorySim`'de, ekonomi ve
## kilitler `ProgressionState`'te, içerik `.tres`'lerde. Buranın işi:
## bileşenlerden gelen YUKARI niyetleri alıp doğru mantığa sormak, cevabı
## AŞAĞI komutla görsellere yazmak.

## Kayıt biçimi. v6 güç sistemini ekledi; v7 kompleks üyeliğini, ortak
## havuzları, güç kaynaklarını ve iç canvas yerleşimini ekler. Eski kayıtlar
## kompleks alanı olmadan sorunsuz açılır (bkz. FactorySim.from_dict).
const SAVE_VERSION: int = 7

## Hız seçenekleri. 0 = duraklatıldı.
const SPEEDS: Array[int] = [0, 1, 2, 4, 8]

@onready var _canvas: FlowCanvas = %Canvas
@onready var _palette: BlockPalette = %Palette
@onready var _research_panel: ResearchPanel = %ResearchPanel
@onready var _research_toggle: Button = %ResearchToggle
@onready var _clock: Label = %Clock
@onready var _money: Label = %Money
@onready var _money_rate: Label = %MoneyRate
@onready var _market_accrued: Label = %MarketAccrued
@onready var _iron_ore_value: Label = %IronOreValue
@onready var _iron_ore_upgrade: Button = %IronOreUpgradeButton
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _load_dialog: FileDialog = %LoadDialog
@onready var _create_complex_button: Button = %CreateComplexButton

var _sim: FactorySim = FactorySim.new()
var _progression: ProgressionState = ProgressionState.new()
var _speed: int = 1

## Kesirli tick borcu. Kare süresi tick süresine tam bölünmediği için gerekli.
var _accumulator: float = 0.0

var _speed_buttons: Array[Button] = []

## Son yazılan değerler. Label.text her karede yazılırsa boşuna font shaping
## olur. Bakiye ayrıca paletin yenilenmesini tetiklediği için takip ediliyor.
var _last_clock: String = ""
var _last_money: String = ""
var _last_balance: int = -1
var _last_research_total: int = -1
var _last_money_rate: String = ""
var _last_market_accrued: String = ""
var _last_iron_ore_value: String = ""

## Ar-Ge Sarayı'na akan ürünlerin ürün-başına hızı. Sunum verisi — kayıtta
## yer almaz, yükledikten birkaç saniye sonra kendi kendine dolar.
var _research_rate := ResearchDeliveryTracker.new()

## Araştırma paneli açıkken bile her kare tam yeniden kurmamak için:
## yalnızca bu kadar sim-tick geçince canlı hız/ETA'yı tazele.
const _RESEARCH_PANEL_REFRESH_TICKS: int = GameConfig.TICKS_PER_SECOND
var _last_research_panel_refresh_tick: int = -999999

var _complex_layout: Dictionary = {}
var _complex_workspace: PanelContainer = null
var _internal_canvas: FlowCanvas = null
var _complex_bus_label: Label = null
var _complex_status_label: Label = null
var _complex_inspector: Label = null
var _complex_strategy: OptionButton = null
var _complex_power_sources: OptionButton = null
var _open_complex_id: int = -1


func _ready() -> void:
	theme = IndustrialTheme.build()
	_palette.block_requested.connect(_on_palette_request)

	_canvas.add_requested.connect(_on_add_requested)
	_canvas.connect_requested.connect(_on_connect_requested)
	_canvas.disconnect_requested.connect(_on_disconnect_requested)
	_canvas.delete_requested.connect(_on_delete_requested)
	_canvas.action_requested.connect(_on_canvas_action_requested)
	_canvas.interacted.connect(_on_canvas_interacted)
	_canvas.complex_open_requested.connect(_open_complex)

	_research_panel.unlock_requested.connect(_on_unlock_requested)
	_research_panel.locate_requested.connect(_on_locate_requested)
	_research_panel.close_requested.connect(_on_research_closed)

	_research_toggle.pressed.connect(_on_research_toggle_pressed)
	%ArrangeButton.pressed.connect(_canvas.arrange_nodes)
	_create_complex_button.pressed.connect(_on_create_complex_pressed)
	%ClearButton.pressed.connect(_on_clear_pressed)
	# Lambda DEĞİL adlandırılmış metot: Godot, yerel değişken yakalayan
	# lambda'ları otomatik çözemiyor ve düğüm silindiğinde çökme riski doğuyor.
	%SaveButton.pressed.connect(_on_save_pressed)
	%LoadButton.pressed.connect(_on_load_pressed)
	_save_dialog.file_selected.connect(_on_save_path_selected)
	_load_dialog.file_selected.connect(_on_load_path_selected)
	_iron_ore_upgrade.pressed.connect(_on_iron_ore_upgrade_pressed)
	_build_complex_workspace()

	_speed_buttons = [%PauseButton, %Speed1Button, %Speed2Button, %Speed4Button, %Speed8Button]
	for index in _speed_buttons.size():
		_speed_buttons[index].pressed.connect(_on_speed_pressed.bind(index))

	_build_starter_layout()
	_refresh_availability()
	_refresh_iron_ore_value()
	_notice("Starter route built: Iron Mine → Mine Extractor → Trade Depot ← Trade Network → Collector. Sales wait at the Collector until you collect them.")


## Oyun her açıldığında (yeni oyun — kayıttan yükleme AYRI bir yoldan,
## `_on_load_path_selected` üzerinden gelir ve bunu ez geçer) hazır kurulu
## gelen başlangıç hattı. `_on_add_requested`'ın aksine ücret/araştırma
## kontrolü YAPILMAZ — bu, oyuncunun kendi kurduğu değil, oyunun kendisiyle
## birlikte gelen bir hat.
func _build_starter_layout() -> void:
	var mine: int = _spawn_free(BlockCatalog.MADEN_OCAGI, Vector2(20, 40))
	var extractor: int = _spawn_free(BlockCatalog.MINE_EXTRACTOR, Vector2(300, 90))
	var network: int = _spawn_free(BlockCatalog.TRADE_NETWORK, Vector2(300, 320))
	var depot: int = _spawn_free(BlockCatalog.TRADE_DEPOT, Vector2(620, 210))
	var collector: int = _spawn_free(BlockCatalog.SEVKIYAT, Vector2(940, 210))

	_link(mine, 0, extractor, 0)
	_link(extractor, 0, depot, 0)
	_link(network, 0, depot, 1)
	_link(depot, 0, collector, 0)


## Bir istasyonu ÜCRETSİZ kurar (bkz. `_build_starter_layout`) — `_on_add_
## requested`'ın maliyet/kilit denetimini atlar, doğrudan simülasyon VE
## tuvali aynı anda kurar.
func _spawn_free(type: BlockType, at: Vector2) -> int:
	var sim_id: int = _sim.add_station(type)
	_canvas.spawn_block(sim_id, type, at)
	return sim_id


## Simülasyon VE tuval bağlantısını TEK yerden kurar — `_build_starter_
## layout` ikisini ayrı ayrı çağırıp unutma riski taşımasın.
func _link(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	_sim.connect_stations(from_id, from_port, to_id, to_port)
	_canvas.apply_connection(from_id, from_port, to_id, to_port)


## --- Oyun döngüsü -----------------------------------------------------------

func _process(delta: float) -> void:
	_advance_sim(delta)
	_sync_visuals()
	_refresh_hud()


func _advance_sim(delta: float) -> void:
	if _speed <= 0:
		return
	_accumulator += delta * float(GameConfig.TICKS_PER_SECOND * _speed)

	var processed: int = 0
	while _accumulator >= 1.0 and processed < GameConfig.MAX_TICKS_PER_FRAME:
		_sim.tick()
		_accumulator -= 1.0
		processed += 1

	if processed >= GameConfig.MAX_TICKS_PER_FRAME:
		# Tavana dayandık: biriken borcu SİLİYORUZ. Taşımaya çalışsaydık her
		# kare daha da geriye düşerdik ve oyun bir daha toparlayamazdı.
		_accumulator = 0.0


## Simülasyondan görüntüye TEK senkronizasyon döngüsü.
##
## 80 düğümün her birine ayrı `_process` koymak yerine tek yerden yazıyoruz —
## düğüm başına SceneTree çağrı yükü olmuyor.
func _sync_visuals() -> void:
	_sync_canvas_visuals(_canvas)
	if _internal_canvas != null and _internal_canvas.visible:
		_sync_canvas_visuals(_internal_canvas)
		_refresh_complex_workspace()


func _sync_canvas_visuals(target: FlowCanvas) -> void:
	for block: FlowBlock in target.get_blocks():
		var station: SimStation = _sim.get_station(block.sim_id)
		if station != null:
			block.render_state(
				station, _sim.tick_count, _sim.unwired_port_count(block.sim_id),
				_sim.auto_collect, _power_text(station), _incoming_rates(station)
			)


## Bir istasyonun HER girdi PORTUNA ayrı ayrı bağlı ÜST istasyon(lar)dan o
## anki gerçek gelen hız (adet/sn). Eritme Ocağı gibi birden fazla girdisi
## olan bloklarda (cevher + kömür) bunları TOPLAMAK anlamsız olurdu — farklı
## kaynaklar, port başına ayrı izlenir. Dizinin indeksi `recipe.inputs`'in
## indeksiyle AYNI hizada olmalı (bkz. `BlockType.input_labels`).
func _incoming_rates(station: SimStation) -> Array[float]:
	var slot_count: int = 1
	if station.type.category == BlockType.Category.SINK:
		slot_count = station.input_port_count
	elif station.type.demand_item != null:
		slot_count = 1 if station.type.power_trade_item != null else 2
	else:
		var recipe: Recipe = station.recipe()
		if recipe != null and not recipe.inputs.is_empty():
			slot_count = recipe.inputs.size()
	var rates: Array[float] = []
	rates.resize(slot_count)
	rates.fill(0.0)
	for link: SimLink in _sim.links_into(station.id):
		if link.to_port < 0 or link.to_port >= slot_count:
			continue
		var rate: float = _rate_contributed_by_link(link)
		if station.type.category == BlockType.Category.SINK:
			var item: ItemType = ItemCatalog.find_by_id(_sim.item_id_on_link(link))
			if item != null:
				var item_multiplier: float = float(_sim.item_sale_multipliers.get(String(item.id), 1.0))
				rate *= float(item.base_price) * station.type.sale_value_multiplier_at_level(station.level) * item_multiplier
		rates[link.to_port] += rate
	return rates


## Bir istasyonun tek bir girdi PORTUNA gelen toplam hız — `_incoming_rates`
## tüm portları isteyen çağıranlar (FlowBlock) için, bu ise `_effective_
## output_rate`'in tek bir portun darboğazını hesaplarken kullandığı yardımcı.
func _incoming_rate_for_port(station: SimStation, port: int) -> float:
	var total: float = 0.0
	for link: SimLink in _sim.links_into(station.id):
		if link.to_port != port:
			continue
		total += _rate_contributed_by_link(link)
	return total


## Bölünebilen kaynakların hızı, tek bir çıkış portundan çıkan her bağlantıya
## eşit paylaştırılır. Bu, ekrandaki Input/Output Value'nun gerçek round-robin
## aktarımıyla aynı kalmasını sağlar: 11/sn, iki kola 5.5/sn + 5.5/sn gider.
func _rate_contributed_by_link(link: SimLink) -> float:
	var src: SimStation = _sim.get_station(link.from_id)
	if src == null:
		return 0.0
	var total_rate: float = _effective_output_rate(src)
	if not src.type.splits_output:
		return total_rate

	var branch_count: int = 0
	for outgoing: SimLink in _sim.links():
		if outgoing.from_id == link.from_id and outgoing.from_port == link.from_port:
			branch_count += 1
	return total_rate / float(maxi(1, branch_count))


## Bir istasyonun GERÇEK, o anki koşullarda üretebileceği hız (adet/sn) —
## kendi temposu VARSA onunla, üst istasyonlardan gelen arzla SINIRLI.
## `RateMeter` gibi zamanla oturan bir ÖLÇÜM değil, formülden anlık hesap:
## bağlantı kurulur kurulmaz veya seviye atlanır atlanmaz doğru değeri
## verir. Üst bardaki "gold/sec" (bkz. `_current_income_per_sec`) ve
## düğümlerin "Input Value"su (bkz. `_incoming_rates`) AYNI bu fonksiyona
## dayanır — ikisi ayrışırsa oyuncu iki farklı "gerçek hız" görür.
##
## BİRDEN FAZLA girdisi olan bloklarda (ör. Eritme Ocağı: cevher + kömür)
## çıktı, HER girdinin kendi oranının (rate/slot.count) EN KÜÇÜĞÜNE göre
## sınırlıdır — dönüşüm ancak İKİSİ de yetiştiğinde olur.
func _effective_output_rate(station: SimStation) -> float:
	if station.type.demand_item != null:
		if station.type.power_trade_item != null:
			var demand_rate: float = _incoming_rate_for_port(station, 0) / float(maxi(1, station.type.demand_required))
			var power_rate: float = float(_sim.delivered_power(station.id)) * float(GameConfig.TICKS_PER_SECOND)
			return minf(demand_rate, power_rate)
		# Trade Depot: mal (port 0) SADECE Talep'ten (port 1) yeterince
		# geliyorsa geçer — Talep hızı `demand_required`'a bölünüp mal
		# hızıyla EN KÜÇÜK olan alınır, tıpkı Eritme Ocağı'nın çok-girdili
		# darboğaz mantığı gibi (bkz. altta).
		var demand_rate: float = _incoming_rate_for_port(station, 1) / float(maxi(1, station.type.demand_required))
		return minf(_incoming_rate_for_port(station, 0), demand_rate)

	var recipe: Recipe = station.recipe()
	if recipe == null:
		# Ara Depo/Dağıtıcı gibi reçetesiz bloklar üretmez, sadece TAŞIR —
		# çıktı hızı üst istasyonlardan gelenin toplamı, kendi tavanı yok.
		if station.type.category == BlockType.Category.BUFFER or station.type.category == BlockType.Category.SPLITTER:
			return _incoming_rate_for_port(station, 0)
		return 0.0

	var own_duration: float = station.effective_duration_ticks()
	if recipe.inputs.is_empty():
		# Kaynak (ör. Maden Ocağı): girdi yok, hız tamamen kendi temposundan.
		return (float(GameConfig.TICKS_PER_SECOND) / own_duration) if own_duration > 0.0 else 0.0

	var rate_from_supply: float = INF
	for port in recipe.inputs.size():
		var ratio: int = maxi(1, recipe.inputs[port].count)
		rate_from_supply = minf(rate_from_supply, _incoming_rate_for_port(station, port) / float(ratio))
	if rate_from_supply == INF:
		rate_from_supply = 0.0

	if own_duration <= 0.0:
		# Eritme Ocağı gibi kendi temposu yok — hız tamamen arzın işlevi.
		return rate_from_supply
	return minf(float(GameConfig.TICKS_PER_SECOND) / own_duration, rate_from_supply)


## Üst bardaki "gold/sec": bağlı tüm Sevkiyat/Elektrik Satış Noktalarının o
## anki gerçek satış hızının toplamı — ölçülmüş bir ortalama DEĞİL (bkz.
## `_effective_output_rate`), formülden anlık hesap. Node'un "Input Value"su
## ile aynı mantık, tüm fabrikaya genelleştirildi.
func _current_income_per_sec() -> float:
	var total: float = 0.0
	for station: SimStation in _sim.stations():
		if station.type.category != BlockType.Category.SINK:
			continue
		for link: SimLink in _sim.links_into(station.id):
			var rate: float = _rate_contributed_by_link(link)
			if rate <= 0.0:
				continue
			var item: ItemType = ItemCatalog.find_by_id(_sim.item_id_on_link(link))
			if item == null:
				continue
			var item_multiplier: float = float(_sim.item_sale_multipliers.get(String(item.id), 1.0))
			total += rate * float(item.base_price) * station.type.sale_value_multiplier_at_level(station.level) * item_multiplier
	return total


## Bir istasyonun düğümünün üstünde gösterilecek güç satırı. Boş string =
## bu istasyonun güç portu yok, satır gizli kalır.
func _power_text(station: SimStation) -> String:
	var type: BlockType = station.type
	if type.is_power_generator():
		return "%d / %d kW used" % [_sim.power_used(station.id), _sim.power_capacity(station.id)]
	if type.is_power_consumer():
		return "%d / %d kW" % [_sim.delivered_power(station.id), type.power_required_per_tick]
	if type.sells_power:
		return "%d kW" % _sim.delivered_power(station.id)
	return ""


func _balance() -> int:
	return _progression.balance(_sim.revenue)


## --- Hız --------------------------------------------------------------------

func _on_speed_pressed(index: int) -> void:
	_speed = SPEEDS[index]
	# Hız değişince biriken kesirli borcu taşımayız; yoksa duraklatıp devam
	# edince bir anda toplu tick atar.
	_accumulator = 0.0


## --- Paletten ve düğümlerin kendi eylem düğmelerinden ------------------------

func _on_palette_request(type: BlockType) -> void:
	_on_add_requested(type, _canvas.viewport_center())


## Düğümün kendi üstündeki İşçi Ata/Yükselt/Tahsil Et düğmelerinden gelir —
## bkz. DESIGN.md D28. Sağ panel artık bir denetçi değil, bu yüzden burada
## paneli tazeleyecek bir şey yok; sonucu doğrudan bloğun kendisine yazarız.
func _on_canvas_action_requested(block: FlowBlock, action: StringName) -> void:
	match action:
		&"upgrade":
			_on_upgrade_requested(block)
		&"collect":
			_on_collect_one_requested(block)


func _on_upgrade_requested(block: FlowBlock) -> void:
	var station: SimStation = _sim.get_station(block.sim_id)
	if station == null:
		return
	var problem: String = _progression.try_upgrade(station, _sim.revenue)
	if not problem.is_empty():
		_notice(problem)
	else:
		_notice("%s upgraded to level %d." % [block.block_type.display_name, station.level])
	_refresh_availability()


func _on_collect_one_requested(block: FlowBlock) -> void:
	var amount: int = _sim.collect(block.sim_id)
	if amount > 0:
		_notice("Collected %s gold." % GameConfig.format_money(amount))


## --- Tuvalden gelen niyetler ------------------------------------------------

func _on_add_requested(type: BlockType, at: Vector2) -> void:
	if not _progression.is_block_available(type, _sim.tick_count):
		_notice("%s has not been discovered yet." % type.display_name)
		return

	if type.max_instances > 0 and _count_of_type(type.id) >= type.max_instances:
		_notice("%s is capped at %d for this experiment. Upgrade the existing one instead." % [
			type.display_name, type.max_instances])
		return

	if not _progression.try_pay(type.build_cost, _sim.revenue):
		_notice("Not enough gold. You need %s." % GameConfig.format_money(type.build_cost))
		return

	var sim_id: int = _sim.add_station(type)
	_canvas.spawn_block(sim_id, type, at)
	_refresh_availability()


## Bu türden şu an kurulu kaç örnek var. `max_instances` denetimi bunu
## okur — ayrı bir sayaç TUTULMAZ (bkz. DESIGN.md D27): silme/yükleme yolları
## bu yüzden yanlışlıkla sınırı aşamaz, her zaman gerçek durumdan sayılır.
func _count_of_type(type_id: StringName) -> int:
	var count: int = 0
	for station: SimStation in _sim.stations():
		if station.type.id == type_id:
			count += 1
	return count


func _on_connect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	if _is_power_port(from_sim, from_port) or _is_power_port(to_sim, to_port):
		var power_problem: String = _sim.power_connection_problem(from_sim, to_sim)
		if not power_problem.is_empty():
			_notice(power_problem)
			return
		_sim.connect_power(from_sim, to_sim)
		_canvas.apply_connection(from_sim, from_port, to_sim, to_port)
		_refresh_status()
		return

	# Kararı simülasyon verir — kural orada yaşıyor, burada kopyası yok.
	var problem: String = _sim.connection_problem(from_sim, from_port, to_sim, to_port)
	if not problem.is_empty():
		_notice(problem)
		return
	_sim.connect_stations(from_sim, from_port, to_sim, to_port)
	_canvas.apply_connection(from_sim, from_port, to_sim, to_port)
	_refresh_status()


func _on_disconnect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	if _is_power_port(from_sim, from_port) or _is_power_port(to_sim, to_port):
		_sim.disconnect_power(from_sim, to_sim)
		_canvas.remove_connection(from_sim, from_port, to_sim, to_port)
		_refresh_status()
		return
	_sim.disconnect_stations(from_sim, from_port, to_sim, to_port)
	_canvas.remove_connection(from_sim, from_port, to_sim, to_port)
	_refresh_status()


## Bu port bu istasyonun GÜÇ portu mu? `BlockType.power_port_index()` ile
## `FlowBlock._build_power_row`'un kullandığı satır AYNI indekstir.
func _is_power_port(sim_id: int, port: int) -> bool:
	var station: SimStation = _sim.get_station(sim_id)
	if station == null:
		return false
	if not (station.type.is_power_generator() or station.type.is_power_consumer() or station.type.sells_power):
		return false
	return port == station.type.power_port_index()


func _on_delete_requested(sim_ids: Array[int]) -> void:
	var refunded: int = 0
	for sim_id: int in sim_ids:
		var station: SimStation = _sim.get_station(sim_id)
		if station != null:
			refunded += station.type.build_cost / 2
			_progression.refund(station.type.build_cost)
		_sim.remove_station(sim_id)
		_canvas.remove_block(sim_id)
		if _internal_canvas != null:
			_internal_canvas.remove_block(sim_id)
	_refresh_availability()
	if _open_complex_id >= 0:
		_rebuild_complex_canvas()
	_rebuild_main_canvas()
	if refunded > 0:
		_notice("Dismantled. %s gold returned (half the cost)." % GameConfig.format_money(refunded))


func _on_clear_pressed() -> void:
	_sim.clear()
	_canvas.clear_all()
	_progression.reset()
	_accumulator = 0.0
	_research_rate.reset()
	_complex_layout.clear()
	_close_complex()
	_last_research_panel_refresh_tick = -999999
	_sync_item_sale_multipliers()
	_refresh_availability()
	_refresh_iron_ore_value()


## --- Ürün satış geliştirmesi (araştırma ağacının DIŞINDA) -------------------

func _on_iron_ore_upgrade_pressed() -> void:
	var problem: String = _progression.item_upgrade_problem(ItemCatalog.CEVHER, _sim.revenue)
	if not problem.is_empty():
		_notice(problem)
		return
	_progression.try_upgrade_item(ItemCatalog.CEVHER, _sim.revenue)
	_sync_item_sale_multipliers()
	_refresh_availability()
	_refresh_iron_ore_value()
	_notice("Iron Ore now sells for %s gold." % GameConfig.format_money(
		roundi(float(ItemCatalog.CEVHER.base_price) * ProgressionState.item_sale_multiplier(
			ItemCatalog.CEVHER, _progression.item_level(ItemCatalog.CEVHER)))
	))


## `_sim.item_sale_multipliers`'ı `_progression.item_levels`'tan YENİDEN
## KURAR — `auto_collect` ile aynı desen (bkz. FactorySim). Yükleme/sıfırlama
## sonrası eski değerler kalmasın diye tam temizleyip baştan doldurur.
func _sync_item_sale_multipliers() -> void:
	_sim.item_sale_multipliers.clear()
	for item: ItemType in ItemCatalog.all():
		if not item.sale_upgradeable:
			continue
		var level: int = _progression.item_level(item)
		if level > 1:
			_sim.item_sale_multipliers[String(item.id)] = ProgressionState.item_sale_multiplier(item, level)


## Üst bardaki "Iron Ore: X gold" etiketini ve Geliştir düğmesini günceller.
func _refresh_iron_ore_value() -> void:
	var level: int = _progression.item_level(ItemCatalog.CEVHER)
	var price: int = roundi(float(ItemCatalog.CEVHER.base_price) * ProgressionState.item_sale_multiplier(ItemCatalog.CEVHER, level))
	var text: String = "Iron Ore: %s gold" % GameConfig.format_money(price)
	if text != _last_iron_ore_value:
		_last_iron_ore_value = text
		_iron_ore_value.text = text

	var cost: int = ProgressionState.item_upgrade_cost(ItemCatalog.CEVHER, level)
	_iron_ore_upgrade.text = "Upgrade (%s gold)" % GameConfig.format_money(cost)
	_iron_ore_upgrade.disabled = _balance() < cost


## --- Araştırma --------------------------------------------------------------

## Sağdaki araştırma paneli sabit DOCKED değil — yüzen düğmeyle açılıp
## kapanır (bkz. DESIGN.md D28). İkinci basış veya tuvale tıklama kapatır.
func _on_research_toggle_pressed() -> void:
	if _research_panel.visible:
		_research_panel.visible = false
		return
	_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts, _research_rate)
	_research_panel.visible = true


func _on_research_closed() -> void:
	_research_panel.visible = false


## Tuval içinde bir yere (boş alan veya bir düğüm) tıklanınca araştırma
## panelini kapatır — düğümün kendi İşçi/Yükselt/Tahsil Et düğmeleri bunu
## TETİKLEMEZ (Button kendi input'unu tüketir, yukarı sızdırmaz).
func _on_canvas_interacted() -> void:
	_research_panel.visible = false


func _on_unlock_requested(node_id: StringName) -> void:
	var node := ResearchCatalog.find_by_id(node_id)
	if node == null:
		return
	var problem: String = _progression.try_unlock(node, _sim.revenue, _sim.research_counts)
	if not problem.is_empty():
		_notice(problem)
	else:
		if node.unlocks_auto_collect:
			_sim.auto_collect = true
			# Bekleyen para KAYBOLMASIN: otomasyon anindan itibaren yeni
			# satislar zaten dogrudan kasaya gidecek, ama o ana kadar
			# BIRIKMIS olan bakiye bu supurme olmasa oyuncunun bir kez daha
			# elle tahsil etmesini gerektirirdi (kaybolmaz ama kafa karistirir).
			_sim.collect_all()
			_notice("Discovered: %s. Market revenue now reaches your treasury automatically." % node.display_name)
		else:
			_notice("Discovered: %s" % node.display_name)
	_refresh_availability()
	_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts, _research_rate)


## Bir ürünün laboratuvara giden hattını tuvalde bulur ve ortalar.
##
## Yalnızca DOĞRUDAN kaynağı seçer — Dağıtıcı'nın ARKASINDAKİ istasyona kadar
## otomatik geri izlemez (bkz. tasarım sınırı: "en yavaş ürün" ile "kök
## neden" aynı şey değildir). Oyuncu oradan devam eder.
func _on_locate_requested(item_id: StringName) -> void:
	for link: SimLink in _sim.links_into(_arge_lab_sim_id()):
		if _sim.item_id_on_link(link) == item_id:
			if _canvas.focus_on(link.from_id):
				return
	var item: ItemType = ItemCatalog.find_by_id(item_id)
	_notice("No route currently carries %s to the Research Lab." % [
		item.display_name if item != null else String(item_id)
	])


## Sahnede Ar-Ge Sarayı en fazla bir kez kurulabilir varsayımıyla ilk
## bulunanı döner. Yoksa -1.
func _arge_lab_sim_id() -> int:
	for station: SimStation in _sim.stations():
		if station.type.category == BlockType.Category.RESEARCH:
			return station.id
	return -1


## --- HUD --------------------------------------------------------------------

func _refresh_hud() -> void:
	var seconds: int = _sim.tick_count / GameConfig.TICKS_PER_SECOND
	var clock: String = "%02d:%02d" % [seconds / 60, seconds % 60]
	if clock != _last_clock:
		_last_clock = clock
		_clock.text = clock

	var balance: int = _balance()
	var money: String = GameConfig.format_money(balance)
	if money != _last_money:
		_last_money = money
		_money.text = money

	var rate: String = "+%s gold/sec" % GameConfig.format_money(roundi(_current_income_per_sec()))
	if rate != _last_money_rate:
		_last_money_rate = rate
		_money_rate.text = rate

	# Tahsilat artık üst bardan değil, her düğümün kendi Tahsil Et
	# düğmesinden yapılıyor (bkz. DESIGN.md D27) — burası yalnızca toplam
	# bekleyen para için salt okunur bir özet.
	var uncollected: int = _sim.total_uncollected()
	var market_text: String = "Market: %s gold" % GameConfig.format_money(uncollected)
	if market_text != _last_market_accrued:
		_last_market_accrued = market_text
		_market_accrued.text = market_text
	_market_accrued.visible = not _sim.auto_collect

	_research_rate.sample(_sim.tick_count, _sim.research_counts)

	# Bakiye değişince paletin "karşılanabilir" durumu da değişir.
	var balance_changed: bool = balance != _last_balance
	if balance_changed:
		_refresh_availability()
		_refresh_iron_ore_value()

	# Araştırma paneli açıkken ürün ilerlemesi VE bakiye canlı görünmeli.
	#
	# Önceden yalnızca research_total değişince yenileniyordu — panel açıkken
	# para birikip bir araştırmayı karşılar hâle gelse bile "Araştır" düğmesi
	# etkinleşmiyordu, oyuncu paneli kapatıp açmak zorunda kalıyordu.
	var research_total: int = _research_total()
	var research_changed: bool = research_total != _last_research_total
	# Yeni teslimat olmasa da hız/ETA zamanla değişir (akış duruyor, "değişken"
	# oluyor, süre azalıyor) — panel açıkken en az saniyede bir tazelenir.
	var time_to_refresh: bool = (
		_sim.tick_count - _last_research_panel_refresh_tick >= _RESEARCH_PANEL_REFRESH_TICKS
	)
	if _research_panel.visible and (balance_changed or research_changed or time_to_refresh):
		_last_research_total = research_total
		_last_research_panel_refresh_tick = _sim.tick_count
		_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts, _research_rate)

func _research_total() -> int:
	var total: int = 0
	for count: int in _sim.research_counts.values():
		total += count
	return total


## Palet ve slot göstergesini mevcut duruma göre günceller.
func _refresh_availability() -> void:
	var available: Dictionary = {}
	for type: BlockType in _progression.available_blocks(_sim.tick_count):
		available[type.id] = true
	var counts: Dictionary = {}
	for station: SimStation in _sim.stations():
		counts[station.type.id] = int(counts.get(station.type.id, 0)) + 1
	_last_balance = _balance()
	_palette.set_availability(available, _last_balance, counts)
	_create_complex_button.visible = _progression.complexes_available()
	_create_complex_button.disabled = not _progression.complexes_available()
	_refresh_status()


func _refresh_status() -> void:
	pass


func _notice(_text: String) -> void:
	pass


func _on_save_pressed() -> void:
	_save_dialog.popup_centered_ratio(0.6)


func _on_load_pressed() -> void:
	_load_dialog.popup_centered_ratio(0.6)


## --- Kayıt ------------------------------------------------------------------

## Üç bölüm: simülasyon durumu, yerleşim, ilerleme.
## Konum ve ad simülasyonu; para ve kilitler simülasyonu ilgilendirmez.
func _snapshot() -> Dictionary:
	_store_internal_layout()
	var layout: Dictionary = {}
	for block: FlowBlock in _canvas.get_blocks():
		layout[str(block.sim_id)] = {
			"x": block.position_offset.x,
			"y": block.position_offset.y,
			"label": block.block_label,
		}
	return {
		"version": SAVE_VERSION,
		"sim": _sim.to_dict(),
		"layout": layout,
		"complex_layout": _complex_layout.duplicate(true),
		"progression": _progression.to_dict(),
	}


func _on_save_path_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_notice("Could not save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(_snapshot(), "\t"))
	file.close()
	_notice("Saved: %s" % path.get_file())


func _on_load_path_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		_notice("File not found.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		_notice("The file is unreadable or invalid.")
		return

	var data: Dictionary = parsed
	var version: int = int(data.get("version", 0))
	if version < 3 or version > SAVE_VERSION:
		_notice("This older save (v%d) cannot be opened." % version)
		return

	_sim.from_dict(data.get("sim", {}))
	_progression.from_dict(data.get("progression", {}))
	_sync_item_sale_multipliers()
	_complex_layout = data.get("complex_layout", {}).duplicate(true)
	_accumulator = 0.0
	# Ar-Ge hız ölçeri kümülatif sayaçlara bakıyor; yükleme sonrası eski
	# örnekler yanlış bir sıçrama gösterirdi.
	_research_rate.reset()
	_last_research_panel_refresh_tick = -999999

	_rebuild_main_canvas(data.get("layout", {}))

	_refresh_availability()
	_notice("Loaded: %s" % path.get_file())


## --- Ironworks Complex UI --------------------------------------------------

func _build_complex_workspace() -> void:
	_complex_workspace = PanelContainer.new()
	_complex_workspace.name = "ComplexWorkspace"
	_complex_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_complex_workspace.visible = false
	_complex_workspace.add_theme_stylebox_override(&"panel", _panel_style(Color(0.10, 0.08, 0.055, 1.0), Color(0.67, 0.47, 0.25, 1.0)))
	add_child(_complex_workspace)

	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 8)
	_complex_workspace.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var back := Button.new()
	back.text = "← Back to Factory"
	back.pressed.connect(_close_complex)
	top.add_child(back)
	_complex_status_label = Label.new()
	_complex_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_complex_status_label.add_theme_font_size_override(&"font_size", 16)
	top.add_child(_complex_status_label)
	_complex_strategy = OptionButton.new()
	_complex_strategy.add_item("Ingot Focus", IronworksComplex.Strategy.INGOT_FOCUS)
	_complex_strategy.add_item("Balanced", IronworksComplex.Strategy.BALANCED)
	_complex_strategy.add_item("Plate Focus", IronworksComplex.Strategy.PLATE_FOCUS)
	_complex_strategy.item_selected.connect(_on_complex_strategy_selected)
	top.add_child(_complex_strategy)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var palette := VBoxContainer.new()
	palette.custom_minimum_size = Vector2(180, 0)
	body.add_child(palette)
	var palette_title := Label.new()
	palette_title.text = "COMPLEX MACHINES"
	palette.add_child(palette_title)
	for type: BlockType in [BlockCatalog.MINE_EXTRACTOR, BlockCatalog.ERITME, BlockCatalog.PRES]:
		var add := Button.new()
		add.text = "+ " + type.display_name
		add.tooltip_text = "Build inside the open complex"
		add.pressed.connect(_add_machine_to_open_complex.bind(type))
		palette.add_child(add)
	var source_title := Label.new()
	source_title.text = "EXTERNAL POWER"
	palette.add_child(source_title)
	_complex_power_sources = OptionButton.new()
	palette.add_child(_complex_power_sources)
	var connect_power := Button.new()
	connect_power.text = "Connect Power Bus"
	connect_power.pressed.connect(_connect_open_complex_power)
	palette.add_child(connect_power)

	_internal_canvas = FlowCanvas.new()
	_internal_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_internal_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_internal_canvas.custom_minimum_size = Vector2(520, 380)
	body.add_child(_internal_canvas)
	_internal_canvas.add_requested.connect(_on_add_requested)
	_internal_canvas.connect_requested.connect(_on_connect_requested)
	_internal_canvas.disconnect_requested.connect(_on_disconnect_requested)
	_internal_canvas.delete_requested.connect(_on_delete_requested)
	_internal_canvas.action_requested.connect(_on_canvas_action_requested)
	_internal_canvas.block_selected.connect(_on_internal_block_selected)

	var inspector := VBoxContainer.new()
	inspector.custom_minimum_size = Vector2(270, 0)
	body.add_child(inspector)
	_complex_bus_label = Label.new()
	_complex_bus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(_complex_bus_label)
	_complex_inspector = Label.new()
	_complex_inspector.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(_complex_inspector)
	var input_bus := Button.new()
	input_bus.text = "Use Material Bus Input"
	input_bus.pressed.connect(_set_selected_bus_mode.bind(true, true))
	inspector.add_child(input_bus)
	var direct_input := Button.new()
	direct_input.text = "Use Direct Input"
	direct_input.pressed.connect(_set_selected_bus_mode.bind(true, false))
	inspector.add_child(direct_input)
	var output_bus := Button.new()
	output_bus.text = "Use Material Bus Output"
	output_bus.pressed.connect(_set_selected_bus_mode.bind(false, true))
	inspector.add_child(output_bus)
	var direct_output := Button.new()
	direct_output.text = "Use Direct Output"
	direct_output.pressed.connect(_set_selected_bus_mode.bind(false, false))
	inspector.add_child(direct_output)
	var power_bus := Button.new()
	power_bus.text = "Use Power Bus"
	power_bus.pressed.connect(_set_selected_power_bus.bind(true))
	inspector.add_child(power_bus)
	var direct_power := Button.new()
	direct_power.text = "Use Direct Power"
	direct_power.pressed.connect(_set_selected_power_bus.bind(false))
	inspector.add_child(direct_power)


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_create_complex_pressed() -> void:
	if not _progression.complexes_available():
		_notice("Discover Industrial Organization first.")
		return
	var selected: Array[int] = _canvas.selected_sim_ids()
	var complex_id: int
	if selected.is_empty():
		complex_id = _sim.create_empty_complex()
		_complex_layout[str(complex_id)] = {"x": _canvas.viewport_center().x, "y": _canvas.viewport_center().y, "stations": {}}
	else:
		complex_id = _sim.create_complex(selected)
		if complex_id < 0:
			_notice("Select at least two connected, eligible workshops that are not already in a complex.")
			return
		var positions: Dictionary = {}
		var center := Vector2.ZERO
		for station_id: int in selected:
			var block: FlowBlock = _canvas.get_block(station_id)
			if block != null:
				positions[str(station_id)] = {"x": block.position_offset.x, "y": block.position_offset.y}
				center += block.position_offset
		center /= maxf(1.0, float(selected.size()))
		_complex_layout[str(complex_id)] = {"x": center.x, "y": center.y, "stations": positions}
	_rebuild_main_canvas()
	_open_complex(complex_id)


func _open_complex(complex_id: int) -> void:
	if _sim.get_complex(complex_id) == null:
		return
	_open_complex_id = complex_id
	get_node("Root").visible = false
	_research_toggle.visible = false
	_complex_workspace.visible = true
	_rebuild_complex_canvas()


func _close_complex() -> void:
	_store_internal_layout()
	_open_complex_id = -1
	if _complex_workspace != null:
		_complex_workspace.visible = false
	get_node("Root").visible = true
	_research_toggle.visible = true


func _rebuild_main_canvas(saved_layout: Dictionary = {}) -> void:
	var live_layout: Dictionary = saved_layout.duplicate(true)
	for block: FlowBlock in _canvas.get_blocks():
		live_layout[str(block.sim_id)] = {"x": block.position_offset.x, "y": block.position_offset.y, "label": block.block_label}
	_canvas.clear_all()
	for station: SimStation in _sim.stations():
		if _sim.complex_for_station(station.id) != null:
			continue
		var entry: Dictionary = live_layout.get(str(station.id), {})
		var block: FlowBlock = _canvas.spawn_block(station.id, station.type, Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))))
		if entry.has("label"):
			block.set_param(&"label", entry["label"])
	for link: SimLink in _sim.links():
		if _canvas.get_block(link.from_id) != null and _canvas.get_block(link.to_id) != null:
			_canvas.apply_connection(link.from_id, link.from_port, link.to_id, link.to_port)
	for power_link: PowerLink in _sim.power_links():
		var src: SimStation = _sim.get_station(power_link.from_id)
		var dst: SimStation = _sim.get_station(power_link.to_id)
		if src != null and dst != null and _canvas.get_block(src.id) != null and _canvas.get_block(dst.id) != null:
			_canvas.apply_connection(src.id, src.type.power_port_index(), dst.id, dst.type.power_port_index())
	for complex: IronworksComplex in _sim.complexes():
		var entry: Dictionary = _complex_layout.get(str(complex.id), {})
		_canvas.spawn_complex(complex.id, complex.display_name, complex.station_ids.size(), Vector2(float(entry.get("x", 200.0)), float(entry.get("y", 200.0))))


func _rebuild_complex_canvas() -> void:
	if _internal_canvas == null:
		return
	var complex: IronworksComplex = _sim.get_complex(_open_complex_id)
	if complex == null:
		_close_complex()
		return
	_internal_canvas.clear_all()
	var entry: Dictionary = _complex_layout.get(str(complex.id), {})
	var positions: Dictionary = entry.get("stations", {})
	for station_id: int in complex.station_ids:
		var station: SimStation = _sim.get_station(station_id)
		if station == null:
			continue
		var at: Dictionary = positions.get(str(station_id), {})
		_internal_canvas.spawn_block(station.id, station.type, Vector2(float(at.get("x", 160.0)), float(at.get("y", 130.0))))
	for link: SimLink in _sim.links():
		if complex.contains(link.from_id) and complex.contains(link.to_id):
			_internal_canvas.apply_connection(link.from_id, link.from_port, link.to_id, link.to_port)
	for power_link: PowerLink in _sim.power_links():
		if complex.contains(power_link.from_id) and complex.contains(power_link.to_id):
			var src: SimStation = _sim.get_station(power_link.from_id)
			var dst: SimStation = _sim.get_station(power_link.to_id)
			if src != null and dst != null:
				_internal_canvas.apply_connection(src.id, src.type.power_port_index(), dst.id, dst.type.power_port_index())
	_complex_strategy.select(int(complex.strategy))
	_refresh_complex_workspace()


func _store_internal_layout() -> void:
	if _internal_canvas == null or _open_complex_id < 0:
		return
	var entry: Dictionary = _complex_layout.get(str(_open_complex_id), {"stations": {}})
	var positions: Dictionary = entry.get("stations", {})
	for block: FlowBlock in _internal_canvas.get_blocks():
		positions[str(block.sim_id)] = {"x": block.position_offset.x, "y": block.position_offset.y}
	entry["stations"] = positions
	_complex_layout[str(_open_complex_id)] = entry


func _refresh_complex_workspace() -> void:
	var complex: IronworksComplex = _sim.get_complex(_open_complex_id)
	if complex == null:
		return
	_complex_status_label.text = "%s  •  %d Machines  •  %s" % [complex.display_name, complex.station_ids.size(), _complex_status(complex)]
	var stocks: PackedStringArray = PackedStringArray()
	for item_id: StringName in complex.material_bus:
		stocks.append("%s: %d / %d" % [item_id.capitalize(), complex.material_bus[item_id], complex.material_capacity])
	stocks.sort()
	_complex_bus_label.text = "MATERIAL BUS\n%s\n\nPOWER BUS\n%s" % ["\n".join(stocks) if not stocks.is_empty() else "Empty", _complex_power_text(complex)]
	_refresh_power_sources(complex)


func _complex_status(complex: IronworksComplex) -> String:
	var running: int = 0
	for station_id: int in complex.station_ids:
		var station: SimStation = _sim.get_station(station_id)
		if station != null and station.status == SimStation.Status.RUNNING:
			running += 1
	return "Running" if running == complex.station_ids.size() else "Partially Running"


func _complex_power_text(complex: IronworksComplex) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for station_id: int in complex.station_ids:
		if complex.power_bus_members.has(station_id):
			var station: SimStation = _sim.get_station(station_id)
			if station != null:
				parts.append("%s: %d / %d" % [station.type.display_name, _sim.delivered_power(station_id), station.type.power_required_per_tick])
	return "\n".join(parts) if not parts.is_empty() else "No Power Bus consumers"


func _refresh_power_sources(complex: IronworksComplex) -> void:
	var selected_id: int = _complex_power_sources.get_selected_id()
	_complex_power_sources.clear()
	for station: SimStation in _sim.stations():
		if station.type.is_power_generator() and not complex.contains(station.id):
			_complex_power_sources.add_item(station.type.display_name + " #" + str(station.id), station.id)
	if selected_id >= 0:
		for index in _complex_power_sources.item_count:
			if _complex_power_sources.get_item_id(index) == selected_id:
				_complex_power_sources.select(index)


func _on_complex_strategy_selected(index: int) -> void:
	if _open_complex_id >= 0:
		_sim.set_complex_strategy(_open_complex_id, _complex_strategy.get_item_id(index))


func _on_internal_block_selected(block: FlowBlock) -> void:
	var station: SimStation = _sim.get_station(block.sim_id)
	if station != null:
		_complex_inspector.text = "%s\n%s\nInput and output can each use either a direct route or the shared Material Bus." % [station.type.display_name, station.status_label().capitalize()]


func _set_selected_bus_mode(is_input: bool, shared: bool) -> void:
	var block: FlowBlock = _internal_canvas.selected_block()
	if block == null:
		_notice("Select a workshop in the complex first.")
		return
	var problem: String = _sim.set_complex_material_mode(_open_complex_id, block.sim_id, 0, is_input, shared)
	if not problem.is_empty():
		_notice(problem)
	else:
		_notice("Material route updated.")


func _set_selected_power_bus(shared: bool) -> void:
	var block: FlowBlock = _internal_canvas.selected_block()
	if block == null:
		_notice("Select a workshop in the complex first.")
		return
	var problem: String = _sim.set_complex_power_bus_member(_open_complex_id, block.sim_id, shared)
	if not problem.is_empty():
		_notice(problem)


func _connect_open_complex_power() -> void:
	if _complex_power_sources.item_count <= 0:
		_notice("Build an external Generator first.")
		return
	var problem: String = _sim.connect_power_to_complex(_complex_power_sources.get_selected_id(), _open_complex_id)
	if not problem.is_empty():
		_notice(problem)


func _add_machine_to_open_complex(type: BlockType) -> void:
	if _open_complex_id < 0 or not _progression.is_block_available(type, _sim.tick_count):
		return
	if type.max_instances > 0 and _count_of_type(type.id) >= type.max_instances:
		_notice("This machine has reached its instance limit.")
		return
	if not _progression.try_pay(type.build_cost, _sim.revenue):
		_notice("Not enough gold.")
		return
	var station_id: int = _sim.add_station(type)
	var problem: String = _sim.add_station_to_complex(_open_complex_id, station_id)
	if not problem.is_empty():
		_sim.remove_station(station_id)
		_progression.refund(type.build_cost * 2)
		_notice(problem)
		return
	var complex_entry: Dictionary = _complex_layout.get(str(_open_complex_id), {"stations": {}})
	var positions: Dictionary = complex_entry.get("stations", {})
	positions[str(station_id)] = {"x": 160.0 + 40.0 * positions.size(), "y": 180.0}
	complex_entry["stations"] = positions
	_complex_layout[str(_open_complex_id)] = complex_entry
	_rebuild_complex_canvas()
	_rebuild_main_canvas()
	_refresh_availability()
