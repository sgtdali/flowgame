class_name FlowCanvas
extends GraphEdit

## Üretim hattının çizildiği tuval.
##
## MİMARİ: Bu bir GÖRÜNTÜ. Artık kendi başına karar vermez — kullanıcı bir şey
## yapmak istediğinde YUKARI niyet bildirir (`connect_requested` gibi), kararı
## GameController verir ve sonucu AŞAĞI komutla buraya yazar (`apply_connection`).
##
## Neden böyle: bağlantının geçerli olup olmadığını bilen tek yer simülasyon
## (ürün tipleri uyuyor mu?). Tuval bunu bilmeye çalışsaydı kuralın iki kopyası
## olurdu ve er geç ayrışırlardı.

## Port tipi — GraphEdit yalnızca aynı tipteki portların bağlanmasına izin verir.
const PORT_TYPE_MATERIAL: int = 0
## Güç portu — bkz. FlowBlock.PORT_TYPE_POWER. GraphEdit'in kendi tip
## denetimi malzeme ve güç tellerinin karışmasını burada, sürükle-bırak
## sırasında engeller.
const PORT_TYPE_POWER: int = 1
const COLOR_MATERIAL_CONNECTION := Color(0.76, 0.57, 0.31, 0.95)
const COLOR_POWER_CONNECTION := Color(0.96, 0.79, 0.22, 0.98)
const SMOOTH_STEP_RADIUS: float = 22.0
const SMOOTH_STEP_SEGMENTS: int = 5

## Kullanıcı niyetleri (yukarı).
signal add_requested(type: BlockType, at: Vector2)
signal connect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int)
signal disconnect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int)
signal delete_requested(sim_ids: Array[int])
signal block_selected(block: FlowBlock)
signal selection_cleared
signal action_requested(block: FlowBlock, action: StringName)
signal complex_open_requested(complex_id: int)

## Tuvale (boş alana veya bir düğüme) tıklanınca yukarı bildirilir. Düğümün
## kendi Yükselt/Tahsil Et/İşçi düğmeleri bunu TETİKLEMEZ — Button kendi
## input'unu tüketip yukarı bırakmaz. GameController bunu araştırma
## yan panelini kapatmak için kullanır (bkz. DESIGN.md D28).
signal interacted

var _selected: FlowBlock = null
var _by_sim_id: Dictionary = {}   # sim_id -> FlowBlock
var _complex_by_id: Dictionary = {} # complex id -> FlowComplexNode
var _next_node_index: int = 1


func _ready() -> void:
	resized.connect(_schedule_scrollbar_hide)
	call_deferred("_hide_internal_scrollbars")
	right_disconnects = true
	show_grid = true
	snapping_enabled = true
	snapping_distance = 20
	minimap_enabled = true
	minimap_size = Vector2(180.0, 120.0)
	minimap_opacity = 0.6
	add_theme_color_override(&"grid_major", Color(0.37, 0.29, 0.19, 0.56))
	add_theme_color_override(&"grid_minor", Color(0.26, 0.21, 0.15, 0.42))
	# Hem kurulu bağlantı hem de sürükleme önizlemesi GraphEdit'in aynı rota
	# sağlayıcısından geçer. Böylece fareyle yeni bir tel çekerken de Smooth Step
	# görünür; ayrı bir koyu yerleşik tel çizilmez.
	connection_lines_curvature = 0.0
	connection_lines_thickness = 2.5
	connection_lines_antialiased = true
	add_theme_color_override(&"connection_rim_color", Color.TRANSPARENT)
	add_theme_color_override(&"connection_valid_target_color", COLOR_MATERIAL_CONNECTION)
	add_theme_color_override(&"connection_invalid_target_color", Color(0.85, 0.35, 0.28, 0.95))
	zoom_min = 0.35
	zoom_max = 2.0

	add_valid_connection_type(PORT_TYPE_MATERIAL, PORT_TYPE_MATERIAL)
	add_valid_connection_type(PORT_TYPE_POWER, PORT_TYPE_POWER)

	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)


func _process(_delta: float) -> void:
	call_deferred("_hide_internal_scrollbars")


