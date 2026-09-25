class_name FactoryScreen
extends Control

## Tam ekran fabrika görünümü: eski oyunun düğüm tuvali (FlowCanvas) + palet.
##
## Kural hesaplamaz: blok ekleme, bağlama, silme kararlarını FactoryInterior
## verir; burası isteği iletir ve sonucu tuvale yazar. Haritanın üst çubuğu
## (para, hız düğmeleri) bu ekranın üstünde görünür kalır; oyun saati
## fabrikadayken de işler. "Back to map" ya da Esc ile kapanır.

signal closed

const IndustrialTheme = preload("res://common/industrial_theme.gd")

## Kendiliğinden gelen giriş kapılarının tuvaldeki sütunu ve aralığı.
const GATE_ORIGIN: Vector2 = Vector2(40.0, 40.0)
const GATE_SPACING: float = 150.0
## Kapı başlığında stok gösterimi: "Logs in · 32/50".
const GATE_TITLE_FORMAT: String = "%s · %d/%d"

@onready var canvas: FlowCanvas = %Canvas
@onready var palette: FactoryPalette = %Palette
@onready var title_label: Label = %FactoryTitle
@onready var message_label: Label = %FactoryMessage
@onready var back_button: Button = %BackButton

var _interior: FactoryInterior = null
## FactoryInterior -> {istasyon id: tuvaldeki konum}. Görünüm bilgisidir,
## simülasyonda tutulmaz; fabrika kapanıp açılınca bloklar yerinde kalır.
var _positions: Dictionary = {}


func _ready() -> void:
	hide()
	# Eski oyunun editör teması: düğümler onunla tasarlandı.
	theme = IndustrialTheme.build()
	back_button.pressed.connect(close)
	palette.block_requested.connect(func(type: BlockType) -> void:
		_add_block(type, canvas.viewport_center()))
	canvas.add_requested.connect(_add_block)
	canvas.connect_requested.connect(_on_connect_requested)
	canvas.disconnect_requested.connect(_on_disconnect_requested)
	canvas.delete_requested.connect(_on_delete_requested)


func setup(config: MapConfig) -> void:
	palette.build(config)


func is_open() -> bool:
	return visible and _interior != null


func open(interior: FactoryInterior, factory_title: String) -> void:
	_interior = interior
	title_label.text = factory_title
	message_label.text = ""
	canvas.clear_all()
	_sync_blocks()
	for link: SimLink in interior.links():
		canvas.apply_connection(link.from_id, link.from_port, link.to_id, link.to_port)
	show()


func close() -> void:
	if _interior == null:
		return
	_save_positions()
	canvas.clear_all()
	_interior = null
	hide()
	closed.emit()


func _process(_delta: float) -> void:
	if not is_open():
		return
	# Hat yeni bir mal getirdiyse giriş kapısı içeride kendiliğinden kurulmuştur.
	_sync_blocks()
	_render()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if is_open() and key != null and key.pressed and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


## Simülasyonda olup tuvalde olmayan istasyonların görüntüsünü kurar.
func _sync_blocks() -> void:
	var saved: Dictionary = _positions.get(_interior, {})
	var gate_index: int = 0
	for station: SimStation in _interior.stations():
		var gate: FactoryGate = station.type as FactoryGate
		var is_input_gate: bool = gate != null and gate.direction == FactoryGate.Direction.IN
		if canvas.get_block(station.id) == null:
			var at: Vector2 = saved.get(station.id, canvas.viewport_center())
			if is_input_gate and not saved.has(station.id):
				at = GATE_ORIGIN + Vector2(0.0, GATE_SPACING * gate_index)
			canvas.spawn_block(station.id, station.type, at)
		if is_input_gate:
			gate_index += 1


func _render() -> void:
	for block: FlowBlock in canvas.get_blocks():
		var station: SimStation = _interior.get_station(block.sim_id)
		if station == null:
			continue
		var gate: FactoryGate = station.type as FactoryGate
		# Kapıların boş portu kurulum hatası sayılmaz (kullanılmayan mal olabilir).
		var unwired: int = 0 if gate != null else _interior.unwired_port_count(station.id)
		block.render_state(station, _interior.tick_count, unwired)
		if gate != null:
			var stock: float = (_interior.input_stock(gate.good)
					if gate.direction == FactoryGate.Direction.IN else _interior.output_stock(gate.good))
			var text: String = GATE_TITLE_FORMAT % [gate.display_name, floori(stock), _interior.capacity]
			if block.block_label != text:
				block.set_param(&"label", text)


func _add_block(type: BlockType, at: Vector2) -> void:
	if _interior == null:
		return
	var id: int = _interior.add_station(type)
	canvas.spawn_block(id, type, at)
	message_label.text = ""


func _on_connect_requested(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	var problem: String = _interior.connection_problem(from_id, from_port, to_id, to_port)
	if problem.is_empty() and _interior.connect_stations(from_id, from_port, to_id, to_port):
		canvas.apply_connection(from_id, from_port, to_id, to_port)
		message_label.text = ""
	else:
		# Eski oyunun metni ayırıcıyı "Crossroads" diye anar; burada adı Splitter.
		message_label.text = problem.replace("Crossroads", "Splitter")


func _on_disconnect_requested(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	_interior.disconnect_stations(from_id, from_port, to_id, to_port)
	canvas.remove_connection(from_id, from_port, to_id, to_port)


func _on_delete_requested(ids: Array[int]) -> void:
	var kept: bool = false
	for id: int in ids:
		if _interior.can_remove(id):
			_interior.remove_station(id)
			canvas.remove_block(id)
		else:
			kept = true
	message_label.text = "Input gates can't be removed." if kept else ""


func _save_positions() -> void:
	var saved: Dictionary = {}
	for block: FlowBlock in canvas.get_blocks():
		saved[block.sim_id] = block.position_offset
	_positions[_interior] = saved
