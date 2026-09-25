class_name RouteView
extends Node2D

## Haritada bir hat: iki nokta arasında çizgi, taşınan mal etiketi ve gidip
## gelen görsel araçlar.
##
## Kural hesaplamaz: araç sayısını MapRoute'tan, her yönde taşınan malı ve hızı
## `set_flow` ile (MapFlowSim'den) alır. Araçlar yalnızca görseldir;
## simülasyonu etkilemez (tasarım belgesi). Hiçbir şey taşımayan hat gri-kesik
## çizilir ve araçları uçlarda park eder (görev 06, K1–K3).

const OUTER_WIDTH: float = 9.0
const INNER_WIDTH: float = 5.0
const OUTER_COLOR: Color = Color(0.1, 0.22, 0.35)
const INNER_COLOR: Color = Color(0.45, 0.78, 1.0)
const HOVER_COLOR: Color = Color(0.7, 0.9, 1.0)
const SELECTED_COLOR: Color = Color(1.0, 1.0, 1.0)
const SELECTED_EXTRA_WIDTH: float = 4.0
## Boş hat: soluk gri, kesik çizgi.
const IDLE_OUTER_COLOR: Color = Color(0.25, 0.27, 0.3, 0.7)
const IDLE_INNER_COLOR: Color = Color(0.72, 0.74, 0.76, 0.8)
const IDLE_DASH: float = 10.0
const LABEL_SIZE: int = 14
## Etiketin çizgiden uzaklığı (nokta adlarının üstüne binmesin).
const LABEL_OFFSET: float = 20.0
const ICON_SIZE: float = 18.0
const ARROW_SIZE: float = 7.0
## Etiketteki parçalar arası boşluk ve iki yön arası boşluk.
const LABEL_SPACING: float = 5.0
const LABEL_GAP: float = 18.0
const VEHICLE_SIZE: Vector2 = Vector2(18.0, 11.0)
## Boş dönen aracın içi (neredeyse yalnızca çerçeve).
const EMPTY_VEHICLE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)
## Park eden araçların uçtan uzaklığı ve birbirine aralığı (hat boyunca).
const PARK_OFFSET: float = 26.0
const PARK_SPACING: float = 22.0

var route: MapRoute
var from_point: MapPoint
var to_point: MapPoint
var from_position: Vector2
var to_position: Vector2

var _hovered: bool = false
var _selected: bool = false
## Oyun saati (dakika); WorldMap her karede verir. Duraklatınca araçlar durur.
var _clock: float = 0.0
## [ileri, geri]: en çok taşınan mal (yoksa null) ve toplam hız (birim/dk).
var _cargo: Array[Good] = [null, null]
var _rates: Array[float] = [0.0, 0.0]


func setup(map_route: MapRoute, start: MapPoint, end: MapPoint) -> void:
	route = map_route
	from_point = start
	to_point = end
	from_position = to_local(start.global_position)
	to_position = to_local(end.global_position)
	queue_redraw()


## Her yönde taşınan mal ve hız (MapFlowSim.main_cargo / route_flow).
func set_flow(cargo: Array[Good], rates: Array[float]) -> void:
	if cargo == _cargo and rates == _rates:
		return
	_cargo = cargo
	_rates = rates
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
	if not is_equal_approx(_clock, game_minutes) and _is_active():
		_clock = game_minutes
		queue_redraw()


## En az bir yönde yük taşınıyor mu?
func _is_active() -> bool:
	return _cargo[0] != null or _cargo[1] != null


func _draw() -> void:
	var width: float = OUTER_WIDTH + (SELECTED_EXTRA_WIDTH if _selected else 0.0)
	var highlight: bool = _selected or _hovered
	var inner: Color = SELECTED_COLOR if _selected else (HOVER_COLOR if _hovered else INNER_COLOR)
	if _is_active() or highlight:
		draw_line(from_position, to_position, OUTER_COLOR, width, true)
		draw_line(from_position, to_position, inner, INNER_WIDTH, true)
	else:
		draw_line(from_position, to_position, IDLE_OUTER_COLOR, width, true)
		draw_dashed_line(from_position, to_position, IDLE_INNER_COLOR, INNER_WIDTH, IDLE_DASH, true, true)
	if route == null:
		return
	_draw_vehicles()
	_draw_label()