## GraphEdit bunu hem mevcut bağlantılar hem de bağlantı sürükleme önizlemesi
## için çağırır. Böylece iki çizim sistemi birbirinin üstüne binmez.
func _get_connection_line(from: Vector2, to: Vector2) -> PackedVector2Array:
	return _smooth_step_points(from, to)


func _smooth_step_points(from: Vector2, to: Vector2) -> PackedVector2Array:
	var x_direction: float = 1.0 if to.x >= from.x else -1.0
	var y_direction: float = 1.0 if to.y >= from.y else -1.0
	var horizontal_half: float = absf(to.x - from.x) * 0.5
	var vertical_distance: float = absf(to.y - from.y)
	# Kısa mesafede köşe yarıçapı küçülür; bağlantı asla düz bir çizgiye
	# geri dönmez. Aynı hizada iki port varsa küçük bir Smooth Step sapması
	# yaratılır ki rota yine okunur kalsın.
	var corner_radius: float = minf(SMOOTH_STEP_RADIUS, maxf(2.0, horizontal_half * 0.5))
	if vertical_distance > 0.0:
		corner_radius = minf(corner_radius, maxf(2.0, vertical_distance * 0.5))
	else:
		y_direction = 1.0
	var middle_x: float = (from.x + to.x) * 0.5
	var first_before := Vector2(middle_x - x_direction * corner_radius, from.y)
	var first_after := Vector2(middle_x, from.y + y_direction * corner_radius)
	var second_before := Vector2(middle_x, to.y - y_direction * corner_radius)
	var second_after := Vector2(middle_x + x_direction * corner_radius, to.y)
	var points := PackedVector2Array([from, first_before])
	_append_quadratic(points, first_before, Vector2(middle_x, from.y), first_after)
	points.append(second_before)
	_append_quadratic(points, second_before, Vector2(middle_x, to.y), second_after)
	points.append(to)
	return points


func _append_quadratic(points: PackedVector2Array, from: Vector2, control: Vector2, to: Vector2) -> void:
	for step in range(1, SMOOTH_STEP_SEGMENTS + 1):
		var t: float = float(step) / float(SMOOTH_STEP_SEGMENTS)
		var inverse: float = 1.0 - t
		points.append(inverse * inverse * from + 2.0 * inverse * t * control + t * t * to)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		interacted.emit()


func _schedule_scrollbar_hide() -> void:
	call_deferred("_hide_internal_scrollbars")


func _hide_internal_scrollbars() -> void:
	_hide_scrollbars_in(self)


func _hide_scrollbars_in(root: Node) -> void:
	for child: Node in root.get_children(true):
		if child is HScrollBar or child is VScrollBar:
			child.hide()
		_hide_scrollbars_in(child)


## --- Paletten sürükle-bırak -------------------------------------------------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("block_type")


func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Ekran pikselini graf koordinatına çevir.
	add_requested.emit(data["block_type"], (scroll_offset + at_position) / zoom)


## --- Niyetler (yukarı) ------------------------------------------------------

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var src: FlowBlock = _block_by_name(from_node)
	var dst: FlowBlock = _block_by_name(to_node)
	if src == null or dst == null:
		return
	connect_requested.emit(src.sim_id, from_port, dst.sim_id, to_port)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var src: FlowBlock = _block_by_name(from_node)
	var dst: FlowBlock = _block_by_name(to_node)
	if src == null or dst == null:
		return
	disconnect_requested.emit(src.sim_id, from_port, dst.sim_id, to_port)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var ids: Array[int] = []
	for node_name: StringName in nodes:
		var block: FlowBlock = _block_by_name(node_name)
		if block != null:
			ids.append(block.sim_id)
	if not ids.is_empty():
		delete_requested.emit(ids)


## --- Komutlar (aşağı) -------------------------------------------------------

## Simülasyonda zaten yaratılmış bir istasyonun görüntüsünü oluşturur.
func spawn_block(sim_id: int, type: BlockType, at: Vector2) -> FlowBlock:
	var block := preload("res://features/flow_canvas/flow_block.tscn").instantiate() as FlowBlock
	block.setup(type)
	block.sim_id = sim_id
	block.name = "n%d" % _next_node_index
	_next_node_index += 1
	block.position_offset = at
	block.action_requested.connect(func(blk: FlowBlock, action: StringName) -> void: action_requested.emit(blk, action))
	add_child(block)
	_by_sim_id[sim_id] = block
	return block


