class_name GameController
extends Control

## ORKESTRATÖR. Simülasyonu ve ilerlemeyi sahiplenir, tick'i sürer,
## görselleri besler.
##
## İş mantığı burada DEĞİL — üretim kuralları `FactorySim`'de, ekonomi ve
## kilitler `ProgressionState`'te, içerik `.tres`'lerde. Buranın işi:
## bileşenlerden gelen YUKARI niyetleri alıp doğru mantığa sormak, cevabı
## AŞAĞI komutla görsellere yazmak.

## Kayıt biçimi. v2'de ilerleme durumu yoktu.
const SAVE_VERSION: int = 3

## Hız seçenekleri. 0 = duraklatıldı.
const SPEEDS: Array[int] = [0, 1, 2, 4]

@onready var _canvas: FlowCanvas = %Canvas
@onready var _palette: BlockPalette = %Palette
@onready var _inspector: BlockInspector = %Inspector
@onready var _research_panel: ResearchPanel = %ResearchPanel
@onready var _status: Label = %Status
@onready var _clock: Label = %Clock
@onready var _money: Label = %Money
@onready var _money_rate: Label = %MoneyRate
@onready var _slots: Label = %Slots
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _load_dialog: FileDialog = %LoadDialog
@onready var _notice_timer: Timer = %NoticeTimer

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
var _last_slots: String = ""
var _last_status: String = ""
var _last_balance: int = -1
var _last_research_total: int = -1
var _last_money_rate: String = ""

## Gelir ve sevkiyat hızı. Sunum verisi — kayıtta yer almaz, yükledikten
## birkaç saniye sonra kendi kendine dolar.
var _income_rate := RateMeter.new()
var _output_rate := RateMeter.new()


func _ready() -> void:
	_palette.block_requested.connect(_on_palette_request)
	_inspector.param_changed.connect(_on_param_changed)

	_canvas.add_requested.connect(_on_add_requested)
	_canvas.connect_requested.connect(_on_connect_requested)
	_canvas.disconnect_requested.connect(_on_disconnect_requested)
	_canvas.delete_requested.connect(_on_delete_requested)
	_canvas.block_selected.connect(_inspector.show_block)
	_canvas.selection_cleared.connect(_inspector.clear)

	_research_panel.unlock_requested.connect(_on_unlock_requested)
	_research_panel.close_requested.connect(_on_research_closed)

	%ResearchButton.pressed.connect(_on_research_pressed)
	%ArrangeButton.pressed.connect(_canvas.arrange_nodes)
	%ClearButton.pressed.connect(_on_clear_pressed)
	# Lambda DEĞİL adlandırılmış metot: Godot, yerel değişken yakalayan
	# lambda'ları otomatik çözemiyor ve düğüm silindiğinde çökme riski doğuyor.
	%SaveButton.pressed.connect(_on_save_pressed)
	%LoadButton.pressed.connect(_on_load_pressed)
	_save_dialog.file_selected.connect(_on_save_path_selected)
	_load_dialog.file_selected.connect(_on_load_path_selected)
	_notice_timer.timeout.connect(_refresh_status)

	_speed_buttons = [%PauseButton, %Speed1Button, %Speed2Button, %Speed4Button]
	for index in _speed_buttons.size():
		_speed_buttons[index].pressed.connect(_on_speed_pressed.bind(index))

	_refresh_availability()
	_notice("Maden Ocağı → Eritme Fırını → Sevkiyat kurarak başla.")


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
	for block: FlowBlock in _canvas.get_blocks():
		var station: SimStation = _sim.get_station(block.sim_id)
		if station != null:
			block.render_state(station, _sim.tick_count, _sim.unwired_port_count(block.sim_id))


func _balance() -> int:
	return _progression.balance(_sim.revenue)


## --- Hız --------------------------------------------------------------------

func _on_speed_pressed(index: int) -> void:
	_speed = SPEEDS[index]
	# Hız değişince biriken kesirli borcu taşımayız; yoksa duraklatıp devam
	# edince bir anda toplu tick atar.
	_accumulator = 0.0


## --- Paletten ve denetçiden ------------------------------------------------

