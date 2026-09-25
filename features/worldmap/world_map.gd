extends Node2D

## Harita ekranı: girdiyi, seçimi ve oyun saatini yönetir.
##
## Kural hesaplamaz: bütün kurallar ve sayılar MapFlowSim'dedir (bölge, hat,
## fabrika, şehir). Panelleri MapPanels doldurur; hat kurma akışı RouteBuilder'da,
## araç çubuğu aletleri MapTools'ta, "fare neyin üstünde" MapPicker'da,
## kaydırma/yakınlaştırma MapCamera'da, oyun hızı SpeedBar'dadır. Fabrikanın
## içi FactoryScreen'de tam ekran açılır; oyun saati o sırada da işler.
## Alet seçili değilken tıklama önceliği: nokta → hat → bölge.

## Kurulan fabrikanın haritadaki adı: kurulma sırası (fabrikanın türü yoktur; görev 08, K3).
const FACTORY_NAME: String = "Factory %d"
## Panellerin ve üst çubuğun yenilenme aralığı (gerçek saniye).
const UI_REFRESH_SECONDS: float = 0.25
## Sağ tuş bundan az kayarak bırakılırsa "sağ tık" sayılır (fazlası kaydırmadır).
const RIGHT_CLICK_SLOP: float = 6.0

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
@onready var tool_bar: ToolBar = $UI/ToolBar
@onready var cursor_tag: CursorTag = $UI/CursorTag

var sim: MapFlowSim = MapFlowSim.new()
var state: RegionState = sim.regions
var routes: RouteState = sim.routes
var tools: MapTools
var selection: MapSelection = MapSelection.new()

var _panels: MapPanels
var _picker: MapPicker
var _points: Array[MapPoint] = []
var _ui_timer: float = 0.0
var _right_press_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Area2D'lerin fare üzerine gelme sinyalleri için gerekli.
	get_viewport().physics_object_picking = true
	_picker = MapPicker.new(self, region_map, route_builder)
	_points = _picker.points
	camera.map_rect = map_bounds.get_global_rect()
	camera.focus_rect(_picker.regions_rect(_unlocked_ids()))
	_panels = MapPanels.new(sim, RegionState.DEFAULT_CONFIG, info_panel, point_panel, route_panel)
	info_panel.unlock_requested.connect(_on_unlock_requested)
	point_panel.build_route_requested.connect(_on_build_route_requested)
	point_panel.open_factory_requested.connect(_on_open_factory_requested)
	factory_screen.setup(RegionState.DEFAULT_CONFIG)
	factory_screen.closed.connect(_on_factory_closed)
	route_panel.add_vehicle_requested.connect(func(route: MapRoute) -> void:
		if routes.add_vehicle(route): _refresh_now())
	route_panel.remove_vehicle_requested.connect(func(route: MapRoute) -> void:
		if routes.remove_vehicle(route): _refresh_now())
	route_panel.remove_route_requested.connect(_on_remove_route_requested)
	route_builder.routes = routes
	route_builder.map_scale = region_map.global_scale.x
	route_builder.hint_changed.connect(_show_hint)
	route_builder.route_built.connect(func(_route: MapRoute) -> void:
		_show_hint("")
		_refresh_now())
	tools = MapTools.new(sim, route_builder)
	tools.tool_changed.connect(_on_tool_changed)
	tools.factory_requested.connect(_on_build_factory_requested)
	tools.unlock_requested.connect(_on_unlock_requested)
	tools.rejected.connect(top_bar.show_error)
	tool_bar.tool_pressed.connect(tools.toggle)
	speed_bar.advanced.connect(sim.step)
	refresh_statuses()
	_refresh_now()


func _process(delta: float) -> void:
	route_builder.set_clock(sim.clock)
	_ui_timer += delta
	if _ui_timer >= UI_REFRESH_SECONDS:
		_refresh_now()


func refresh_statuses() -> void:
	for view: RegionView in _picker.views():
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
	if key != null:
		if tools.handle_key(key):
			get_viewport().set_input_as_handled()
		elif key.pressed and key.keycode == KEY_ESCAPE and route_builder.is_building():
			route_builder.cancel()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_RIGHT:
			# Sağ tuşla sürüklemek haritayı kaydırır; yalnızca yerinde tıklamak geri adımdır.
			if button.pressed:
				_right_press_position = button.position
			elif button.position.distance_to(_right_press_position) <= RIGHT_CLICK_SLOP:
				if not tools.step_back() and route_builder.is_building():
					route_builder.cancel()
		elif button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(_picker.to_world(button.position))
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		var world: Vector2 = _picker.to_world(motion.position)
		selection.hover_point(_picker.point_at(world))
		route_builder.update_preview(world, selection.hovered_point)
		var hover_route: RouteView = null
		if selection.hovered_point == null and not route_builder.is_building():
			hover_route = _picker.route_at(world)
		selection.hover_route(hover_route)
		_update_hover_card()
		cursor_tag.show_for(tools.cursor_tag(selection.hovered_point,
				_picker.region_at(world) if tools.tool == MapTools.Tool.FACTORY else null), motion.position)