func spawn_complex(complex_id: int, display_name: String, machine_count: int, at: Vector2) -> FlowComplexNode:
	var node := FlowComplexNode.new()
	node.setup(complex_id, display_name, machine_count)
	node.position_offset = at
	node.open_requested.connect(func(id: int) -> void: complex_open_requested.emit(id))
	add_child(node)
	_complex_by_id[complex_id] = node
	return node


func apply_connection(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	var src: FlowBlock = _by_sim_id.get(from_sim)
	var dst: FlowBlock = _by_sim_id.get(to_sim)
	if src == null or dst == null:
		return
	connect_node(src.name, from_port, dst.name, to_port)


func remove_connection(from_sim: int, from_port: int, to_sim: int, to_port: int) -> void:
	var src: FlowBlock = _by_sim_id.get(from_sim)
	var dst: FlowBlock = _by_sim_id.get(to_sim)
	if src == null or dst == null:
		return
	disconnect_node(src.name, from_port, dst.name, to_port)


func remove_block(sim_id: int) -> void:
	var block: FlowBlock = _by_sim_id.get(sim_id)
	if block == null:
		return
	_drop_connections_for(block.name)
	if block == _selected:
		_selected = null
		selection_cleared.emit()
	_by_sim_id.erase(sim_id)
	remove_child(block)
	block.queue_free()


func clear_all() -> void:
	clear_connections()
	for child: Node in get_children():
		if child is not FlowBlock and child is not FlowComplexNode:
			continue
		# queue_free ertelenir ve düğüm adı bir süre daha dolu kalır; ağaçtan
		# hemen çıkarmazsak sonra eklenen aynı adlı bloklar yeniden adlandırılır.
		remove_child(child)
		child.queue_free()
	_by_sim_id.clear()
	_complex_by_id.clear()
	_selected = null
	_next_node_index = 1
	selection_cleared.emit()


## --- Sorgular ---------------------------------------------------------------

func get_blocks() -> Array[FlowBlock]:
	var out: Array[FlowBlock] = []
	for child in get_children():
		if child is FlowBlock:
			out.append(child)
	return out


func get_block(sim_id: int) -> FlowBlock:
	return _by_sim_id.get(sim_id)


func selected_block() -> FlowBlock:
	return _selected if is_instance_valid(_selected) else null


func selected_sim_ids() -> Array[int]:
	var ids: Array[int] = []
	for block: FlowBlock in get_blocks():
		if block.selected:
			ids.append(block.sim_id)
	return ids


func viewport_center() -> Vector2:
	return (scroll_offset + size * 0.5) / zoom


## Bir istasyonu seçer ve görünüme ortalar. Araştırma takip panelindeki
## "Hatta bul" düğmesinin çağırdığı tek giriş noktası — kaydırma matematiği
## `viewport_center()`'ın tersi, burada tek yerde yaşar.
func focus_on(sim_id: int) -> bool:
	var block: FlowBlock = _by_sim_id.get(sim_id)
	if block == null:
		return false
	if is_instance_valid(_selected) and _selected != block:
		_selected.selected = false
	block.selected = true
	_selected = block
	block_selected.emit(block)
	scroll_offset = block.position_offset * zoom - size * 0.5 + block.size * 0.5 * zoom
	return true


## --- İç işler ---------------------------------------------------------------

func _block_by_name(node_name: StringName) -> FlowBlock:
	var node := get_node_or_null(NodePath(node_name))
	return node if node is FlowBlock else null


## GraphEdit, bir düğüm silinince bağlantıları kendiliğinden temizlemez.
func _drop_connections_for(node_name: StringName) -> void:
	for conn: Dictionary in get_connection_list():
		if StringName(conn["from_node"]) == node_name or StringName(conn["to_node"]) == node_name:
			disconnect_node(
				StringName(conn["from_node"]), int(conn["from_port"]),
				StringName(conn["to_node"]), int(conn["to_port"])
			)


func _on_node_selected(node: Node) -> void:
	if node is FlowBlock:
		_selected = node
		block_selected.emit(node)


func _on_node_deselected(node: Node) -> void:
	if node == _selected:
		_selected = null
		selection_cleared.emit()
