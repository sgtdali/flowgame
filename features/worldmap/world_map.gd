extends Node2D

## Harita ekranı: bölgeleri durumlarıyla gösterir, seçimi ve kamerayı yönetir.
##
## Kural hesaplamaz: bölge durumu RegionState'ten gelir. Tıklanan bölge,
## bölgelerin CollisionPolygon2D'lerine fizik sorgusuyla bulunur. Noktaya
## tıklama bölgeye tıklamadan önceliklidir (yarıçap kontrolü). Hat kurma
## akışı RouteBuilder'dadır; burası yalnızca girdiyi ona yönlendirir.
## Kaydırma ve yakınlaştırma MapCamera'dadır.

## Hat çizgisine bu kadar yakın tıklama hattı seçer (dünya birimi).
const ROUTE_HIT_DISTANCE: float = 10.0

@onready var camera: MapCamera = $Camera2D
@onready var region_map: Node2D = $RegionMap
@onready var map_bounds: Control = $RegionMap/MapBounds
@onready var info_panel: RegionInfoPanel = $UI/InfoPanel
@onready var point_panel: PointInfoPanel = $UI/PointPanel
@onready var route_panel: RouteInfoPanel = $UI/RoutePanel
@onready var money_label: Label = %MoneyLabel
@onready var hint_label: Label = $UI/TopBar/Margin/HBox/HintLabel
@onready var route_builder: RouteBuilder = $Routes

var state: RegionState = RegionState.new()
var routes: RouteState = RouteState.new(state)
var selected: RegionView = null
var selected_point: MapPoint = null
var selected_route: RouteView = null

var _points: Array[MapPoint] = []
var _hovered_point: MapPoint = null
var _hovered_route: RouteView = null

var _default_hint: String = ""


func _ready() -> void:
	# Area2D'lerin fare üzerine gelme sinyalleri için gerekli.
	get_viewport().physics_object_picking = true
	camera.map_rect = Rect2(map_bounds.position, map_bounds.size)
	for node: Node in region_map.find_children("*", "MapPoint", true, false):
		_points.append(node as MapPoint)
	info_panel.unlock_requested.connect(_on_unlock_requested)
	point_panel.build_route_requested.connect(_on_build_route_requested)
	route_panel.add_vehicle_requested.connect(_on_add_vehicle_requested)
	route_panel.remove_vehicle_requested.connect(_on_remove_vehicle_requested)
	route_panel.remove_route_requested.connect(_on_remove_route_requested)
	route_builder.routes = routes
	route_builder.hint_changed.connect(_on_hint_changed)
	route_builder.route_built.connect(_on_route_built)
	_default_hint = hint_label.text
	refresh_statuses()
	_update_money()


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
				var route_view: RouteView = route_builder.route_at(world, ROUTE_HIT_DISTANCE)
				if route_view != null:
					_select_route(route_view)
				else:
					_select(_region_at(world))
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		var world: Vector2 = _event_to_world(motion.position)
		_set_hovered_point(_point_at(world))
		route_builder.update_preview(world, _hovered_point)
		var hover_route: RouteView = null
		if _hovered_point == null and not route_builder.is_building():
			hover_route = route_builder.route_at(world, ROUTE_HIT_DISTANCE)
		_set_hovered_route(hover_route)


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


func _select_route(view: RouteView) -> void:
	_clear_selection()
	selected_route = view
	view.set_selected(true)
	_update_panel()


func _clear_selection() -> void:
	if selected != null:
		selected.set_selected(false)
	if selected_point != null:
		selected_point.set_selected(false)
	if selected_route != null:
		selected_route.set_selected(false)
	selected = null
	selected_point = null
	selected_route = null


func _set_hovered_route(view: RouteView) -> void:
	if view == _hovered_route:
		return
	if _hovered_route != null and is_instance_valid(_hovered_route):
		_hovered_route.set_hovered(false)
	_hovered_route = view
	if view != null:
		view.set_hovered(true)


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
	route_panel.hide()
	if selected_route != null:
		var route: MapRoute = selected_route.route
		route_panel.show_route(selected_route, routes.add_vehicle_block_reason(route),
				routes.remove_vehicle_block_reason(route), routes.vehicle_refund(route.transport))
		return
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


func _on_add_vehicle_requested(route: MapRoute) -> void:
	if routes.add_vehicle(route):
		_after_route_change()


func _on_remove_vehicle_requested(route: MapRoute) -> void:
	if routes.remove_vehicle(route):
		_after_route_change()


func _on_remove_route_requested(route: MapRoute) -> void:
	var view: RouteView = selected_route
	routes.remove_route(route)
	_clear_selection()
	_set_hovered_route(null)
	if view != null:
		route_builder.remove_view(view)
	_after_route_change()


func _after_route_change() -> void:
	route_builder.refresh_views()
	_update_money()
	_update_panel()


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
