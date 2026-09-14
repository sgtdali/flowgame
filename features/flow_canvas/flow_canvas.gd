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

## Kullanıcı niyetleri (yukarı).
signal add_requested(type: BlockType, at: Vector2)
signal connect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int)
signal disconnect_requested(from_sim: int, from_port: int, to_sim: int, to_port: int)
signal delete_requested(sim_ids: Array[int])
signal block_selected(block: FlowBlock)
signal selection_cleared

var _selected: FlowBlock = null
var _by_sim_id: Dictionary = {}   # sim_id -> FlowBlock
var _next_node_index: int = 1


func _ready() -> void:
	right_disconnects = true
	show_grid = true
	snapping_enabled = true
	snapping_distance = 20
	minimap_enabled = true
	minimap_size = Vector2(180.0, 120.0)
	minimap_opacity = 0.6
	add_theme_color_override(&"grid_major", Color(0.37, 0.29, 0.19, 0.56))
	add_theme_color_override(&"grid_minor", Color(0.26, 0.21, 0.15, 0.42))
	connection_lines_curvature = 0.45
	connection_lines_thickness = 2.5
	connection_lines_antialiased = true
	zoom_min = 0.35
	zoom_max = 2.0

	add_valid_connection_type(PORT_TYPE_MATERIAL, PORT_TYPE_MATERIAL)

	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)


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
	var block := FlowBlock.new()
	block.setup(type)
	block.sim_id = sim_id
	block.name = "n%d" % _next_node_index
	_next_node_index += 1
	block.position_offset = at
	add_child(block)
	_by_sim_id[sim_id] = block
	return block


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
	for block: FlowBlock in get_blocks():
		# queue_free ertelenir ve düğüm adı bir süre daha dolu kalır; ağaçtan
		# hemen çıkarmazsak sonra eklenen aynı adlı bloklar yeniden adlandırılır.
		remove_child(block)
		block.queue_free()
	_by_sim_id.clear()
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


func viewport_center() -> Vector2:
	return (scroll_offset + size * 0.5) / zoom


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