func _on_palette_request(type: BlockType) -> void:
	_on_add_requested(type, _canvas.viewport_center())


func _on_param_changed(key: StringName, value: Variant) -> void:
	var block: FlowBlock = _canvas.selected_block()
	if block != null:
		block.set_param(key, value)


## --- Tuvalden gelen niyetler ------------------------------------------------

func _on_add_requested(type: BlockType, at: Vector2) -> void:
	if not _progression.is_block_available(type):
		_notice("%s henüz araştırılmadı." % type.display_name)
		return

	var limit: int = _progression.slot_limit()
	if _sim.station_count() >= limit:
		_notice("Slot dolu (%d/%d) — Fabrika Genişlemesi araştır." % [limit, limit])
		return

	if not _progression.try_pay(type.build_cost, _sim.revenue):
		_notice("Yetersiz bakiye — %s ₺ gerekiyor." % GameConfig.format_money(type.build_cost))
		return

	var sim_id: int = _sim.add_station(type)
	_canvas.spawn_block(sim_id, type, at)
	_refresh_availability()


func _on_connect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	# Kararı simülasyon verir — kural orada yaşıyor, burada kopyası yok.
	var problem: String = _sim.connection_problem(from_sim, from_port, to_sim, to_port)
	if not problem.is_empty():
		_notice(problem)
		return
	_sim.connect_stations(from_sim, from_port, to_sim, to_port)
	_canvas.apply_connection(from_sim, from_port, to_sim, to_port)
	_refresh_status()


func _on_disconnect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	_sim.disconnect_stations(from_sim, from_port, to_sim, to_port)
	_canvas.remove_connection(from_sim, from_port, to_sim, to_port)
	_refresh_status()


func _on_delete_requested(sim_ids: Array[int]) -> void:
	var refunded: int = 0
	for sim_id: int in sim_ids:
		var station: SimStation = _sim.get_station(sim_id)
		if station != null:
			refunded += station.type.build_cost / 2
			_progression.refund(station.type.build_cost)
		_sim.remove_station(sim_id)
		_canvas.remove_block(sim_id)
	_refresh_availability()
	if refunded > 0:
		_notice("Söküldü — %s ₺ iade edildi (yarısı)." % GameConfig.format_money(refunded))


func _on_clear_pressed() -> void:
	_sim.clear()
	_canvas.clear_all()
	_progression.reset()
	_accumulator = 0.0
	_income_rate.reset()
	_output_rate.reset()
	_refresh_availability()


## --- Araştırma --------------------------------------------------------------

func _on_research_pressed() -> void:
	_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts)
	_research_panel.visible = true


func _on_research_closed() -> void:
	_research_panel.visible = false


func _on_unlock_requested(node_id: StringName) -> void:
	var node := ResearchCatalog.find_by_id(node_id)
	if node == null:
		return
	var problem: String = _progression.try_unlock(node, _sim.revenue, _sim.research_counts)
	if not problem.is_empty():
		_notice(problem)
	else:
		_notice("Araştırıldı: %s" % node.display_name)
	_refresh_availability()
	_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts)


## --- HUD --------------------------------------------------------------------

func _refresh_hud() -> void:
	var seconds: int = _sim.tick_count / GameConfig.TICKS_PER_SECOND
	var clock: String = "%02d:%02d" % [seconds / 60, seconds % 60]
	if clock != _last_clock:
		_last_clock = clock
		_clock.text = clock

	var balance: int = _balance()
	var money: String = "%s ₺" % GameConfig.format_money(balance)
	if money != _last_money:
		_last_money = money
		_money.text = money

	_income_rate.sample(_sim.tick_count, _sim.revenue)
	_output_rate.sample(_sim.tick_count, _sim.total_sold())
	var rate: String = "+%s ₺/dk" % GameConfig.format_money(roundi(_income_rate.per_minute()))
	if rate != _last_money_rate:
		_last_money_rate = rate
		_money_rate.text = rate

	var slots: String = "%d / %d" % [_sim.station_count(), _progression.slot_limit()]
	if slots != _last_slots:
		_last_slots = slots
		_slots.text = slots

	# Bakiye değişince paletin "karşılanabilir" durumu da değişir.
	if balance != _last_balance:
		_refresh_availability()

	# Araştırma paneli açıkken ürün ilerlemesi canlı görünmeli.
	var research_total: int = _research_total()
	if _research_panel.visible and research_total != _last_research_total:
		_last_research_total = research_total
		_research_panel.refresh(_progression, _sim.revenue, _sim.research_counts)

	if _notice_timer.is_stopped():
		_refresh_status()