func _on_left_click(world: Vector2) -> void:
	var point: MapPoint = _picker.point_at(world)
	# Alet seçiliyken tıklama aleti uygular; seçim ve panel yok (K4).
	if tools.handle_click(point, _picker.region_at(world), world):
		return
	if route_builder.is_building():
		# Panelden başlatılan hat: noktaya tıklamak kurar, boşluğa tıklamak iptal eder.
		if point != null:
			route_builder.try_finish(point)
		else:
			route_builder.cancel()
		return
	selection.select_at(_picker, world)
	_refresh_now()


func _refresh_now() -> void:
	_ui_timer = 0.0
	top_bar.refresh(sim)
	route_builder.refresh_views(sim)
	MapMarkers.refresh(_points, sim, RegionState.DEFAULT_CONFIG.point_stock_capacity)
	_refresh_highlights()
	_panels.show_selection(selection.region, selection.point, selection.route)
	_update_hover_card()


## Üzerine gelinen nokta ya da hattın özet kutusu (görev 06, K8).
func _update_hover_card() -> void:
	if factory_screen.is_open() or route_builder.is_building():
		hover_card.hide()
	else:
		hover_card.show_for(selection.hovered_point, selection.hovered_route, _panels,
				get_viewport().get_mouse_position())


## Üst çubuğun ortası: hat kurma ipucu; yoksa seçili aletin ipucu. Hat kurma
## başlayıp bitince de çağrılır; vurgular o an güncellensin.
func _show_hint(text: String) -> void:
	top_bar.show_hint(text if not text.is_empty() else tools.idle_hint())
	_refresh_highlights()


func _refresh_highlights() -> void:
	ToolHighlights.refresh(tools.tool, route_builder.start_point(), _points, _picker.views(), sim)


func _on_tool_changed(tool: MapTools.Tool) -> void:
	tool_bar.show_tool(tool)
	cursor_tag.hide()
	if tool != MapTools.Tool.NONE:
		selection.clear()
	_refresh_now()
	_show_hint("")


func _on_unlock_requested(region_id: StringName) -> void:
	if state.unlock(region_id):
		refresh_statuses()
		_refresh_now()


func _on_build_route_requested(point: MapPoint) -> void:
	selection.clear()
	_refresh_now()
	route_builder.start(point)


## Fabrikayı kurar ve tıklanan yere haritada noktasını koyar.
func _on_build_factory_requested(region: RegionView, world_position: Vector2) -> void:
	var number: int = sim.factories.next_number()
	var factory_id: StringName = sim.factories.build(region.data.id)
	if factory_id.is_empty():
		return
	var point: MapPoint = MapPoint.new()
	point.kind = MapPoint.Kind.FACTORY
	point.name = String(factory_id).get_slice("/", 1)
	region.points_root().add_child(point)
	point.global_position = world_position
	point.set_factory(FACTORY_NAME % number)
	_points.append(point)
	_refresh_now()


func _on_open_factory_requested(point: MapPoint) -> void:
	var interior: FactoryInterior = sim.factories.interior_at(point.get_point_id())
	if interior == null:
		return
	tools.set_tool(MapTools.Tool.NONE)
	if route_builder.is_building():
		route_builder.cancel()
	selection.clear()
	_refresh_now()
	# Harita arkada gizli kalır; kamera fareyle kaymasın, alt çubuk görünmesin.
	camera.set_process_unhandled_input(false)
	tool_bar.hide()
	factory_screen.open(interior, point.describe())


func _on_factory_closed() -> void:
	camera.set_process_unhandled_input(true)
	tool_bar.show()
	_refresh_now()


func _on_remove_route_requested(route: MapRoute) -> void:
	var view: RouteView = selection.route
	routes.remove_route(route)
	selection.clear()
	selection.hover_route(null)
	if view != null:
		route_builder.remove_view(view)
	_refresh_now()


func _unlocked_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for region: RegionData in RegionCatalog.all():
		if state.is_unlocked(region.id):
			out.append(region.id)
	return out
