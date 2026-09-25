class_name GoodBar
extends Control

## Panellerde tek satırlık gösterge: mal simgeleri + (isteğe bağlı) doluluk
## çubuğu + kısa sayı metni. Ör. [LG] ▓▓▓░░ 32/50.
##
## Çubuğun bölgeleri (`zones`) verilirse arka plan bölgelere göre boyanır ve
## dolgu, ulaştığı bölgenin renginde çizilir (şehir talebi: tam / yarı / onda
## bir fiyat). Bölge yoksa dolgu yeşil, doluyken kırmızıdır. Yalnızca çizer.

const ROW_HEIGHT: float = 22.0
const MIN_WIDTH: float = 210.0
const ICON_SIZE: float = 18.0
const ICON_GAP: float = 3.0
const BAR_SIZE: Vector2 = Vector2(90.0, 9.0)
const GAP: float = 7.0
const FONT_SIZE: int = 13
const TEXT_COLOR: Color = Color(0.92, 0.92, 0.9)
const BAR_BACK: Color = Color(0.08, 0.09, 0.1, 0.85)
const BAR_OUTLINE: Color = Color(0.45, 0.47, 0.5)
const FILL_COLOR: Color = Color(0.55, 0.85, 0.45)
const FULL_COLOR: Color = Color(0.95, 0.3, 0.25)
const FULL_RATIO: float = 0.999
## Bölgelerin arka planda ne kadar görüneceği.
const ZONE_BACK_ALPHA: float = 0.25

var _goods: Array[Good] = []
var _fill: float = -1.0
var _text: String = ""
var _zones: PackedFloat32Array = PackedFloat32Array()
var _zone_colors: Array[Color] = []


func _ready() -> void:
	custom_minimum_size = Vector2(MIN_WIDTH, ROW_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `fill` < 0: çubuk yok (yalnızca simge + metin). `zones`: bölgelerin çubuk
## oranı olarak bitişleri (artan, sonuncusu 1.0); `zone_colors` aynı sırada.
func set_data(goods: Array[Good], fill: float, text: String,
		zones: PackedFloat32Array = PackedFloat32Array(), zone_colors: Array[Color] = []) -> void:
	if goods == _goods and is_equal_approx(fill, _fill) and text == _text and zones == _zones:
		return
	_goods = goods
	_fill = fill
	_text = text
	_zones = zones
	_zone_colors = zone_colors
	queue_redraw()


func _draw() -> void:
	var x: float = 0.0
	var mid: float = size.y * 0.5
	for good: Good in _goods:
		GoodIcon.draw(self, Vector2(x, mid - ICON_SIZE * 0.5), good, ICON_SIZE)
		x += ICON_SIZE + ICON_GAP
	if not _goods.is_empty():
		x += GAP - ICON_GAP
	if _fill >= 0.0:
		_draw_bar(Rect2(Vector2(x, mid - BAR_SIZE.y * 0.5), BAR_SIZE))
		x += BAR_SIZE.x + GAP
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(x, mid + (font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5),
			_text, HORIZONTAL_ALIGNMENT_LEFT, maxf(size.x - x, 0.0), FONT_SIZE, TEXT_COLOR)


func _draw_bar(back: Rect2) -> void:
	draw_rect(back, BAR_BACK)
	var fill: float = clampf(_fill, 0.0, 1.0)
	var fill_color: Color = FULL_COLOR if fill >= FULL_RATIO else FILL_COLOR
	var start: float = 0.0
	for i: int in _zones.size():
		var color: Color = _zone_colors[i] if i < _zone_colors.size() else FILL_COLOR
		var zone: Rect2 = Rect2(back.position + Vector2(back.size.x * start, 0.0),
				Vector2(back.size.x * (_zones[i] - start), back.size.y))
		draw_rect(zone, Color(color, ZONE_BACK_ALPHA))
		if fill > start:
			fill_color = color
		start = _zones[i]
	draw_rect(Rect2(back.position, Vector2(back.size.x * fill, back.size.y)), fill_color)
	draw_rect(back, BAR_OUTLINE, false, 1.0)
