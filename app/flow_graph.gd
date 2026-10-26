extends GraphEdit
## Production graph with orthogonal (step) connection lines instead of bezier curves.
## The links are drawn by LinkLayer as 16 px pixel-art bands; GraphEdit's own lines are hidden.
## Routes go around the cards and never lie on top of each other (LinkRouter). They are kept
## in canvas px, so zooming and scrolling only redraw them, and a moved card reroutes only
## its own links and the ones whose line it now covers or used to cover.

## Horizontal run out of an output port / into an input port before the first bend.
const STUB := 20.0
## Link bands from the outer edge to the center line, 1 px each; mirrored for 16 px total.
const LINK_BANDS: Array[Color] = [Color("0e0c0a"), Color("1e2225"), Color("787b80"), Color("3d3f45"),
	Color("52524f"), Color("645e59"), Color("716c61"), Color("716b60")]
const LINE_WIDTH := 16.0
## Cross ticks over the link: TICK px wide, one every TICK_STEP px along its length.
const TICK := 2.0
## Ticks cross only the center bands (from this band inward), each pixel a step darker
## than the band it covers.
const TICK_FIRST_BAND := 4
const TICK_DARKEN := 0.2
const TICK_STEP := 20.0
## Products on the way are drawn ITEM_SIZE px square, on the 8 px center of the line.
const ITEM_SIZE := 8.0
## Room left between a line's edge and a card it passes, in px.
const CARD_CLEARANCE := 4.0
## A link is routed inside the box around its ends grown by these margins, tried in turn
## until a route fits; only the cards in that box count.
const REGION_MARGINS: Array[float] = [80.0, 320.0, 1280.0]
## Cards are looked up in square buckets of this many canvas px.
const BUCKET := 256.0
const LinkRouter = preload("res://app/link_router.gd")

## Products on the way, given by the owner: (from, from_port, to, to_port) ->
## [8 px icon, item distances from the source, link length], both in canvas px; [] for none.
var link_items: Callable
## Goes up whenever a route changes, so the owner knows when to read the lengths again.
var route_version := 0
## How many links the last update rerouted (for measuring).
var last_rerouted := 0
var _drag_node := StringName()
var _drag_port := -1
var _drag_output := true
## link key -> {key, from_end, to_end, conn, points (canvas px), box, group}
var _routes := {}
## Route keys in drawing order.
var _order: Array = []
## card name -> [instance id, wall rect in canvas px]
var _cards := {}
## bucket cell -> {card name: true} / {route key: true} for walls / route boxes touching it
var _buckets := {}
var _route_buckets := {}
## The link list as last taken apart: its hash, link key -> connection, card -> link keys.
var _conns_hash := 0
var _links := {}
var _card_links := {}
var _router := LinkRouter.new()
var _routed_frame := -1
## The bounded map in canvas px (empty: no bounds) and its ore deposits, drawn under the links:
## [{"rect": Rect2, "color": Color, "icon": Texture2D, "name": String, "art": Texture2D}, ...]
var map_rect := Rect2():
	set(value):
		map_rect = value
		_place_map_corners()
var deposit_areas: Array = []
## GraphEdit only scrolls as far as its elements reach, so two invisible ones sit in the map's
## corners to let the view travel the whole map.
var _map_corners: Array[GraphElement] = []
## The river as quads along its center line, in canvas px: water edges (left, right), the
## outer bank edges, and the distance along the river at each point.
var _river_water_left := PackedVector2Array()
var _river_water_right := PackedVector2Array()
var _river_bank_left := PackedVector2Array()
var _river_bank_right := PackedVector2Array()
var _river_along := PackedFloat32Array()
var _river_half := PackedFloat32Array()
var _river_water: Texture2D = preload("res://app/art/map/river_water.png")
var _river_sand: Texture2D = preload("res://app/art/map/river_sand.png")
## Water drifts down the river at this many canvas px per second.
const RIVER_FLOW := 24.0
const RIVER_EDGE := Color("3f5f63")
const RIVER_BANK_EDGE := Color("b9a77f")
## Trees and bushes: [[texture, top-left corner in canvas px], ...], sorted by their foot so
## the nearer one covers the farther.
var decor: Array = []
const MAP_OUTSIDE := Color("cfc6b4")
const MAP_EDGE := Color("8a7f6a")

