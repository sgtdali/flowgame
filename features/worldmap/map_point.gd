@tool
class_name MapPoint
extends Node2D

## Haritada bir nokta: ham madde alanı, fabrika arsası ya da şehir.
##
## Noktalar çizim sahnesinde bölge düğümünün altında durur
## (RegionMap.tscn → Area1/Points/...). tools/generate_points.gd bölge
## verisinden üretir; konum sahnede saklanır ve elle kaydırılabilir.
## Hangi bölgeye ait olduğu sahnedeki yerinden bellidir (get_region_view).
## Kural hesaplamaz: soluk/seçili durumu WorldMap verir.

enum Kind { RESOURCE_SITE, FACTORY_PLOT, CITY }

@export var kind: Kind = Kind.FACTORY_PLOT:
	set(value):
		kind = value
		queue_redraw()
## Yalnızca ham madde alanında: çıkan hammadde.
@export var resource: RawResource:
	set(value):
		resource = value
		queue_redraw()
## Aynı bölgedeki aynı türden noktaları ayırır. Ham madde alanında
## RegionData.resources içindeki sırasıdır.
@export var slot_index: int = 0

## Noktalar hatların üstünde çizilsin (hat katmanı z=10, bkz. WorldMap.tscn).
const POINT_Z_INDEX: int = 20
## Tıklama/üzerine gelme yarıçapı (dünya birimi).
const HIT_RADIUS: float = 18.0
const SIZE: float = 11.0
const CITY_COLOR: Color = Color(0.86, 0.3, 0.26)
const PLOT_COLOR: Color = Color(0.2, 0.22, 0.24, 0.75)
const SITE_COLORS: Dictionary = {
	RawResource.SiteKind.FOREST: Color(0.22, 0.62, 0.3),
	RawResource.SiteKind.FARM: Color(0.93, 0.78, 0.28),
	RawResource.SiteKind.MINE: Color(0.62, 0.58, 0.54),
}
const OUTLINE: Color = Color(0.08, 0.09, 0.1)
const LABEL_SIZE: int = 14
## Kilitli bölgedeki noktanın görünürlüğü.
const DIMMED_ALPHA: float = 0.6

var _hovered: bool = false
var _selected: bool = false


func _ready() -> void:
	z_as_relative = false
	z_index = POINT_Z_INDEX


func set_dimmed(value: bool) -> void:
	modulate = Color(1.0, 1.0, 1.0, DIMMED_ALPHA) if value else Color.WHITE


func set_hovered(value: bool) -> void:
	if _hovered != value:
		_hovered = value
		queue_redraw()


func set_selected(value: bool) -> void:
	if _selected != value:
		_selected = value
		queue_redraw()


## Kurallarda (RouteState) kullanılan, sahneden bağımsız kimlik: "area1/City".
func get_point_id() -> StringName:
	var view: RegionView = get_region_view()
	var region_id: String = String(view.data.id) if view != null and view.data != null else "?"
	return StringName("%s/%s" % [region_id, name])


func get_region_view() -> RegionView:
	var node: Node = get_parent()
	while node != null and not node is RegionView:
		node = node.get_parent()
	return node as RegionView


## Haritada ve panelde görünen ad.
func get_title() -> String:
	match kind:
		Kind.CITY:
			# Editörde (tool) RegionData'nın fonksiyonları çağrılamaz; alanı okunur.
			var view: RegionView = get_region_view()
			if view != null and view.data != null and not view.data.city_name.is_empty():
				return view.data.city_name
			return "City"
		Kind.RESOURCE_SITE:
			if resource != null:
				return RawResource.site_name(resource.site_kind)
			return "Resource Site"
	return "Plot %d" % (slot_index + 1)


## "Forest (Area 1)" — ipuçlarında ve hat panelinde.
func describe() -> String:
	var view: RegionView = get_region_view()
	var region_name: String = view.data.display_name if view != null and view.data != null else "?"
	return "%s (%s)" % [get_title(), region_name]


func _draw() -> void:
	if _selected:
		draw_circle(Vector2.ZERO, SIZE + 9.0, Color(1.0, 1.0, 1.0, 0.35))
		draw_arc(Vector2.ZERO, SIZE + 9.0, 0.0, TAU, 32, Color.WHITE, 3.0)
	elif _hovered:
		draw_circle(Vector2.ZERO, SIZE + 8.0, Color(1.0, 1.0, 1.0, 0.45))
		draw_arc(Vector2.ZERO, SIZE + 8.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.85), 2.0)

	match kind:
		Kind.CITY:
			draw_circle(Vector2.ZERO, SIZE + 3.0, Color.WHITE)
			draw_circle(Vector2.ZERO, SIZE, CITY_COLOR)
			draw_arc(Vector2.ZERO, SIZE + 3.0, 0.0, TAU, 32, OUTLINE, 2.0)
		Kind.RESOURCE_SITE:
			var color: Color = Color.GRAY
			if resource != null:
				color = SITE_COLORS.get(resource.site_kind, Color.GRAY)
			var s: float = SIZE + 2.0
			var diamond: PackedVector2Array = [
				Vector2(0.0, -s), Vector2(s, 0.0), Vector2(0.0, s), Vector2(-s, 0.0)]
			draw_colored_polygon(diamond, color)
			diamond.append(diamond[0])
			draw_polyline(diamond, OUTLINE, 2.0)
		Kind.FACTORY_PLOT:
			var rect: Rect2 = Rect2(Vector2(-SIZE, -SIZE), Vector2(SIZE, SIZE) * 2.0)
			draw_rect(rect, PLOT_COLOR)
			draw_rect(rect, Color.WHITE, false, 2.0)

	_draw_label()


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = get_title()
	var width: float = 160.0
	var pos: Vector2 = Vector2(-width * 0.5, SIZE + 20.0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, 5, OUTLINE)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, Color.WHITE)
