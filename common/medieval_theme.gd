extends RefCounted

# Shared medieval palette for the entire game interface.
const INK := Color(0.13, 0.09, 0.06)
const PARCHMENT := Color(0.93, 0.83, 0.63)
const MUTED := Color(0.73, 0.62, 0.45)
const GOLD := Color(0.82, 0.63, 0.32)
const WOOD := Color(0.23, 0.16, 0.10)
const WOOD_LIGHT := Color(0.34, 0.24, 0.15)
const BORDER := Color(0.57, 0.40, 0.21)


static func _box(fill: Color, edge: Color, width: int = 1, radius: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 5.0
	box.content_margin_bottom = 5.0
	return box


static func build() -> Theme:
	var skin := Theme.new()
	skin.set_color(&"font_color", &"Label", PARCHMENT)
	skin.set_color(&"font_color", &"Button", PARCHMENT)
	skin.set_color(&"font_hover_color", &"Button", Color(1.0, 0.90, 0.69))
	skin.set_color(&"font_pressed_color", &"Button", INK)
	skin.set_color(&"font_disabled_color", &"Button", MUTED.darkened(0.28))
	skin.set_color(&"font_color", &"LineEdit", PARCHMENT)
	skin.set_color(&"font_placeholder_color", &"LineEdit", MUTED)
	skin.set_color(&"font_selected_color", &"LineEdit", INK)
	skin.set_color(&"font_color", &"GraphNode", PARCHMENT)
	skin.set_color(&"font_selected_color", &"GraphNode", Color(1.0, 0.92, 0.75))
	skin.set_stylebox(&"panel", &"PanelContainer", _box(WOOD, BORDER))
	skin.set_stylebox(&"panel", &"GraphEdit", _box(Color(0.15, 0.12, 0.09), BORDER, 0, 0))
	skin.set_stylebox(&"normal", &"Button", _box(WOOD_LIGHT, BORDER))
	skin.set_stylebox(&"hover", &"Button", _box(Color(0.43, 0.29, 0.16), GOLD, 2))
	skin.set_stylebox(&"pressed", &"Button", _box(GOLD, Color(0.96, 0.78, 0.47), 2))
	skin.set_stylebox(&"disabled", &"Button", _box(Color(0.23, 0.18, 0.13), Color(0.37, 0.30, 0.22)))
	skin.set_stylebox(&"focus", &"Button", _box(Color.TRANSPARENT, GOLD, 1))
	skin.set_stylebox(&"normal", &"LineEdit", _box(Color(0.16, 0.12, 0.08), BORDER))
	skin.set_stylebox(&"focus", &"LineEdit", _box(Color.TRANSPARENT, GOLD, 2))
	skin.set_stylebox(&"fill", &"ProgressBar", _box(GOLD, GOLD, 0, 1))
	skin.set_stylebox(&"background", &"ProgressBar", _box(Color(0.12, 0.10, 0.07), BORDER, 1, 1))
	skin.set_color(&"grid_major", &"GraphEdit", Color(0.37, 0.29, 0.19, 0.56))
	skin.set_color(&"grid_minor", &"GraphEdit", Color(0.26, 0.21, 0.15, 0.42))
	skin.set_color(&"activity", &"GraphEdit", GOLD)
	skin.set_color(&"connection_hover_tint_color", &"GraphEdit", Color(0.94, 0.81, 0.52))
	return skin