func _ready() -> void:
	# GraphEdit's own lines are hidden: the link layer and the drag preview Line2D on its top layer.
	for child in get_children(true):
		if child.name == &"_connection_layer":
			(child as CanvasItem).visible = false
		for line in child.get_children(true):
			if line is Line2D:
				(line as Line2D).self_modulate = Color.TRANSPARENT
	connection_drag_started.connect(func(node: StringName, port: int, is_output: bool) -> void:
		_drag_node = node
		_drag_port = port
		_drag_output = is_output)
	connection_drag_ended.connect(func() -> void: _drag_node = StringName())
	# Internal front: above the grid, below the cards; the map under the links.
	add_child(MapLayer.new(), false, Node.INTERNAL_MODE_FRONT)
	add_child(LinkLayer.new(), false, Node.INTERNAL_MODE_FRONT)

func _place_map_corners() -> void:
	if _map_corners.is_empty():
		for i in range(2):
			var corner := GraphElement.new()
			corner.name = "MapCorner%d" % i
			corner.selectable = false
			corner.draggable = false
			corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			corner.custom_minimum_size = Vector2.ONE
			corner.size = Vector2.ONE
			corner.self_modulate = Color.TRANSPARENT
			add_child(corner)
			_map_corners.append(corner)
	_map_corners[0].position_offset = map_rect.position
	_map_corners[1].position_offset = map_rect.end - Vector2.ONE

## Takes the river's center line ([x, y, water half width, left bank, right bank] per point)
## and works out its edges once; drawing only moves them to the screen.
func set_river(points: Array) -> void:
	for array in [_river_water_left, _river_water_right, _river_bank_left, _river_bank_right]:
		array.clear()
	_river_along.clear()
	_river_half.clear()
	var along := 0.0
	for i in range(points.size()):
		var here := Vector2(points[i][0], points[i][1])
		var ahead := Vector2(points[mini(i + 1, points.size() - 1)][0], points[mini(i + 1, points.size() - 1)][1])
		var behind := Vector2(points[maxi(i - 1, 0)][0], points[maxi(i - 1, 0)][1])
		var normal := (ahead - behind).orthogonal().normalized()
		if i > 0:
			along += here.distance_to(behind)
		var half := float(points[i][2])
		_river_water_left.append(here + normal * half)
		_river_water_right.append(here - normal * half)
		_river_bank_left.append(here + normal * (half + float(points[i][3])))
		_river_bank_right.append(here - normal * (half + float(points[i][4])))
		_river_along.append(along)
		_river_half.append(half)

## Keeps the middle of the view inside the map.
func keep_in_map() -> void:
	if map_rect.size == Vector2.ZERO:
		return
	var held := scroll_offset.clamp(map_rect.position * zoom - size * 0.5, map_rect.end * zoom - size * 0.5)
	if held != scroll_offset:
		scroll_offset = held

