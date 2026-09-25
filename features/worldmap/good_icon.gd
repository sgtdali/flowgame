class_name GoodIcon
extends RefCounted

## Malın simgesi: renkli küçük kare + iki harf (LG, LB...). Renk ve harfler
## malın verisinden (ItemType.color / icon_char) gelir; haritada, panellerde ve
## özet kutusunda aynı simge kullanılır.

const OUTLINE: Color = Color(0.08, 0.09, 0.1)
## Yazı rengi: açık zeminde koyu, koyu zeminde açık.
const DARK_TEXT: Color = Color(0.08, 0.09, 0.1)
const LIGHT_TEXT: Color = Color(0.97, 0.96, 0.92)
const LIGHTNESS_SPLIT: float = 0.6


## `canvas` üzerine, sol üst köşesi `top_left` olan `size` boyunda kare çizer.
static func draw(canvas: CanvasItem, top_left: Vector2, good: Good, size: float) -> void:
	var rect: Rect2 = Rect2(top_left, Vector2(size, size))
	canvas.draw_rect(rect, good.color)
	canvas.draw_rect(rect, OUTLINE, false, 1.5)
	var font_size: int = int(size * 0.55)
	var font: Font = ThemeDB.fallback_font
	var baseline: float = top_left.y + (size + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	canvas.draw_string(font, Vector2(top_left.x, baseline), good.icon_char,
			HORIZONTAL_ALIGNMENT_CENTER, size, font_size, text_color(good))


static func text_color(good: Good) -> Color:
	return DARK_TEXT if good.color.get_luminance() > LIGHTNESS_SPLIT else LIGHT_TEXT
