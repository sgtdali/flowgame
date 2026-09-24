class_name RouteView
extends Node2D

## Haritada bir hat: iki nokta arasında çizgi ve ortasında kapasite etiketi.
##
## Kural hesaplamaz: kapasiteyi MapRoute'tan okur. Uçların konumu kurulurken
## verilir (noktalar hareket etmez).

const OUTER_WIDTH: float = 9.0
const INNER_WIDTH: float = 5.0
const OUTER_COLOR: Color = Color(0.1, 0.22, 0.35)
const INNER_COLOR: Color = Color(0.45, 0.78, 1.0)
const LABEL_SIZE: int = 14

var route: MapRoute
var from_position: Vector2
var to_position: Vector2


func setup(map_route: MapRoute, from_pos: Vector2, to_pos: Vector2) -> void:
	route = map_route
	from_position = from_pos
	to_position = to_pos
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	draw_line(from_position, to_position, OUTER_COLOR, OUTER_WIDTH, true)
	draw_line(from_position, to_position, INNER_COLOR, INNER_WIDTH, true)
	if route == null:
		return
	var font: Font = ThemeDB.fallback_font
	var text: String = "%s/min" % format_rate(route.capacity_per_minute())
	var width: float = 120.0
	var mid: Vector2 = (from_position + to_position) * 0.5
	var pos: Vector2 = mid + Vector2(-width * 0.5, -10.0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, 5, OUTER_COLOR)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, Color.WHITE)


## 10.0 -> "10", 2.5 -> "2.5"
static func format_rate(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value