func _get_connection_line(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	return _step_route(from_position, to_position, STUB * zoom)

## The plain route without avoiding anything: out, one vertical step, in; a backward link
## leaves right, crosses over at mid height and enters from the left.
static func _step_route(a: Vector2, b: Vector2, stub: float) -> PackedVector2Array:
	if b.x - a.x >= stub * 2.0:
		var mid_x := roundf((a.x + b.x) * 0.5)
		return PackedVector2Array([a, Vector2(mid_x, a.y), Vector2(mid_x, b.y), b])
	var mid_y := roundf((a.y + b.y) * 0.5)
	return PackedVector2Array([a, Vector2(a.x + stub, a.y), Vector2(a.x + stub, mid_y),
		Vector2(b.x - stub, mid_y), Vector2(b.x - stub, b.y), b])

## Screen position of a card's port, or null when the card is gone.
func _port(node: StringName, port: int, output: bool) -> Variant:
	var card := get_node_or_null(NodePath(String(node))) as GraphNode
	if card == null:
		return null
	var local := card.get_output_port_position(port) if output else card.get_input_port_position(port)
	return card.position + local * zoom

## Canvas position of a card's port, or null when the card is gone.
func _canvas_port(node: StringName, port: int, output: bool) -> Variant:
	var card := get_node_or_null(NodePath(String(node))) as GraphNode
	if card == null:
		return null
	return card.position_offset + (card.get_output_port_position(port) if output else card.get_input_port_position(port))

## Length of the link's route in canvas px, or 0 when it has none.
func route_length(from: StringName, from_port: int, to: StringName, to_port: int) -> float:
	_update_routes()
	var route: Dictionary = _routes.get(_key(from, from_port, to, to_port), {})
	return _length(route.points) if not route.is_empty() else 0.0

static func _key(from: StringName, from_port: int, to: StringName, to_port: int) -> String:
	return "%s|%d>%s|%d" % [from, from_port, to, to_port]

static func _length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

## Brings the routes up to date, once per frame. Reroutes new links, links of cards that
## moved, came or went (or were rebuilt), and links whose line a moved card covers now or
## covered before; the other routes stay as they are.
func _update_routes() -> void:
	var frame := Engine.get_process_frames()
	if frame == _routed_frame:
		return
	_routed_frame = frame
	var moved: Array[Rect2] = []
	var moved_cards := {}
	var seen := {}
	for child in get_children():
		if not (child is GraphNode and child.visible):
			continue
		var name := String(child.name)
		seen[name] = true
		var wall := Rect2(child.position_offset, child.size).grow(LINE_WIDTH * 0.5 + CARD_CLEARANCE)
		var known: Array = _cards.get(name, [])
		if known.is_empty() or known[0] != child.get_instance_id() or known[1] != wall:
			if not known.is_empty():
				moved.append(known[1])
				_unfile(_buckets, known[1], name)
			moved.append(wall)
			moved_cards[name] = true
			_cards[name] = [child.get_instance_id(), wall]
			_file(_buckets, wall, name)
	if seen.size() != _cards.size():
		for name in _cards.keys():
			if not seen.has(name):
				moved.append(_cards[name][1])
				moved_cards[name] = true
				_unfile(_buckets, _cards[name][1], name)
				_cards.erase(name)
	var dirty := {}
	# The link list is read every frame but only taken apart when it changed.
	var conns := get_connection_list()
	var links_changed := conns.hash() != _conns_hash
	if links_changed:
		_conns_hash = conns.hash()
		_links.clear()
		_card_links.clear()
		for conn in conns:
			var key := _key(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
			_links[key] = conn
			for card in [String(conn.from_node), String(conn.to_node)]:
				if not _card_links.has(card):
					_card_links[card] = []
				_card_links[card].append(key)
			if not _routes.has(key):
				dirty[key] = true
		for key in _routes.keys():
			if not _links.has(key):
				_drop_route(key)
	for name in moved_cards:
		for key in _card_links.get(name, []):
			dirty[key] = true
	# Lines a moved card now covers or used to cover.
	for wall in moved:
		for cell in _cells(wall):
			for key in _route_buckets.get(cell, {}):
				if not dirty.has(key) and wall.intersects(_routes[key].box) and _crosses(_routes[key].points, wall):
					dirty[key] = true
	if dirty.is_empty() and not links_changed:
		return
	var keys := dirty.keys()
	keys.sort()
	last_rerouted = keys.size()
	# Free the old lines first, then route one by one; each avoids the ones placed before it.
	var groups := {}
	for key in keys:
		groups[key] = _routes.get(key, {}).get("group", key)
		_drop_route(key)
	for key in keys:
		var conn: Dictionary = _links[key]
		var a: Variant = _canvas_port(conn.from_node, conn.from_port, true)
		var b: Variant = _canvas_port(conn.to_node, conn.to_port, false)
		if a == null or b == null:
			continue
		var route := {"key": key, "conn": conn, "group": groups[key],
			"from_end": "%s|%d" % [conn.from_node, conn.from_port],
			"to_end": "%s|%d" % [conn.to_node, conn.to_port]}
		route.points = _route_one(route, a, b)
		var box := Rect2(route.points[0], Vector2.ZERO)
		for p in route.points:
			box = box.expand(p)
		route.box = box.grow(LINE_WIDTH)
		_routes[key] = route
		_file(_route_buckets, route.box, key)
	if links_changed:
		_regroup()
	route_version += 1

func _drop_route(key: String) -> void:
	if _routes.has(key):
		_unfile(_route_buckets, _routes[key].box, key)
		_routes.erase(key)

## Buckets: cell -> {name: true} for everything whose box touches the cell.
static func _file(buckets: Dictionary, box: Rect2, name: String) -> void:
	for cell in _cells(box):
		if not buckets.has(cell):
			buckets[cell] = {}
		buckets[cell][name] = true

static func _unfile(buckets: Dictionary, box: Rect2, name: String) -> void:
	for cell in _cells(box):
		if buckets.has(cell):
			buckets[cell].erase(name)

## Drops every route and cache, so the next update routes everything from scratch.
func forget_routes() -> void:
	_routes.clear()
	_order.clear()
	_cards.clear()
	_buckets.clear()
	_route_buckets.clear()
	_links.clear()
	_card_links.clear()
	_conns_hash = 0
	_routed_frame = -1

## Whether a route's line runs through a card wall; running along its edge does not count.
static func _crosses(points: PackedVector2Array, wall: Rect2) -> bool:
	var inside := wall.grow(-0.5)
	for i in range(points.size() - 1):
		if inside.intersects(Rect2(points[i], Vector2.ZERO).expand(points[i + 1]), true):
			return true
	return false

static func _cells(box: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(floori(box.position.y / BUCKET), floori(box.end.y / BUCKET) + 1):
		for x in range(floori(box.position.x / BUCKET), floori(box.end.x / BUCKET) + 1):
			cells.append(Vector2i(x, y))
	return cells

func _route_one(route: Dictionary, a: Vector2, b: Vector2) -> PackedVector2Array:
	var ends := Rect2(a, Vector2.ZERO).expand(b).expand(a + Vector2(STUB, 0)).expand(b - Vector2(STUB, 0))
	for margin in REGION_MARGINS:
		var region := ends.grow(margin)
		var walls: Array[Rect2] = []
		var met := {}
		for cell in _cells(region):
			for name in _buckets.get(cell, []):
				if not met.has(name):
					met[name] = true
					var wall: Rect2 = _cards[name][1]
					if wall.intersects(region):
						walls.append(wall)
		# Lines of other links in the region; links sharing a port may share runs.
		var runs: Array = []
		met.clear()
		for cell in _cells(region):
			for key in _route_buckets.get(cell, {}):
				if met.has(key):
					continue
				met[key] = true
				var other: Dictionary = _routes[key]
				if other.from_end == route.from_end or other.to_end == route.to_end or not other.box.intersects(region):
					continue
				for i in range(other.points.size() - 1):
					runs.append([other.points[i], other.points[i + 1]])
		var points := _router.route(a, b, walls, runs, region, LINE_WIDTH, STUB)
		if not points.is_empty():
			return points
	# No way around (a card covers the port): the plain route.
	return _step_route(a, b, STUB)

## Links that share an output or an input port form one group, drawn as one merged belt.
func _regroup() -> void:
	_order = _routes.keys()
	_order.sort()
	var parent := {}
	var owner_of := {}
	for key in _order:
		parent[key] = key
		for end in [_routes[key].from_end, "in:" + _routes[key].to_end]:
			if owner_of.has(end):
				parent[_root(parent, key)] = _root(parent, owner_of[end])
			else:
				owner_of[end] = key
	for key in _order:
		_routes[key].group = _root(parent, key)

static func _root(parent: Dictionary, key: String) -> String:
	while parent[key] != key:
		key = parent[key]
	return key

## Visible routes on screen, grouped for drawing: [[group, [points...], [cargo...]], ...];
## the drag preview last. Cargo entries are [points, icon, item distances, link length].
func _visible_groups() -> Array:
	_update_routes()
	var view := Rect2(scroll_offset / zoom, size / zoom).grow(LINE_WIDTH)
	var by_group := {}
	var order: Array = []
	for key in _order:
		var route: Dictionary = _routes.get(key, {})
		if route.is_empty() or not route.box.intersects(view):
			continue
		if not by_group.has(route.group):
			var fresh: Array[PackedVector2Array] = []
			by_group[route.group] = [route.group, fresh, []]
			order.append(route.group)
		var points := PackedVector2Array()
		for p in route.points:
			points.append(p * zoom - scroll_offset)
		by_group[route.group][1].append(points)
		if link_items.is_valid():
			var conn: Dictionary = route.conn
			var info: Array = link_items.call(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
			if not info.is_empty() and not info[1].is_empty() and int(info[2]) > 0:
				by_group[route.group][2].append([points, info[0], info[1], info[2]])
	var groups: Array = []
	for group in order:
		groups.append(by_group[group])
	if _drag_node != StringName():
		var end: Variant = _port(_drag_node, _drag_port, _drag_output)
		if end != null:
			var mouse := get_local_mouse_position()
			var line := _get_connection_line(end, mouse) if _drag_output else _get_connection_line(mouse, end)
			var preview: Array[PackedVector2Array] = [line]
			groups.append(["", preview, []])
	return groups

## The area outside the map dimmed, its edge, the deposits as mountains with their ore's
## tag, and the trees and bushes.
class MapLayer extends Control:
	var _flow := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		_flow += delta * RIVER_FLOW
		queue_redraw()

	## Sand on both banks (textured in canvas space), the water textured along the river and
	## drifting with it, and dark lines along the water's edges.
	func _draw_river(graph: GraphEdit, view: Rect2) -> void:
		var count: int = graph._river_along.size()
		if count < 2:
			return
		var zoom: float = graph.zoom
		var shift: Vector2 = graph.scroll_offset
		var water_size: Vector2 = graph._river_water.get_size()
		var sand_size: Vector2 = graph._river_sand.get_size()
		var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		var edge_width := maxf(1.0, 2.0 * zoom)
		# All edges to the screen at once; the sand keeps its canvas positions for its texture.
		var to_screen := Transform2D(0.0, Vector2(zoom, zoom), 0.0, -shift)
		var water_left: PackedVector2Array = to_screen * graph._river_water_left
		var water_right: PackedVector2Array = to_screen * graph._river_water_right
		var bank_left: PackedVector2Array = to_screen * graph._river_bank_left
		var bank_right: PackedVector2Array = to_screen * graph._river_bank_right
		var visible := PackedInt32Array()
		for i in range(count - 1):
			var box := Rect2(bank_left[i], Vector2.ZERO).expand(bank_left[i + 1]).expand(bank_right[i]).expand(bank_right[i + 1])
			if box.intersects(view):
				visible.append(i)
		# One pass per texture so the quads batch: both banks, then the water, then the edges.
		var sand_uv: PackedVector2Array
		for i in visible:
			sand_uv = PackedVector2Array([graph._river_bank_left[i], graph._river_bank_left[i + 1],
				graph._river_water_left[i + 1], graph._river_water_left[i]])
			draw_primitive(PackedVector2Array([bank_left[i], bank_left[i + 1], water_left[i + 1], water_left[i]]), white,
				Transform2D.IDENTITY.scaled(Vector2.ONE / sand_size) * sand_uv, graph._river_sand)
			sand_uv = PackedVector2Array([graph._river_water_right[i], graph._river_water_right[i + 1],
				graph._river_bank_right[i + 1], graph._river_bank_right[i]])
			draw_primitive(PackedVector2Array([water_right[i], water_right[i + 1], bank_right[i + 1], bank_right[i]]), white,
				Transform2D.IDENTITY.scaled(Vector2.ONE / sand_size) * sand_uv, graph._river_sand)
		for i in visible:
			var u1: float = (graph._river_along[i] - _flow) / water_size.x
			var u2: float = (graph._river_along[i + 1] - _flow) / water_size.x
			draw_primitive(PackedVector2Array([water_left[i], water_left[i + 1], water_right[i + 1], water_right[i]]), white,
				PackedVector2Array([Vector2(u1, 0), Vector2(u2, 0), Vector2(u2, graph._river_half[i + 1] * 2.0 / water_size.y),
					Vector2(u1, graph._river_half[i] * 2.0 / water_size.y)]), graph._river_water)
		for edge in [[water_left, RIVER_EDGE], [water_right, RIVER_EDGE], [bank_left, RIVER_BANK_EDGE], [bank_right, RIVER_BANK_EDGE]]:
			var points: PackedVector2Array = edge[0]
			var line := PackedVector2Array()
			for k in range(visible.size()):
				var i: int = visible[k]
				if not line.is_empty() and visible[k - 1] != i - 1:
					draw_polyline(line, edge[1], edge_width)
					line.clear()
				if line.is_empty():
					line.append(points[i])
				line.append(points[i + 1])
			if line.size() > 1:
				draw_polyline(line, edge[1], edge_width)

	func _draw() -> void:
		var graph := get_parent() as GraphEdit
		if graph.map_rect.size == Vector2.ZERO:
			return
		var zoom: float = graph.zoom
		var view := Rect2(Vector2.ZERO, size)
		_draw_river(graph, view)
		var map := Rect2(graph.map_rect.position * zoom - graph.scroll_offset, graph.map_rect.size * zoom)
		# Four bands around the map (top, bottom, left, right) as [x0, y0, x1, y1], cut to the view.
		for band in [[0.0, 0.0, size.x, map.position.y], [0.0, map.end.y, size.x, size.y],
				[0.0, map.position.y, map.position.x, map.end.y], [map.end.x, map.position.y, size.x, map.end.y]]:
			var top_left := Vector2(maxf(band[0], 0.0), maxf(band[1], 0.0))
			var bottom_right := Vector2(minf(band[2], size.x), minf(band[3], size.y))
			if bottom_right.x > top_left.x and bottom_right.y > top_left.y:
				draw_rect(Rect2(top_left, bottom_right - top_left), MAP_OUTSIDE)
		draw_rect(map, MAP_EDGE, false, 3.0)
		var font := get_theme_default_font()
		for area in graph.deposit_areas:
			# The deposit is a mountain centered on the mine's spot, its ore named on a tag below.
			var art: Texture2D = area.art
			var center: Vector2 = area.rect.get_center() * zoom - graph.scroll_offset
			var mountain := Rect2(center - art.get_size() * zoom * 0.5, art.get_size() * zoom)
			# The tag keeps a readable size when zoomed far out, where it is what the player looks for.
			var k := maxf(zoom, 0.35)
			var tag := Rect2(Vector2(center.x - 110.0 * k, mountain.end.y + 8.0 * k), Vector2(220, 44) * k)
			if not mountain.merge(tag).intersects(view):
				continue
			draw_texture_rect(art, mountain, false)
			var tint: Color = area.color
			draw_rect(tag, Color(tint, 0.9))
			draw_rect(tag, tint.darkened(0.45), false, maxf(1.0, 3.0 * k))
			var icon := Rect2(tag.position + Vector2(6, 6) * k, Vector2(32, 32) * k)
			draw_texture_rect(area.icon, icon, false)
			if zoom >= 0.4:
				draw_string(font, Vector2(icon.end.x + 8.0 * k, tag.position.y + 29.0 * k), area.name,
					HORIZONTAL_ALIGNMENT_LEFT, -1, int(17.0 * k), tint.darkened(0.7))
		for item in graph.decor:
			var texture: Texture2D = item[0]
			var r := Rect2(item[1] * zoom - graph.scroll_offset, texture.get_size() * zoom)
			if r.intersects(view):
				draw_texture_rect(texture, r, false)

class LinkLayer extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var graph := get_parent() as GraphEdit
		# Group by group, each one whole: a later group crosses over the earlier ones like a
		# bridge, its outline drawn over them. Inside a group the belts merge.
		for entry in graph._visible_groups():
			var links: Array[PackedVector2Array] = entry[1]
			_draw_belts(graph, links)
			_draw_ticks(graph, links)
			_draw_items(graph, entry[2])

	## Band by band across the group's links, so its T-junctions merge cleanly.
	func _draw_belts(graph: GraphEdit, links: Array[PackedVector2Array]) -> void:
		for band in LINK_BANDS.size():
			var half := maxf(roundf((LINK_BANDS.size() - band) * graph.zoom), 1.0)
			for points in links:
				for i in range(points.size() - 1):
					var span := Rect2(points[i].round(), Vector2.ZERO).expand(points[i + 1].round())
					draw_rect(span.grow(half), LINK_BANDS[band])

	func _draw_ticks(graph: GraphEdit, links: Array[PackedVector2Array]) -> void:
		var outer := maxf(roundf((LINK_BANDS.size() - TICK_FIRST_BAND) * graph.zoom), 1.0)
		var tick := maxf(roundf(TICK * graph.zoom), 1.0)
		var step := TICK_STEP * graph.zoom
		for points in links:
			# Distance walked along the whole link, so the spacing carries over the bends.
			var walked := 0.0
			for i in range(points.size() - 1):
				var a := points[i].round()
				var b := points[i + 1].round()
				var length := a.distance_to(b)
				var along := (b - a) / maxf(length, 1.0)
				var across := Vector2(absf(along.y), absf(along.x))
				var d := ceilf(walked / step) * step - walked
				# No ticks in a bend's square: keep clear of corners by the link's half width.
				var clear := outer + tick
				var lo := clear if i > 0 else 0.0
				var hi := length - clear if i + 2 < points.size() else length
				while d <= length and length > 0.0:
					if walked + d > 0.0 and d >= lo and d <= hi:
						var at := (a + along * d).round()
						var lead := Vector2(absf(along.x), absf(along.y)) * tick
						for band in range(TICK_FIRST_BAND, LINK_BANDS.size()):
							var reach := maxf(roundf((LINK_BANDS.size() - band) * graph.zoom), 1.0)
							draw_rect(Rect2(at - across * reach - lead * 0.5, across * reach * 2.0 + lead),
								LINK_BANDS[band].darkened(TICK_DARKEN))
					d += step
				walked += length

	## Products ride on the center of the line, placed by their share of the route.
	func _draw_items(graph: GraphEdit, cargo: Array) -> void:
		var size := maxf(roundf(ITEM_SIZE * graph.zoom), 1.0)
		for entry in cargo:
			var points: PackedVector2Array = entry[0]
			var total: float = graph._length(points)
			for at in entry[2]:
				var spot := _along(points, total * float(at) / float(entry[3]))
				draw_texture_rect(entry[1], Rect2((spot - Vector2.ONE * size * 0.5).round(), Vector2.ONE * size), false)

	## The point `distance` px along the route.
	func _along(points: PackedVector2Array, distance: float) -> Vector2:
		for i in range(points.size() - 1):
			var span := points[i].distance_to(points[i + 1])
			if distance <= span:
				return points[i].move_toward(points[i + 1], distance)
			distance -= span
		return points[points.size() - 1]