## Araçlar hat boyunca eşit aralıkla gidip gelir; tur süresi = 2 × mesafe ÷ hız.
## Hiçbir yönde yük yoksa uçlarda park eder.
func _draw_vehicles() -> void:
	if route.vehicles <= 0 or route.transport.speed <= 0:
		return
	var direction: Vector2 = (to_position - from_position).normalized()
	if not _is_active():
		for i: int in route.vehicles:
			# Araçlar sırayla iki uca dağılır.
			var at_start: bool = i % 2 == 0
			var offset: float = PARK_OFFSET + PARK_SPACING * floorf(i / 2.0)
			var pos: Vector2 = (from_position + direction * offset if at_start
					else to_position - direction * offset)
			_draw_vehicle(pos, direction, EMPTY_VEHICLE_COLOR)
		return
	var round_trip: float = 2.0 * route.distance / route.transport.speed
	if round_trip <= 0.0:
		return
	for i: int in route.vehicles:
		var phase: float = fposmod(_clock / round_trip + float(i) / route.vehicles, 1.0)
		# 0 → 0.5 gidiş (ileri yön), 0.5 → 1 dönüş (geri yön).
		var forward: bool = phase < 0.5
		var t: float = phase * 2.0 if forward else (1.0 - phase) * 2.0
		var cargo: Good = _cargo[MapRoute.Direction.FORWARD if forward else MapRoute.Direction.BACKWARD]
		_draw_vehicle(from_position.lerp(to_position, t), direction,
				cargo.color if cargo != null else EMPTY_VEHICLE_COLOR)


func _draw_vehicle(pos: Vector2, direction: Vector2, fill: Color) -> void:
	draw_set_transform(pos, direction.angle())
	var rect: Rect2 = Rect2(-VEHICLE_SIZE * 0.5, VEHICLE_SIZE)
	draw_rect(rect, fill)
	draw_rect(rect, OUTER_COLOR, false, 1.5)
	draw_set_transform(Vector2.ZERO)


## Her taşıyan yön için: [simge] hız ▶ (ok, malın gittiği yönü gösterir).
func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var along: Vector2 = (to_position - from_position).normalized()
	var parts: Array[Dictionary] = []
	for direction: MapRoute.Direction in [MapRoute.Direction.FORWARD, MapRoute.Direction.BACKWARD]:
		var good: Good = _cargo[direction]
		if good == null:
			continue
		var text: String = format_rate(_rates[direction])
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		parts.append({"good": good, "text": text, "text_width": text_width,
				"arrow": along if direction == MapRoute.Direction.FORWARD else -along,
				"width": ICON_SIZE + LABEL_SPACING * 2.0 + text_width + ARROW_SIZE * 2.0})
	if parts.is_empty():
		return
	var total: float = LABEL_GAP * (parts.size() - 1)
	for part: Dictionary in parts:
		total += part["width"]
	var normal: Vector2 = Vector2(-along.y, along.x)
	# Etiket her zaman çizginin üst tarafına gelsin.
	if normal.y > 0.0:
		normal = -normal
	var mid: Vector2 = (from_position + to_position) * 0.5 + normal * LABEL_OFFSET
	var x: float = mid.x - total * 0.5
	for part: Dictionary in parts:
		GoodIcon.draw(self, Vector2(x, mid.y - ICON_SIZE * 0.5), part["good"], ICON_SIZE)
		x += ICON_SIZE + LABEL_SPACING
		var baseline: Vector2 = Vector2(x, mid.y + LABEL_SIZE * 0.35)
		draw_string_outline(font, baseline, part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, 5, OUTER_COLOR)
		draw_string(font, baseline, part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, Color.WHITE)
		x += float(part["text_width"]) + LABEL_SPACING + ARROW_SIZE
		_draw_arrow(Vector2(x, mid.y), part["arrow"])
		x += ARROW_SIZE + LABEL_GAP


func _draw_arrow(center: Vector2, direction: Vector2) -> void:
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var tip: Vector2 = center + direction * ARROW_SIZE
	var back: Vector2 = center - direction * ARROW_SIZE * 0.6
	var arrow: PackedVector2Array = [tip, back + side * ARROW_SIZE * 0.8, back - side * ARROW_SIZE * 0.8]
	draw_colored_polygon(arrow, Color.WHITE)
	arrow.append(arrow[0])
	draw_polyline(arrow, OUTER_COLOR, 1.5)


## 10.0 -> "10", 2.5 -> "2.5"
static func format_rate(value: float) -> String:
	value = snappedf(value, 0.1)
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value
