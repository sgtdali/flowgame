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
const FACTORY_COLOR: Color = Color(0.85, 0.55, 0.25)
const SITE_COLORS: Dictionary = {
	RawResource.SiteKind.FOREST: Color(0.22, 0.62, 0.3),
	RawResource.SiteKind.FARM: Color(0.93, 0.78, 0.28),
	RawResource.SiteKind.MINE: Color(0.62, 0.58, 0.54),
}
const OUTLINE: Color = Color(0.08, 0.09, 0.1)
const LABEL_SIZE: int = 14
const WARNING_COLOR: Color = Color(1.0, 0.8, 0.2)
## Şehir gelir rozeti.
const BADGE_COLOR: Color = Color(0.55, 0.85, 0.45)
const BADGE_SATURATED_COLOR: Color = Color(1.0, 0.6, 0.2)
const BADGE_FONT_SIZE: int = 13
const BADGE_PADDING: float = 4.0
const BADGE_RISE: float = 10.0
## Bu gelirin (para/dk) altında rozet gösterilmez.
const INCOME_VISIBLE_MIN: float = 0.05
## Stok çubuğu (noktanın hemen altında) ve dolunca rengi.
const STOCK_BAR_SIZE: Vector2 = Vector2(34.0, 5.0)
const STOCK_BAR_GAP: float = 5.0
const STOCK_BAR_BACK: Color = Color(0.08, 0.09, 0.1, 0.8)
const STOCK_BAR_FILL: Color = Color(0.55, 0.85, 0.45)
const STOCK_BAR_FULL: Color = Color(0.95, 0.3, 0.25)
## Bu doluluktan sonrası "dolu" sayılır (üretim durur).
const STOCK_FULL_RATIO: float = 0.999
## Noktanın sağındaki mal simgeleri.
const GOOD_ICON_SIZE: float = 16.0
const GOOD_ICON_GAP: float = 3.0
## Adın, stok çubuğu yer alsın diye aşağı kayması.
const LABEL_DROP: float = 8.0
const WARNING_SIZE: float = 9.0
## Kilitli bölgedeki noktanın görünürlüğü.
const DIMMED_ALPHA: float = 0.6

var _hovered: bool = false
var _selected: bool = false
## Arsaya fabrika kurulduysa adı (ör. "Factory"); boşsa arsa boş.
var _factory_name: String = ""
## Fabrikada sorun var mı (çıkış dolu ya da makineler girdi bekliyor).
var _warning: bool = false
## Şehir rozeti: geçen dakikanın geliri ve şehir doydu mu (görev 06, K4).
var _income: float = 0.0
var _saturated: bool = false
## Stok doluluğu 0–1; negatifse çubuk yok (görev 06, K5).
var _stock_fill: float = -1.0
## Noktanın sağında simgesi gösterilen mallar (yatakta hammadde, fabrikada çıktılar).
var _goods: Array[Good] = []


func _ready() -> void:
	z_as_relative = false
	z_index = POINT_Z_INDEX


func set_factory(factory_name: String) -> void:
	_factory_name = factory_name
	queue_redraw()


func set_warning(value: bool) -> void:
	if _warning != value:
		_warning = value
		queue_redraw()


func set_income(income: float, saturated: bool) -> void:
	if not is_equal_approx(_income, income) or _saturated != saturated:
		_income = income
		_saturated = saturated
		queue_redraw()


## `fill`: 0–1 doluluk; negatifse çubuk gizlenir.
func set_stock(fill: float) -> void:
	if not is_equal_approx(_stock_fill, fill):
		_stock_fill = fill
		queue_redraw()


func set_goods(goods: Array[Good]) -> void:
	if goods != _goods:
		_goods = goods
		queue_redraw()


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
	if not _factory_name.is_empty():
		return _factory_name
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
			if _income >= INCOME_VISIBLE_MIN:
				_draw_income_badge()
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
			if _factory_name.is_empty():
				draw_rect(rect, PLOT_COLOR)
				draw_rect(rect, Color.WHITE, false, 2.0)
			else:
				# Kurulu fabrika: dolu kare + çatı.
				draw_rect(rect.grow(2.0), FACTORY_COLOR)
				draw_rect(rect.grow(2.0), OUTLINE, false, 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(-SIZE, -SIZE),
						Vector2(0.0, -SIZE - 8.0), Vector2(SIZE, -SIZE)]), FACTORY_COLOR.darkened(0.3))
			if _warning:
				_draw_warning(Vector2(SIZE + 4.0, -SIZE - 4.0))

	_draw_goods()
	_draw_stock_bar()
	_draw_label()


## Noktanın sağında mal simgeleri. Editörde çizilmez (veri oyunda gelir).
func _draw_goods() -> void:
	var x: float = SIZE + 6.0
	for good: Good in _goods:
		GoodIcon.draw(self, Vector2(x, -GOOD_ICON_SIZE * 0.5), good, GOOD_ICON_SIZE)
		x += GOOD_ICON_SIZE + GOOD_ICON_GAP


func _draw_stock_bar() -> void:
	if _stock_fill < 0.0:
		return
	var back: Rect2 = Rect2(Vector2(-STOCK_BAR_SIZE.x * 0.5, SIZE + STOCK_BAR_GAP), STOCK_BAR_SIZE)
	draw_rect(back, STOCK_BAR_BACK)
	var fill: float = clampf(_stock_fill, 0.0, 1.0)
	var bar: Rect2 = Rect2(back.position, Vector2(back.size.x * fill, back.size.y))
	draw_rect(bar, STOCK_BAR_FULL if fill >= STOCK_FULL_RATIO else STOCK_BAR_FILL)
	draw_rect(back, OUTLINE, false, 1.0)


## Şehrin üstünde "+10/min"; şehir doyduysa turuncu.
func _draw_income_badge() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = "+%s/min" % RouteView.format_rate(_income)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE)
	var box: Rect2 = Rect2(Vector2(-text_size.x * 0.5 - BADGE_PADDING, -SIZE - BADGE_RISE - text_size.y),
			Vector2(text_size.x + BADGE_PADDING * 2.0, text_size.y + BADGE_PADDING))
	draw_rect(box, BADGE_SATURATED_COLOR if _saturated else BADGE_COLOR)
	draw_rect(box, OUTLINE, false, 1.5)
	draw_string(font, Vector2(box.position.x + BADGE_PADDING, box.end.y - BADGE_PADDING * 0.5 - font.get_descent(BADGE_FONT_SIZE)),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE, OUTLINE)


## Sarı üçgen içinde "!" — sorunlu fabrika.
func _draw_warning(center: Vector2) -> void:
	var s: float = WARNING_SIZE
	var triangle: PackedVector2Array = [center + Vector2(0.0, -s), center + Vector2(s, s * 0.8),
			center + Vector2(-s, s * 0.8)]
	draw_colored_polygon(triangle, WARNING_COLOR)
	triangle.append(triangle[0])
	draw_polyline(triangle, OUTLINE, 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-s, s * 0.6), "!",
			HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, int(s * 1.4), OUTLINE)


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = get_title()
	var width: float = 160.0
	var pos: Vector2 = Vector2(-width * 0.5, SIZE + 20.0 + (LABEL_DROP if _stock_fill >= 0.0 else 0.0))
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, 5, OUTLINE)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, Color.WHITE)
