class_name PaletteItem
extends Button

## Paletteki tek istasyon düğmesi.
##
## İki yolla blok eklenebilir: tıklama (tuvalin ortasına düşer) veya tuvale
## sürükleyip bırakma (bırakılan noktaya düşer) — ReactFlow'daki gibi.

var block_type: BlockType = null


func setup(type: BlockType) -> void:
	block_type = type
	text = "%s   %s" % [type.icon_char, type.display_name]
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_text = "%s\n%s" % [type.category_label(), type.description]
	custom_minimum_size = Vector2(0.0, 30.0)
	add_theme_font_size_override(&"font_size", 12)


## Godot sürükleme başlatınca çağırır. Taşınan yük: hangi arketip sürükleniyor.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if block_type == null:
		return null
	set_drag_preview(_build_preview())
	return {"block_type": block_type}


func _build_preview() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = block_type.accent_color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override(&"panel", style)

	var label := Label.new()
	label.text = "%s  %s" % [block_type.icon_char, block_type.display_name]
	label.add_theme_font_size_override(&"font_size", 12)
	label.add_theme_color_override(&"font_color", Color(0.08, 0.09, 0.11))
	panel.add_child(label)
	return panel
