extends Node2D

## Harita ekranı: girdiyi, seçimi ve oyun saatini yönetir.
##
## Kural hesaplamaz: bütün kurallar ve sayılar MapFlowSim'dedir (bölge, hat,
## fabrika, şehir). Panelleri MapPanels doldurur; hat kurma akışı RouteBuilder'da,
## kaydırma/yakınlaştırma MapCamera'da, oyun hızı SpeedBar'dadır. Fabrikanın
## içi FactoryScreen'de tam ekran açılır; oyun saati o sırada da işler.
## Tıklama önceliği: nokta → hat → bölge. Tıklanan bölge, bölgelerin
## CollisionPolygon2D'lerine fizik sorgusuyla bulunur.

## Hat çizgisine bu kadar yakın tıklama hattı seçer (dünya birimi).
const ROUTE_HIT_DISTANCE: float = 10.0
## Kurulan fabrikanın haritadaki adı (fabrikanın türü yoktur).
const FACTORY_NAME: String = "Factory"
## Panellerin ve üst çubuğun yenilenme aralığı (gerçek saniye).
const UI_REFRESH_SECONDS: float = 0.25

@onready var camera: MapCamera = $Camera2D
@onready var region_map: Node2D = $RegionMap
@onready var map_bounds: Control = $RegionMap/MapBounds
@onready var info_panel: RegionInfoPanel = $UI/InfoPanel
@onready var point_panel: PointInfoPanel = $UI/PointPanel
@onready var route_panel: RouteInfoPanel = $UI/RoutePanel
@onready var top_bar: MapTopBar = $UI/TopBar
@onready var speed_bar: SpeedBar = %SpeedBar
@onready var route_builder: RouteBuilder = $Routes
@onready var factory_screen: FactoryScreen = $UI/FactoryScreen
@onready var hover_card: HoverCard = $UI/HoverCard

var sim: MapFlowSim = MapFlowSim.new()
var state: RegionState = sim.regions
var routes: RouteState = sim.routes
var selected: RegionView = null
var selected_point: MapPoint = null
var selected_route: RouteView = null

var _panels: MapPanels
var _points: Array[MapPoint] = []
var _hovered_point: MapPoint = null
var _hovered_route: RouteView = null
var _ui_timer: float = 0.0


func _ready() -> void:
	# Area2D'lerin fare üzerine gelme sinyalleri için gerekli.
	get_viewport().physics_object_picking = true
	camera.map_rect = map_bounds.get_global_rect()
	camera.focus_rect(_start_rect())
	for node: Node in region_map.find_children("*", "MapPoint", true, false):
		_points.append(node as MapPoint)
	_panels = MapPanels.new(sim, RegionState.DEFAULT_CONFIG, info_panel, point_panel, route_panel)
	info_panel.unlock_requested.connect(_on_unlock_requested)
	point_panel.build_route_requested.connect(_on_build_route_requested)
	point_panel.build_factory_requested.connect(_on_build_factory_requested)
	point_panel.open_factory_requested.connect(_on_open_factory_requested)
	factory_screen.setup(RegionState.DEFAULT_CONFIG)
	factory_screen.closed.connect(_on_factory_closed)
	route_panel.add_vehicle_requested.connect(func(route: MapRoute) -> void:
		if routes.add_vehicle(route): _refresh_now())
	route_panel.remove_vehicle_requested.connect(func(route: MapRoute) -> void:
		if routes.remove_vehicle(route): _refresh_now())
	route_panel.remove_route_requested.connect(_on_remove_route_requested)
	route_builder.routes = routes
	route_builder.hint_changed.connect(top_bar.show_hint)
	route_builder.route_built.connect(func(_route: MapRoute) -> void:
		top_bar.show_hint("")
		_refresh_now())
	speed_bar.advanced.connect(sim.step)
	refresh_statuses()
	_refresh_now()


func _process(delta: float) -> void:
	route_builder.set_clock(sim.clock)
	_ui_timer += delta
	if _ui_timer >= UI_REFRESH_SECONDS:
		_refresh_now()


func refresh_statuses() -> void:
	for view: RegionView in _views():
		if view.data != null:
			view.set_status(state.status(view.data.id))
	# Kilitli bölgenin noktaları görünür ama soluk.
	for point: MapPoint in _points:
		var view: RegionView = point.get_region_view()
		point.set_dimmed(view == null or view.data == null or not state.is_unlocked(view.data.id))


