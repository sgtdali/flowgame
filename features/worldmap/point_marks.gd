class_name PointMarks
extends RefCounted

## Harita noktasının üstündeki durum işaretlerinin çizimi (MapPoint kullanır):
## rozet (şehir geliri, alet fiyat etiketi), fabrika uyarısı, stok çubuğu ve
## mal simgeleri. Yalnızca çizer; noktanın boyutu `point_size` ile gelir.

const OUTLINE: Color = Color(0.08, 0.09, 0.1)
const BADGE_FONT_SIZE: int = 13
const BADGE_PADDING: float = 4.0
## Rozetin noktanın üst kenarından yüksekliği.
const BADGE_RISE: float = 10.0
const WARNING_COLOR: Color = Color(1.0, 0.8, 0.2)
const WARNING_SIZE: float = 9.0
const STOCK_BAR_SIZE: Vector2 = Vector2(34.0, 5.0)
const STOCK_BAR_GAP: float = 5.0
const STOCK_BAR_BACK: Color = Color(0.08, 0.09, 0.1, 0.8)
const STOCK_BAR_FILL: Color = Color(0.55, 0.85, 0.45)
const STOCK_BAR_FULL: Color = Color(0.95, 0.3, 0.25)
## Bu doluluktan sonrası "dolu" sayılır (üretim durur).
const STOCK_FULL_RATIO: float = 0.999
const GOOD_ICON_SIZE: float = 16.0
const GOOD_ICON_GAP: float = 3.0


## Noktanın üstünde ortalı, dolgulu küçük kutu içinde yazı (ör. "+10/min", "+300").
static func draw_badge(canvas: CanvasItem, point_size: float, text: String, fill: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE)
	var box: Rect2 = Rect2(Vector2(-text_size.x * 0.5 - BADGE_PADDING, -point_size - BADGE_RISE - text_size.y),
			Vector2(text_size.x + BADGE_PADDING * 2.0, text_size.y + BADGE_PADDING))
	canvas.draw_rect(box, fill)
	canvas.draw_rect(box, OUTLINE, false, 1.5)
	canvas.draw_string(font, Vector2(box.position.x + BADGE_PADDING,
			box.end.y - BADGE_PADDING * 0.5 - font.get_descent(BADGE_FONT_SIZE)),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE, OUTLINE)


## Sarı üçgen içinde "!" — sorunlu fabrika.
static func draw_warning(canvas: CanvasItem, center: Vector2) -> void:
	var s: float = WARNING_SIZE
	var triangle: PackedVector2Array = [center + Vector2(0.0, -s), center + Vector2(s, s * 0.8),
			center + Vector2(-s, s * 0.8)]
	canvas.draw_colored_polygon(triangle, WARNING_COLOR)
	triangle.append(triangle[0])
	canvas.draw_polyline(triangle, OUTLINE, 2.0)
	canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-s, s * 0.6), "!",
			HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, int(s * 1.4), OUTLINE)


## Noktanın altında doluluk çubuğu; dolunca kırmızı.
static func draw_stock_bar(canvas: CanvasItem, point_size: float, fill_ratio: float) -> void:
	var back: Rect2 = Rect2(Vector2(-STOCK_BAR_SIZE.x * 0.5, point_size + STOCK_BAR_GAP), STOCK_BAR_SIZE)
	canvas.draw_rect(back, STOCK_BAR_BACK)
	var fill: float = clampf(fill_ratio, 0.0, 1.0)
	canvas.draw_rect(Rect2(back.position, Vector2(back.size.x * fill, back.size.y)),
			STOCK_BAR_FULL if fill >= STOCK_FULL_RATIO else STOCK_BAR_FILL)
	canvas.draw_rect(back, OUTLINE, false, 1.0)


## Noktanın sağında mal simgeleri.
static func draw_goods(canvas: CanvasItem, point_size: float, goods: Array[Good]) -> void:
	var x: float = point_size + 6.0
	for good: Good in goods:
		GoodIcon.draw(canvas, Vector2(x, -GOOD_ICON_SIZE * 0.5), good, GOOD_ICON_SIZE)
		x += GOOD_ICON_SIZE + GOOD_ICON_GAP
