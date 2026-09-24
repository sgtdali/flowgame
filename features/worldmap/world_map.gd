extends Node2D

## Harita ekranı: bölgeleri durumlarıyla gösterir, seçimi ve kamerayı yönetir.
##
## Kural hesaplamaz: bölge durumu RegionState'ten gelir. Tıklanan bölge,
## bölgelerin CollisionPolygon2D'lerine fizik sorgusuyla bulunur. Noktaya
## tıklama bölgeye tıklamadan önceliklidir (yarıçap kontrolü). Hat kurma
## akışı RouteBuilder'dadır; burası yalnızca girdiyi ona yönlendirir.

const MIN_ZOOM: float = 0.6
const MAX_ZOOM: float = 3.0
const ZOOM_STEP: float = 1.15
## Kamera haritadan en fazla bu kadar dışarı kayabilir (px).
const PAN_MARGIN: float = 300.0

@onready var camera: Camera2D = $Camera2D
@onready var region_map: Node2D = $RegionMap
@onready var map_bounds: Control = $RegionMap/MapBounds
@onready var info_panel: RegionInfoPanel = $UI/InfoPanel
@onready var point_panel: PointInfoPanel = $UI/PointPanel
@onready var money_label: Label = %MoneyLabel
@onready var hint_label: Label = $UI/TopBar/Margin/HBox/HintLabel
@onready var route_builder: RouteBuilder = $Routes

var state: RegionState = RegionState.new()
var routes: RouteState = RouteState.new(state)
var selected: RegionView = null
var selected_point: MapPoint = null

var _points: Array[MapPoint] = []
var _hovered_point: MapPoint = null

var _panning: bool = false
var _target_zoom: Vector2 = Vector2.ONE
var _default_hint: String = ""


func _ready() -> void:
	# Area2D'lerin fare üzerine gelme sinyalleri için gerekli.
	get_viewport().physics_object_picking = true
	_target_zoom = camera.zoom
	for node: Node in region_map.find_children("*", "MapPoint", true, false):
		_points.append(node as MapPoint)
	info_panel.unlock_requested.connect(_on_unlock_requested)
	point_panel.build_route_requested.connect(_on_build_route_requested)
	route_builder.routes = routes
	route_builder.hint_changed.connect(_on_hint_changed)
	route_builder.route_built.connect(_on_route_built)
	_default_hint = hint_label.text
	refresh_statuses()
	_update_money()


func _process(delta: float) -> void:
	camera.zoom = camera.zoom.lerp(_target_zoom, minf(delta * 12.0, 1.0))


func refresh_statuses() -> void:
	for view: RegionView in _views():
		if view.data != null:
			view.set_status(state.status(view.data.id))
	# Kilitli bölgenin noktaları görünür ama soluk.
	for point: MapPoint in _points:
		var view: RegionView = point.get_region_view()
		point.set_dimmed(view == null or view.data == null or not state.is_unlocked(view.data.id))


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and route_builder.is_building():
		route_builder.cancel()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(ZOOM_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(1.0 / ZOOM_STEP)
		elif button.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_panning = button.pressed
			if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT and route_builder.is_building():
				route_builder.cancel()
		elif button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			var world: Vector2 = _event_to_world(button.position)
			var point: MapPoint = _point_at(world)
			if route_builder.is_building():
				# Hat kurarken: noktaya tıklamak kurar, boşluğa tıklamak iptal eder.
				if point != null:
					route_builder.try_finish(point)
				else:
					route_builder.cancel()
			elif point != null:
				_select_point(point)
			else:
				_select(_region_at(world))
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _panning:
		camera.position -= motion.relative / camera.zoom
		_clamp_camera()
	elif motion != null:
		var world: Vector2 = _event_to_world(motion.position)
		_set_hovered_point(_point_at(world))
		route_builder.update_preview(world, _hovered_point)


## Olayın ekran konumunu dünya koordinatına çevirir (kamera ve yakınlaştırma dahil).
func _event_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _select(view: RegionView) -> void:
	_clear_selection()
	selected = view
	if selected != null:
		selected.set_selected(true)
	_update_panel()


func _select_point(point: MapPoint) -> void:
	_clear_selection()
	selected_point = point
	point.set_selected(true)
	_update_panel()


func _clear_selection() -> void:
	if selected != null:
		selected.set_selected(false)
	if selected_point != null:
		selected_point.set_selected(false)
	selected = null
	selected_point = null


func _set_hovered_point(point: MapPoint) -> void:
	if point == _hovered_point:
		return
	if _hovered_point != null:
		_hovered_point.set_hovered(false)
	_hovered_point = point
	if point != null:
		point.set_hovered(true)


func _update_panel() -> void:
	info_panel.hide()
	point_panel.hide()
	if selected_point != null:
		var view: RegionView = selected_point.get_region_view()
		point_panel.show_point(selected_point, state.status(view.data.id),
				routes.start_block_reason(selected_point.get_point_id()))
		return
	if selected == null or selected.data == null:
		return
	var region_id: StringName = selected.data.id
	info_panel.show_region(selected.data, state.status(region_id), state.unlock_cost(),
			state.unlock_block_reason(region_id))


func _on_unlock_requested(region_id: StringName) -> void:
	if state.unlock(region_id):
		refresh_statuses()
		_update_money()
		_update_panel()


func _on_build_route_requested(point: MapPoint) -> void:
	_clear_selection()
	_update_panel()
	route_builder.start(point)


func _on_route_built(_route: MapRoute) -> void:
	_update_money()
	hint_label.text = _default_hint


func _on_hint_changed(text: String) -> void:
	hint_label.text = text if not text.is_empty() else _default_hint


func _update_money() -> void:
	money_label.text = "Money: %s" % RegionInfoPanel.format_money(state.money)


## Dünya noktasına en yakın, HIT_RADIUS içindeki nokta.
func _point_at(world_point: Vector2) -> MapPoint:
	var best: MapPoint = null
	var best_distance: float = MapPoint.HIT_RADIUS
	for point: MapPoint in _points:
		var distance: float = point.global_position.distance_to(world_point)
		if distance <= best_distance:
			best = point
			best_distance = distance
	return best


func _region_at(world_point: Vector2) -> RegionView:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_point(query):
		var view: RegionView = hit["collider"] as RegionView
		if view != null:
			return view
	return null


func _views() -> Array[RegionView]:
	var out: Array[RegionView] = []
	for child: Node in region_map.get_children():
		if child is RegionView:
			out.append(child)
	return out


func _zoom_at_mouse(factor: float) -> void:
	var before: float = _target_zoom.x
	var after: float = clampf(before * factor, MIN_ZOOM, MAX_ZOOM)
	_target_zoom = Vector2(after, after)
	var mouse_world: Vector2 = get_global_mouse_position()
	camera.position += (mouse_world - camera.position) * (1.0 - before / after)
	_clamp_camera()


func _clamp_camera() -> void:
	var bounds: Rect2 = Rect2(map_bounds.position, map_bounds.size).grow(PAN_MARGIN)
	camera.position = camera.position.clamp(bounds.position, bounds.end)
