class_name GameController
extends Control

## ORKESTRATÖR. Simülasyonu sahiplenir, tick'i sürer, görselleri besler.
##
## İş mantığı burada DEĞİL — üretim kuralları `FactorySim`'de, içerik
## `.tres`'lerde. Buranın işi: bileşenlerden gelen YUKARI niyetleri alıp
## simülasyona sormak, cevabı AŞAĞI komutla görsellere yazmak.
##
## Palet, tuval ve denetçi birbirini tanımaz. Hepsi buradan geçer.

## Kayıt biçimi. v1 (simülasyon öncesi) artık okunamıyor.
const SAVE_VERSION: int = 2

## Hız seçenekleri. 0 = duraklatıldı.
const SPEEDS: Array[int] = [0, 1, 2, 4]

@onready var _canvas: FlowCanvas = %Canvas
@onready var _palette: BlockPalette = %Palette
@onready var _inspector: BlockInspector = %Inspector
@onready var _status: Label = %Status
@onready var _clock: Label = %Clock
@onready var _money: Label = %Money
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _load_dialog: FileDialog = %LoadDialog
@onready var _notice_timer: Timer = %NoticeTimer

var _sim: FactorySim = FactorySim.new()
var _speed: int = 1

## Kesirli tick borcu. Kare süresi tick süresine tam bölünmediği için gerekli.
var _accumulator: float = 0.0

var _speed_buttons: Array[Button] = []

## Son yazılan metinler. Label.text her karede yazılırsa boşuna font shaping
## olur; ayrıca saat saniyede bir, para nadiren değişir.
var _last_clock: String = ""
var _last_money: String = ""
var _last_status: String = ""


func _ready() -> void:
	_palette.block_requested.connect(_on_palette_request)
	_inspector.param_changed.connect(_on_param_changed)

	_canvas.add_requested.connect(_on_add_requested)
	_canvas.connect_requested.connect(_on_connect_requested)
	_canvas.disconnect_requested.connect(_on_disconnect_requested)
	_canvas.delete_requested.connect(_on_delete_requested)
	_canvas.block_selected.connect(_inspector.show_block)
	_canvas.selection_cleared.connect(_inspector.clear)

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

	_build_sample_flow()


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
			block.render_state(station)


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
	var sim_id: int = _sim.add_station(type)
	_canvas.spawn_block(sim_id, type, at)
	_refresh_status()


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
	for sim_id: int in sim_ids:
		_sim.remove_station(sim_id)
		_canvas.remove_block(sim_id)
	_refresh_status()


func _on_clear_pressed() -> void:
	_sim.clear()
	_canvas.clear_all()
	_accumulator = 0.0
	_refresh_status()


## --- HUD --------------------------------------------------------------------

func _refresh_hud() -> void:
	var seconds: int = _sim.tick_count / GameConfig.TICKS_PER_SECOND
	var clock: String = "%02d:%02d" % [seconds / 60, seconds % 60]
	if clock != _last_clock:
		_last_clock = clock
		_clock.text = clock

	var money: String = "%s ₺" % GameConfig.format_money(_sim.revenue)
	if money != _last_money:
		_last_money = money
		_money.text = money

	# Bildirim gösteriliyorken durum çubuğunu ezmeyiz.
	if _notice_timer.is_stopped():
		_refresh_status()


func _refresh_status() -> void:
	var text: String = "%d istasyon  ·  %d bağlantı  ·  %d tıkalı  ·  %d aç" % [
		_sim.station_count(), _sim.link_count(),
		_sim.count_with_status(SimStation.Status.BLOCKED),
		_sim.count_with_status(SimStation.Status.STARVED),
	]
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

## Simülasyon durumu + yerleşim. Konum ve ad simülasyonu ilgilendirmez,
## o yüzden ayrı bölümde tutulur.
func _snapshot() -> Dictionary:
	var layout: Dictionary = {}
	for block: FlowBlock in _canvas.get_blocks():
		layout[str(block.sim_id)] = {
			"x": block.position_offset.x,
			"y": block.position_offset.y,
			"label": block.block_label,
		}
	return {"version": SAVE_VERSION, "sim": _sim.to_dict(), "layout": layout}


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
	_canvas.clear_all()
	_accumulator = 0.0

	var layout: Dictionary = data.get("layout", {})
	for station: SimStation in _sim.stations():
		var entry: Dictionary = layout.get(str(station.id), {})
		var at := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		var block: FlowBlock = _canvas.spawn_block(station.id, station.type, at)
		if entry.has("label"):
			block.set_param(&"label", entry["label"])

	for link: SimLink in _sim.links():
		_canvas.apply_connection(link.from_id, link.from_port, link.to_id, link.to_port)

	_refresh_status()
	_notice("Yüklendi: %s" % path.get_file())


## --- Açılış örneği ----------------------------------------------------------

## Uygulama boş bir tuvalle açılmasın diye örnek bir hat kurar.
## İki şeyi gösterir: Montaj'da iki hattın birleşmesi (Levha + Vida) ve
## Kalite Kontrol'ün Ret çıkışının Geri Dönüşüm üzerinden hatta dönmesi.
func _build_sample_flow() -> void:
	var layout: Array = [
		[BlockCatalog.MADEN_OCAGI, Vector2(40, 260)],
		[BlockCatalog.ERITME, Vector2(300, 260)],
		[BlockCatalog.PRES, Vector2(560, 260)],
		[BlockCatalog.HADDE, Vector2(820, 440)],
		[BlockCatalog.KESIM, Vector2(1080, 440)],
		[BlockCatalog.MONTAJ, Vector2(1340, 260)],
		[BlockCatalog.KALITE, Vector2(1600, 260)],
		[BlockCatalog.SEVKIYAT, Vector2(1880, 160)],
		[BlockCatalog.GERI_DONUSUM, Vector2(1880, 440)],
	]
	var ids: Array[int] = []
	for entry: Array in layout:
		var type: BlockType = entry[0]
		var sim_id: int = _sim.add_station(type)
		_canvas.spawn_block(sim_id, type, entry[1] as Vector2)
		ids.append(sim_id)

	# [kaynak indeksi, kaynak port, hedef indeksi, hedef port]
	var wires: Array = [
		[0, 0, 1, 0], [1, 0, 2, 0],
		[2, 0, 3, 0],   # Levha -> Hadde
		[3, 0, 4, 0],   # Çubuk -> Kesim
		[2, 0, 5, 0],   # Levha -> Montaj girdi 1
		[4, 0, 5, 1],   # Vida  -> Montaj girdi 2
		[5, 0, 6, 0],   # Gövde -> Kalite
		[6, 0, 7, 0],   # Uygun -> Sevkiyat
		[6, 1, 8, 0],   # Ret   -> Geri Dönüşüm
		[8, 0, 2, 0],   # Külçe -> Pres (geri besleme)
	]
	for wire: Array in wires:
		_on_connect_requested(ids[wire[0]], wire[1], ids[wire[2]], wire[3])

	_refresh_status()
