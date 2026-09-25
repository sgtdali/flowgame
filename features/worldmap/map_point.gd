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

## Sıra MapPoints.Kind ile aynı (sahnede sayı olarak saklanır).
enum Kind { RESOURCE_SITE, FACTORY, CITY }

@export var kind: Kind = Kind.CITY:
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
const FACTORY_COLOR: Color = Color(0.85, 0.55, 0.25)
const SITE_COLORS: Dictionary = {
	RawResource.SiteKind.FOREST: Color(0.22, 0.62, 0.3),
	RawResource.SiteKind.FARM: Color(0.93, 0.78, 0.28),
	RawResource.SiteKind.MINE: Color(0.62, 0.58, 0.54),
}
const OUTLINE: Color = Color(0.08, 0.09, 0.1)
const LABEL_SIZE: int = 14
## Şehir gelir rozeti.
const BADGE_COLOR: Color = Color(0.55, 0.85, 0.45)
const BADGE_SATURATED_COLOR: Color = Color(1.0, 0.6, 0.2)
## Bu gelirin (para/dk) altında rozet gösterilmez.
const INCOME_VISIBLE_MIN: float = 0.05
## Alet fiyat etiketi: yetiyorsa açık, yetmiyorsa kırmızı (görev 07, K2).
const TAG_COLOR: Color = Color(0.95, 0.95, 0.9)
const TAG_EXPENSIVE_COLOR: Color = Color(0.95, 0.4, 0.35)
## Alet seçiliyken kullanılamayan noktanın görünürlüğü.
const UNUSABLE_ALPHA: float = 0.3
## Adın, stok çubuğu yer alsın diye aşağı kayması.
const LABEL_DROP: float = 8.0
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
## Alet etiketi ("" yoksa), parası yetiyor mu, alet açıkken kullanılamaz mı.
var _tag: String = ""
var _tag_affordable: bool = true
var _unusable: bool = false
var _dimmed: bool = false


func _ready() -> void:
	z_as_relative = false
	z_index = POINT_Z_INDEX
	# Harita oyunda ölçeklenir (WorldMap'te RegionMap.scale); nokta, simge ve
	# yazılar yine aynı boyda kalsın. Konum ölçekle birlikte açılır.
	if not Engine.is_editor_hint():
		global_scale = Vector2.ONE


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
	_dimmed = value
	_apply_alpha()


## Seçili aletin bu noktadaki işareti: fiyat etiketi ya da "kullanılamaz" soluğu.
func set_tool_mark(tag: String, affordable: bool, unusable: bool) -> void:
	if tag != _tag or affordable != _tag_affordable or unusable != _unusable:
		_tag = tag
		_tag_affordable = affordable
		_unusable = unusable
		_apply_alpha()
		queue_redraw()


func _apply_alpha() -> void:
	var alpha: float = UNUSABLE_ALPHA if _unusable else (DIMMED_ALPHA if _dimmed else 1.0)
	modulate = Color(1.0, 1.0, 1.0, alpha)


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
			if view != null and view.data != null and slot_index < view.data.city_names.size():
				return view.data.city_names[slot_index]
			return "City"
		Kind.RESOURCE_SITE:
			if resource != null:
				return RawResource.site_name(resource.site_kind)
			return "Resource Site"
	return _factory_name if not _factory_name.is_empty() else "Factory"


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
				PointMarks.draw_badge(self, SIZE, "+%s/min" % RouteView.format_rate(_income),
						BADGE_SATURATED_COLOR if _saturated else BADGE_COLOR)
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
		Kind.FACTORY:
			# Fabrika: dolu kare + çatı.
			var rect: Rect2 = Rect2(Vector2(-SIZE, -SIZE), Vector2(SIZE, SIZE) * 2.0)
			draw_rect(rect.grow(2.0), FACTORY_COLOR)
			draw_rect(rect.grow(2.0), OUTLINE, false, 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-SIZE, -SIZE),
					Vector2(0.0, -SIZE - 8.0), Vector2(SIZE, -SIZE)]), FACTORY_COLOR.darkened(0.3))
			if _warning:
				PointMarks.draw_warning(self, Vector2(SIZE + 4.0, -SIZE - 4.0))

	if not _goods.is_empty():
		PointMarks.draw_goods(self, SIZE, _goods)
	if _stock_fill >= 0.0:
		PointMarks.draw_stock_bar(self, SIZE, _stock_fill)
	if not _tag.is_empty():
		PointMarks.draw_badge(self, SIZE, _tag, TAG_COLOR if _tag_affordable else TAG_EXPENSIVE_COLOR)
	_draw_label()


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = get_title()
	var width: float = 160.0
	var pos: Vector2 = Vector2(-width * 0.5, SIZE + 20.0 + (LABEL_DROP if _stock_fill >= 0.0 else 0.0))
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, 5, OUTLINE)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE, Color.WHITE)