func _unhandled_input(event: InputEvent) -> void:
	if factory_screen.is_open():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and route_builder.is_building():
		route_builder.cancel()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT and route_builder.is_building():
			route_builder.cancel()
		elif button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(_event_to_world(button.position))
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
		_update_hover_card()


func _on_left_click(world: Vector2) -> void:
	var point: MapPoint = _point_at(world)
	if route_builder.is_building():
		# Hat kurarken: noktaya tıklamak kurar, boşluğa tıklamak iptal eder.
		if point != null:
			route_builder.try_finish(point)
		else:
			route_builder.cancel()
		return
	_clear_selection()
	if point != null:
		selected_point = point
		point.set_selected(true)
	else:
		selected_route = route_builder.route_at(world, ROUTE_HIT_DISTANCE)
		if selected_route != null:
			selected_route.set_selected(true)
		else:
			selected = _region_at(world)
			if selected != null:
				selected.set_selected(true)
	_refresh_now()


## Olayın ekran konumunu dünya koordinatına çevirir (kamera ve yakınlaştırma dahil).
func _event_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


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


## Üst çubuğu, hat etiketlerini ve açık paneli şimdi yeniler.
func _refresh_now() -> void:
	_ui_timer = 0.0
	top_bar.refresh(sim)
	route_builder.refresh_views(sim)
	MapMarkers.refresh(_points, sim, RegionState.DEFAULT_CONFIG.point_stock_capacity)
	_panels.show_selection(selected, selected_point, selected_route)
	_update_hover_card()


## Üzerine gelinen nokta ya da hattın özet kutusu (görev 06, K8).
func _update_hover_card() -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if factory_screen.is_open() or route_builder.is_building():
		hover_card.hide()
	elif _hovered_point != null:
		hover_card.show_rows(_hovered_point.describe(), _panels.point_rows(_hovered_point), mouse)
	elif _hovered_route != null and is_instance_valid(_hovered_route):
		hover_card.show_rows("%s - %s" % [_hovered_route.from_point.get_title(),
				_hovered_route.to_point.get_title()], _panels.route_rows(_hovered_route), mouse)
	else:
		hover_card.hide()


func _on_unlock_requested(region_id: StringName) -> void:
	if state.unlock(region_id):
		refresh_statuses()
		_refresh_now()


func _on_build_route_requested(point: MapPoint) -> void:
	_clear_selection()
	_refresh_now()
	route_builder.start(point)


func _on_build_factory_requested(point: MapPoint) -> void:
	if sim.factories.build(point.get_point_id()):
		point.set_factory(FACTORY_NAME)
		_refresh_now()


func _on_open_factory_requested(point: MapPoint) -> void:
	var interior: FactoryInterior = sim.factories.interior_at(point.get_point_id())
	if interior == null:
		return
	if route_builder.is_building():
		route_builder.cancel()
	_clear_selection()
	_refresh_now()
	# Harita arkada gizli kalır; kamera fareyle kaymasın.
	camera.set_process_unhandled_input(false)
	factory_screen.open(interior, point.describe())


func _on_factory_closed() -> void:
	camera.set_process_unhandled_input(true)
	_refresh_now()


func _on_remove_route_requested(route: MapRoute) -> void:
	var view: RouteView = selected_route
	routes.remove_route(route)
	_clear_selection()
	_set_hovered_route(null)
	if view != null:
		route_builder.remove_view(view)
	_refresh_now()


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


## Başlangıçta açık bölgelerin dünya koordinatında kapladığı alan.
func _start_rect() -> Rect2:
	var vertices: PackedVector2Array = []
	for view: RegionView in _views():
		if view.data != null and state.is_unlocked(view.data.id):
			for poly: PackedVector2Array in view.get_polygons():
				vertices.append_array(view.global_transform * poly)
	if vertices.is_empty():
		return Rect2()
	var rect: Rect2 = Rect2(vertices[0], Vector2.ZERO)
	for vertex: Vector2 in vertices:
		rect = rect.expand(vertex)
	return rect


func _views() -> Array[RegionView]:
	var out: Array[RegionView] = []
	for child: Node in region_map.get_children():
		if child is RegionView:
			out.append(child)
	return out
