class_name CursorTag
extends Label

## İmlecin yanında duran küçük yazı: Factory aleti seçiliyken fabrikanın fiyatı
## ("Build 300"; para yetmiyorsa kırmızı) ya da oraya neden kurulamadığı (gri).
## Yalnızca gösterir; metni MapTools verir.

const CURSOR_OFFSET: Vector2 = Vector2(18.0, 14.0)
const FONT_SIZE: int = 15
const OK_COLOR: Color = Color(1.0, 0.95, 0.6)
const EXPENSIVE_COLOR: Color = Color(1.0, 0.45, 0.4)
const BLOCKED_COLOR: Color = Color(0.75, 0.77, 0.78)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override(&"font_size", FONT_SIZE)
	add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0))
	add_theme_constant_override(&"outline_size", 5)
	hide()


## `tag`: MapTools.cursor_tag sonucu ({text, state}); metin boşsa gizlenir.
func show_for(tag: Dictionary, mouse_position: Vector2) -> void:
	var text: String = tag.get("text", "")
	if text.is_empty():
		hide()
		return
	self.text = text
	var color: Color = BLOCKED_COLOR
	match tag.get("state", MapTools.TagState.BLOCKED):
		MapTools.TagState.OK:
			color = OK_COLOR
		MapTools.TagState.EXPENSIVE:
			color = EXPENSIVE_COLOR
	add_theme_color_override(&"font_color", color)
	position = mouse_position + CURSOR_OFFSET
	show()
