class_name FlowCanvas
extends GraphEdit

## Üretim akışının çizildiği tuval.
##
## MİMARİ: Bu bir mantık bileşenidir. Palet, denetçi veya üst bardan HABERİ
## YOKTUR. Olan biteni YUKARI sinyalle bildirir; ne yapacağı ise editör
## (orkestratör) tarafından AŞAĞI doğru metot çağrısıyla söylenir.

## Kaydedilen dosyanın biçim sürümü. Eski kayıtlar bozulmasın diye taşınır.
const FORMAT_VERSION: int = 1

signal block_selected(block: FlowBlock)
signal selection_cleared
## Akış her değiştiğinde (ekleme/silme/bağlama/parametre) yayılır.
signal graph_changed
## Kullanıcıya gösterilecek kısa bilgi/uyarı metni.
signal notice(text: String)

var _selected: FlowBlock = null
var _next_index: int = 1


func _ready() -> void:
	right_disconnects = true
	show_grid = true
	snapping_enabled = true
	snapping_distance = 20
	minimap_enabled = true
	minimap_size = Vector2(180.0, 120.0)
	minimap_opacity = 0.6
	connection_lines_curvature = 0.45
	connection_lines_thickness = 2.5
	connection_lines_antialiased = true
	zoom_min = 0.35
	zoom_max = 2.0

	# Yalnızca malzeme portları birbirine bağlanabilir.
	add_valid_connection_type(FlowBlock.PORT_TYPE_MATERIAL, FlowBlock.PORT_TYPE_MATERIAL)

	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)


## --- Editörün çağırdığı komutlar (call down) --------------------------------

## Tuvale yeni bir istasyon ekler. Konum verilmezse görünür alanın ortasına düşer.
func add_block(type: BlockType, at: Variant = null) -> FlowBlock:
	var block := FlowBlock.new()
	block.setup(type)
	block.name = "blk%d" % _next_index
	_next_index += 1

	block.position_offset = _viewport_center() if at == null else (at as Vector2)
	add_child(block)
	block.params_changed.connect(_on_block_params_changed)

	graph_changed.emit()
	return block


## Seçili istasyonun bir parametresini değiştirir. Denetçi paneli bloğa asla
## doğrudan dokunmaz — istek buradan geçer.
func set_selected_param(key: StringName, value: Variant) -> void:
	if not is_instance_valid(_selected):
		return
	_selected.set_param(key, value)


func clear_graph() -> void:
	clear_connections()
	for block: FlowBlock in get_blocks():
		# queue_free() ertelenir ve düğüm adı bir süre daha "dolu" kalır.
		# Ağaçtan hemen çıkarmazsak, ardından eklenen aynı adlı bloklar
		# Godot tarafından yeniden adlandırılır.
		remove_child(block)
		block.queue_free()
	_selected = null
	_next_index = 1
	selection_cleared.emit()
	graph_changed.emit()


func get_blocks() -> Array[FlowBlock]:
	var out: Array[FlowBlock] = []
	for child in get_children():
		if child is FlowBlock:
			out.append(child)
	return out


## --- Paletten sürükle-bırak -------------------------------------------------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("block_type")


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var type: BlockType = data["block_type"]
	# Ekran pikselini graf koordinatına çevir.
	add_block(type, (scroll_offset + at_position) / zoom)


## --- Bağlantı kuralları -----------------------------------------------------

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		notice.emit("Bir istasyon kendine bağlanamaz.")
		return
	if is_node_connected(from_node, from_port, to_node, to_port):
		notice.emit("Bu bağlantı zaten var.")
		return

	connect_node(from_node, from_port, to_node, to_port)

	if _creates_cycle(from_node, to_node):
		notice.emit("Geri besleme (rework) döngüsü oluştu — bilgi amaçlı.")
	graph_changed.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)
	graph_changed.emit()


## Hedef düğümden başlayıp kaynağa geri dönülebiliyorsa döngü vardır.
func _creates_cycle(from_node: StringName, to_node: StringName) -> bool:
	var stack: Array[StringName] = [to_node]
	var seen: Dictionary = {}
	while not stack.is_empty():
		var current: StringName = stack.pop_back()
		if current == from_node:
			return true
		if seen.has(current):
			continue
		seen[current] = true
		for conn: Dictionary in get_connection_list():
			if StringName(conn["from_node"]) == current:
				stack.append(StringName(conn["to_node"]))
	return false


