extends Button
## One inventory slot, shared by the quick-use bar and the inventory window. Shows a carried
## machine or product with its count; can be dragged, and a quick-use slot (hotbar_index >= 0)
## accepts a dropped item, which pins it there.

const Icons = preload("res://app/icons.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const TEAL := Color("61d8bb")
const AMBER := Color("f2a33a")
const MUTED := Color("8ca5b6")

## Called with (hotbar_index, dropped key) when an item is dropped on a quick-use slot.
var on_drop: Callable
## "machine:<kind>", "product:<id>" or "" for an empty quick-use slot.
var key := ""
var hotbar_index := -1
## Inventory window: drawn with a small marker when the item is on the quick-use bar.
var pinned := false
var _slot: Icons.Slot
var _number: Label

func _init(size_px: int = 44) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	focus_mode = Control.FOCUS_NONE
	_style()
	_slot = Icons.Slot.new(null, 0)
	_slot.show_one = true
	_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_slot)

func _box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(4)
	return style

func _style() -> void:
	add_theme_stylebox_override("normal", _box(Color("12222e"), Color("294356")))
	add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL))
	add_theme_stylebox_override("pressed", _box(Color("295258"), TEAL))
	add_theme_stylebox_override("disabled", _box(Color("0d1a24"), Color("1c3142")))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

## Number key shown in the corner of a quick-use slot (1-9, then 0).
func show_number(index: int) -> void:
	hotbar_index = index
	_number = Label.new()
	_number.text = str((index + 1) % 10)
	_number.add_theme_font_size_override("font_size", 10)
	_number.add_theme_color_override("font_color", MUTED)
	_number.position = Vector2(4, 1)
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_number)

func set_item(sim: RefCounted, new_key: String) -> void:
	if new_key != key or _slot.texture == null and not new_key.is_empty():
		key = new_key
		var parts := key.split(":")
		if key.is_empty():
			_slot.texture = null
		elif parts[0] == "machine":
			_slot.texture = Icons.machine(SpriteMachineCard.art_path(parts[1]))
			_slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		else:
			_slot.texture = Icons.product(sim, parts[1])
			_slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var count: int = sim.carried_count(key) if not key.is_empty() else 0
	_slot.count = count
	_slot.show_one = not key.is_empty()
	_slot.modulate.a = 1.0 if count > 0 else 0.35
	if key.is_empty():
		tooltip_text = "Boş yuva: envanterden (I) bir öğe sürükle"
	else:
		var parts := key.split(":")
		tooltip_text = str(sim.catalog.machines[parts[1]].name) if parts[0] == "machine" else sim.product_name(parts[1])
		if parts[0] == "machine":
			tooltip_text += "\nTıkla: yerleştir"
		tooltip_text += "\nSağ tık: hızlı erişimden çıkar" if hotbar_index >= 0 else ("\nSağ tık: hızlı erişimden çıkar" if pinned else "\nSağ tık ya da sürükle: hızlı erişime sabitle")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if key.begins_with("machine:") and count > 0 else Control.CURSOR_ARROW
	_slot.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if pinned and hotbar_index < 0:
		draw_rect(Rect2(size.x - 9, 3, 6, 6), AMBER)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if key.is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture = _slot.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(32, 32)
	preview.texture_filter = _slot.texture_filter
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	return {"inventory_key": key}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return hotbar_index >= 0 and data is Dictionary and data.has("inventory_key")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if on_drop.is_valid():
		on_drop.call(hotbar_index, str(data.inventory_key))