func _research_total() -> int:
	var total: int = 0
	for count: int in _sim.research_counts.values():
		total += count
	return total


## Palet ve slot göstergesini mevcut duruma göre günceller.
func _refresh_availability() -> void:
	var available: Dictionary = {}
	for type: BlockType in _progression.available_blocks():
		available[type.id] = true
	_last_balance = _balance()
	_palette.set_availability(available, _last_balance)
	_refresh_status()


func _refresh_status() -> void:
	# Sayım, düğümlerin ÇERÇEVESİNDE gösterilen durumdan yapılır. Ham
	# simülasyon durumu her tick değişiyor; iki ayrı kaynaktan okursak
	# düğüm yeşilken alt çubuk "boşta" der ve oyuncu hangisine inanacağını
	# bilemez.
	var idle: int = 0
	var unwired: int = 0
	for block: FlowBlock in _canvas.get_blocks():
		match block.shown_display:
			FlowBlock.Display.IDLE: idle += 1
			FlowBlock.Display.UNWIRED: unwired += 1

	var text: String = "%d istasyon  ·  %d bağlantı  ·  %d boşta  ·  sevkiyat %.1f/dk" % [
		_sim.station_count(), _sim.link_count(), idle, _output_rate.per_minute(),
	]
	if unwired > 0:
		text += "  ·  %d istasyonun portu boşta" % unwired
	if text == _last_status:
		return
	_last_status = text
	_status.text = text


func _notice(text: String) -> void:
	_status.text = text
	_last_status = ""  # bildirim bitince durum yeniden yazılsın
	_notice_timer.start()


func _on_save_pressed() -> void:
	_save_dialog.popup_centered_ratio(0.6)


func _on_load_pressed() -> void:
	_load_dialog.popup_centered_ratio(0.6)


## --- Kayıt ------------------------------------------------------------------

## Üç bölüm: simülasyon durumu, yerleşim, ilerleme.
## Konum ve ad simülasyonu; para ve kilitler simülasyonu ilgilendirmez.
func _snapshot() -> Dictionary:
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
		"progression": _progression.to_dict(),
	}


func _on_save_path_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_notice("Kaydedilemedi: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(_snapshot(), "\t"))
	file.close()
	_notice("Kaydedildi: %s" % path.get_file())


func _on_load_path_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		_notice("Dosya bulunamadı.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		_notice("Dosya okunamadı veya biçimi geçersiz.")
		return

	var data: Dictionary = parsed
	var version: int = int(data.get("version", 0))
	if version != SAVE_VERSION:
		_notice("Bu kayıt eski bir sürümden (v%d), açılamıyor." % version)
		return

	_sim.from_dict(data.get("sim", {}))
	_progression.from_dict(data.get("progression", {}))
	_canvas.clear_all()
	_accumulator = 0.0
	# Hız ölçerler kümülatif sayaçlara bakıyor; yükleme sonrası eski örnekler
	# yanlış bir sıçrama gösterirdi.
	_income_rate.reset()
	_output_rate.reset()

	var layout: Dictionary = data.get("layout", {})
	for station: SimStation in _sim.stations():
		var entry: Dictionary = layout.get(str(station.id), {})
		var at := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		var block: FlowBlock = _canvas.spawn_block(station.id, station.type, at)
		if entry.has("label"):
			block.set_param(&"label", entry["label"])

	for link: SimLink in _sim.links():
		_canvas.apply_connection(link.from_id, link.from_port, link.to_id, link.to_port)

	_refresh_availability()
	_notice("Yüklendi: %s" % path.get_file())
