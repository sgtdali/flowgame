class_name RouteView
extends Node2D

## Haritada bir hat: iki nokta arasında çizgi, kapasite etiketi ve gidip gelen
## görsel araçlar.
##
## Kural hesaplamaz: kapasite ve araç sayısını MapRoute'tan okur. Araçlar
## yalnızca görseldir; simülasyonu etkilemez (tasarım belgesi).

const OUTER_WIDTH: float = 9.0
const INNER_WIDTH: float = 5.0
const OUTER_COLOR: Color = Color(0.1, 0.22, 0.35)
const INNER_COLOR: Color = Color(0.45, 0.78, 1.0)
const HOVER_COLOR: Color = Color(0.7, 0.9, 1.0)
const SELECTED_COLOR: Color = Color(1.0, 1.0, 1.0)
const SELECTED_EXTRA_WIDTH: float = 4.0
const LABEL_SIZE: int = 14
## Kapasite yazısının çizgiden uzaklığı (nokta adlarının üstüne binmesin).
const LABEL_OFFSET: float = 16.0
const VEHICLE_SIZE: Vector2 = Vector2(18.0, 11.0)
const VEHICLE_COLOR: Color = Color(0.72, 0.5, 0.28)

var route: MapRoute
var from_point: MapPoint
var to_point: MapPoint
var from_position: Vector2
var to_position: Vector2

var _hovered: bool = false
var _selected: bool = false
## Oyun saati (dakika); WorldMap her karede verir. Duraklatınca araçlar durur.
var _clock: float = 0.0


func setup(map_route: MapRoute, start: MapPoint, end: MapPoint) -> void:
	route = map_route
	from_point = start
	to_point = end
	from_position = to_local(start.global_position)
	to_position = to_local(end.global_position)
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func set_hovered(value: bool) -> void:
	if _hovered != value:
		_hovered = value
		queue_redraw()


func set_selected(value: bool) -> void:
	if _selected != value:
		_selected = value
		queue_redraw()


## Dünya noktasının hat çizgisine uzaklığı.
func distance_to(world_point: Vector2) -> float:
	var local: Vector2 = to_local(world_point)
	return local.distance_to(Geometry2D.get_closest_point_to_segment(local, from_position, to_position))


func set_clock(game_minutes: float) -> void:
	if not is_equal_approx(_clock, game_minutes):
		_clock = game_minutes
		queue_redraw()


func _draw() -> void:
	var width: float = OUTER_WIDTH + (SELECTED_EXTRA_WIDTH if _selected else 0.0)
	var inner: Color = SELECTED_COLOR if _selected else (HOVER_COLOR if _hovered else INNER_COLOR)
	draw_line(from_position, to_position, OUTER_COLOR, width, true)
	draw_line(from_position, to_position, inner, INNER_WIDTH, true)
	if route == null:
		return
	_draw_vehicles()
	_draw_label()


## Araçlar hat boyunca eşit aralıkla gidip gelir; tur süresi = 2 × mesafe ÷ hız.
func _draw_vehicles() -> void:
	if route.vehicles <= 0 or route.transport.speed <= 0:
		return
	var round_trip: float = 2.0 * route.distance / route.transport.speed
	if round_trip <= 0.0:
		return
	var direction: Vector2 = (to_position - from_position).normalized()
	for i: int in route.vehicles:
		var phase: float = fposmod(_clock / round_trip + float(i) / route.vehicles, 1.0)
		# 0 → 0.5 gidiş, 0.5 → 1 dönüş.
		var t: float = phase * 2.0 if phase < 0.5 else (1.0 - phase) * 2.0
		var pos: Vector2 = from_position.lerp(to_position, t)
		draw_set_transform(pos, direction.angle())
		var rect: Rect2 = Rect2(-VEHICLE_SIZE * 0.5, VEHICLE_SIZE)
		draw_rect(rect, VEHICLE_COLOR)
		draw_rect(rect, OUTER_COLOR, false, 1.5)
	draw_set_transform(Vector2.ZERO)


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = "%s/min" % format_rate(route.capacity_per_minute())
	var width: float = 120.0
	var along: Vector2 = (to_position - from_position).normalized()
	var normal: Vector2 = Vector2(-along.y, along.x)
	# Yazı her zaman çizginin üst tarafına gelsin.
	if normal.y > 0.0:
		normal = -normal
	var mid: Vector2 = (from_position + to_position) * 0.5 + normal * LABEL_OFFSET
	var pos: Vector2 = mid + Vector2(-width * 0.5, 5.0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, 5, OUTER_COLOR)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, Color.WHITE)


## 10.0 -> "10", 2.5 -> "2.5"
static func format_rate(value: float) -> String:
	value = snappedf(value, 0.1)
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value