## --- Silme ve seçim ---------------------------------------------------------

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name: StringName in nodes:
		var node := get_node_or_null(NodePath(node_name))
		if not (node is FlowBlock):
			continue
		_drop_connections_for(node_name)
		if node == _selected:
			_selected = null
			selection_cleared.emit()
		node.queue_free()
	graph_changed.emit()


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


func _on_block_params_changed(_block: FlowBlock) -> void:
	graph_changed.emit()


## --- Özet -------------------------------------------------------------------

## Durum çubuğu için akışın anlık özeti.
##
## Darboğaz şimdilik STATİK bir tahmin: en uzun reçete süresi. Faz 2'den
## sonra gerçek darboğaz simülasyondan gelecek (hangi istasyon fiilen tıkalı),
## çünkü asıl darboğazı belirleyen şey süre değil, hattın dengesizliğidir.
func get_summary() -> Dictionary:
	var blocks: Array[FlowBlock] = get_blocks()
	var worst_name: String = ""
	var worst_ticks: int = 0
	for block: FlowBlock in blocks:
		var recipe: Recipe = block.block_type.recipe
		if recipe == null:
			continue
		if recipe.duration_ticks > worst_ticks:
			worst_ticks = recipe.duration_ticks
			worst_name = block.block_label
	return {
		"blocks": blocks.size(),
		"connections": get_connection_list().size(),
		"bottleneck_name": worst_name,
		"bottleneck_ticks": worst_ticks,
	}


## --- Kayıt / yükleme --------------------------------------------------------

func to_dict() -> Dictionary:
	var block_data: Array = []
	for block: FlowBlock in get_blocks():
		block_data.append(block.to_dict())

	var conn_data: Array = []
	for conn: Dictionary in get_connection_list():
		conn_data.append({
			"from": String(conn["from_node"]),
			"from_port": int(conn["from_port"]),
			"to": String(conn["to_node"]),
			"to_port": int(conn["to_port"]),
		})

	return {"version": FORMAT_VERSION, "blocks": block_data, "connections": conn_data}


## Kayıttan akışı kurar. Başarısızlıkta false döner ve notice yayar.
func from_dict(data: Dictionary) -> bool:
	var version: int = int(data.get("version", 0))
	if version > FORMAT_VERSION:
		notice.emit("Dosya daha yeni bir sürümle kaydedilmiş (v%d)." % version)
		return false

	clear_graph()

	# Kayıttaki ad -> sahnedeki gerçek ad. Godot bir adı kabul etmezse
	# (çakışma, geçersiz karakter) yeniden adlandırır; bağlantıları dosyadaki
	# adlara göre değil, bu tabloya göre kurarız.
	var name_map: Dictionary = {}
	var skipped: int = 0

	for entry: Dictionary in data.get("blocks", []):
		var type := BlockCatalog.find_by_id(StringName(entry.get("type_id", "")))
		if type == null:
			skipped += 1
			continue
		var block := FlowBlock.new()
		block.setup(type)
		block.name = "blk%d" % _next_index
		_next_index += 1
		add_child(block)
		block.params_changed.connect(_on_block_params_changed)
		block.apply_dict(entry)
		name_map[String(entry.get("name", ""))] = block.name

	var lost: int = 0
	for conn: Dictionary in data.get("connections", []):
		var from_name: String = String(conn.get("from", ""))
		var to_name: String = String(conn.get("to", ""))
		if not (name_map.has(from_name) and name_map.has(to_name)):
			lost += 1
			continue
		connect_node(
			name_map[from_name], int(conn.get("from_port", 0)),
			name_map[to_name], int(conn.get("to_port", 0))
		)

	if skipped > 0:
		notice.emit("%d istasyon tanınmayan türde olduğu için atlandı." % skipped)
	elif lost > 0:
		notice.emit("%d bağlantı kurulamadı (istasyonu eksik)." % lost)
	graph_changed.emit()
	return true


func _viewport_center() -> Vector2:
	return (scroll_offset + size * 0.5) / zoom
