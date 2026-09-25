class_name RouteBuilder
extends Node2D

## Hat katmanı: kurulmuş hatları çizer ve hat kurma akışını yönetir
## (başlangıç noktası → önizleme çizgisi → ikinci noktaya tıklama).
##
## Kural hesaplamaz: kurulup kurulamayacağını ve maliyeti RouteState söyler.
## WorldMap girdiyi buraya yönlendirir; ipucu metnini hint_changed ile verir.

signal hint_changed(text: String)
signal route_built(route: MapRoute)

## Araştırma gelene kadar kurulan tek tür.
const DEFAULT_TRANSPORT: TransportType = preload("res://data/transport_types/at_arabasi.tres")
const PREVIEW_OK: Color = Color(0.45, 0.9, 0.5, 0.85)
const PREVIEW_BLOCKED: Color = Color(0.95, 0.4, 0.35, 0.85)
const PREVIEW_IDLE: Color = Color(1.0, 1.0, 1.0, 0.6)

var routes: RouteState
## Haritanın ekrandaki ölçeği (WorldMap'te RegionMap.scale). Hat mesafesi
## ekran uzunluğuyla değil harita birimiyle ölçülür; ölçek büyüyünce kapasite değişmesin.
var map_scale: float = 1.0
var _start: MapPoint = null
var _preview: Line2D
var _views: Array[RouteView] = []
var _start_hint: String = ""


func _ready() -> void:
	_preview = Line2D.new()
	_preview.width = 5.0
	_preview.default_color = PREVIEW_IDLE
	_preview.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_preview.end_cap_mode = Line2D.LINE_CAP_ROUND
	_preview.visible = false
	add_child(_preview)


func is_building() -> bool:
	return _start != null


## Yarım hattın ilk noktası (hat kurulmuyorsa null).
func start_point() -> MapPoint:
	return _start


func start(point: MapPoint) -> void:
	_start = point
	_preview.visible = true
	_preview.points = PackedVector2Array([to_local(point.global_position), to_local(point.global_position)])
	_preview.default_color = PREVIEW_IDLE
	_start_hint = "Route from %s: click another point (cost %d). Right-click or Esc to cancel." % [
			point.describe(), routes.build_cost(DEFAULT_TRANSPORT)]
	hint_changed.emit(_start_hint)


func cancel() -> void:
	_start = null
	_preview.visible = false
	hint_changed.emit("")


## Fare hareketinde: önizleme çizgisini ve ipucunu günceller.
## `hovered`: farenin üzerindeki nokta (yoksa null).
func update_preview(world_mouse: Vector2, hovered: MapPoint) -> void:
	if _start == null:
		return
	var end: Vector2 = hovered.global_position if hovered != null else world_mouse
	_preview.points = PackedVector2Array([to_local(_start.global_position), to_local(end)])
	if hovered == null or hovered == _start:
		_preview.default_color = PREVIEW_IDLE
		hint_changed.emit(_start_hint)
		return
	var reason: String = routes.build_block_reason(_start.get_point_id(),
			hovered.get_point_id(), DEFAULT_TRANSPORT)
	if reason.is_empty():
		_preview.default_color = PREVIEW_OK
		var distance: float = map_distance(_start, hovered)
		var capacity: float = MapRoute.capacity_for(1, DEFAULT_TRANSPORT, distance)
		hint_changed.emit("Build route to %s: %s, cost %d, %s/min with 1 %s" % [
				hovered.describe(), MapUnits.km_text(distance), routes.build_cost(DEFAULT_TRANSPORT),
				RouteView.format_rate(capacity), DEFAULT_TRANSPORT.display_name.to_lower()])
	else:
		_preview.default_color = PREVIEW_BLOCKED
		hint_changed.emit("Can't build to %s: %s" % [hovered.describe(), reason])


## İkinci noktaya tıklandı. Kurulursa akış biter ve true döner; kurulamazsa
## akış sürer, ipucu nedeni söyler.
func try_finish(point: MapPoint) -> bool:
	if _start == null or point == null:
		return false
	var distance: float = map_distance(_start, point)
	var route: MapRoute = routes.build(_start.get_point_id(), point.get_point_id(),
			distance, DEFAULT_TRANSPORT)
	if route == null:
		hint_changed.emit("Can't build to %s: %s" % [point.describe(), routes.build_block_reason(
				_start.get_point_id(), point.get_point_id(), DEFAULT_TRANSPORT)])
		return false
	_add_view(route, _start, point)
	_start = null
	_preview.visible = false
	route_built.emit(route)
	return true


## İki nokta arasındaki düz mesafe, harita biriminde.
func map_distance(a: MapPoint, b: MapPoint) -> float:
	return a.global_position.distance_to(b.global_position) / maxf(map_scale, 0.001)


## Hatların etiketini ve araçlarını akışa göre günceller.
func refresh_views(sim: MapFlowSim) -> void:
	for view: RouteView in _views:
		var cargo: Array[Good] = []
		var rates: Array[float] = []
		for direction: MapRoute.Direction in [MapRoute.Direction.FORWARD, MapRoute.Direction.BACKWARD]:
			cargo.append(sim.main_cargo(view.route, direction))
			rates.append(sim.route_flow(view.route, direction))
		view.set_flow(cargo, rates)


## Araçları oyun saatine göre konumlandırır.
func set_clock(game_minutes: float) -> void:
	for view: RouteView in _views:
		view.set_clock(game_minutes)


## Dünya noktasına `max_distance` içindeki en yakın hat (yoksa null).
func route_at(world_point: Vector2, max_distance: float) -> RouteView:
	var best: RouteView = null
	var best_distance: float = max_distance
	for view: RouteView in _views:
		var distance: float = view.distance_to(world_point)
		if distance <= best_distance:
			best = view
			best_distance = distance
	return best


func remove_view(view: RouteView) -> void:
	_views.erase(view)
	view.queue_free()


func _add_view(route: MapRoute, start: MapPoint, end: MapPoint) -> void:
	var view: RouteView = RouteView.new()
	add_child(view)
	# Önizleme çizgisi hatların üstünde kalsın.
	move_child(view, _preview.get_index())
	view.setup(route, start, end)
	_views.append(view)
