extends PanelContainer
## Inventory window (I): everything the player carries, machines then products, with the
## quick-use bar's ten slots underneath. It shares the inventory with the bottom bar; the
## player pins items to quick use by dragging them onto a slot, right clicking them, or
## pressing a slot's number (1-9, 0) while hovering them. Clicking a machine places it.
## I or Esc closes it.

signal machine_requested(kind: String)
signal pin_requested(key: String, slot: int)
signal unpin_requested(slot: int)

const CraftScreen = preload("res://app/craft_screen.gd")
const InventorySlot = preload("res://app/inventory_slot.gd")
const INK := Color("e8e4dc")
const MUTED := Color("8d949b")
const PANEL := Color("16191c")
const COLUMNS := 14
const SLOT := 48

## Inventory key -> slot in the window's grids
var items: Dictionary = {}
## The window's copy of the quick-use bar, index 0-9.
var quick_slots: Array[InventorySlot] = []
var _sim: RefCounted
var _keys: Array = []
var _hover := ""
var _machines: GridContainer
var _products: GridContainer
var _machines_title: Label
var _products_title: Label
var _empty: Label

func _box(background: Color, border: Color, width: int = 1, pad: int = 12, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func build(sim: RefCounted) -> void:
	_sim = sim
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _box(Color(0.02, 0.03, 0.04, 0.55), Color.TRANSPARENT, 0, 0, 0))
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var frame := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = CraftScreen.FRAME
	style.set_texture_margin_all(16)
	style.set_content_margin_all(6)
	frame.add_theme_stylebox_override("panel", style)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label("Envanter", 18, INK))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var hint := _label("Tıkla: makineyi yerleştir · Sürükle, sağ tıkla ya da üstündeyken 1-0: hızlı erişime sabitle", 11, MUTED)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hint)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, Color("2c3238"), 1, 8))
	box.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * SLOT + (COLUMNS - 1) * 4 + 2, 300)
	panel.add_child(scroll)
	var lists := VBoxContainer.new()
	lists.add_theme_constant_override("separation", 6)
	scroll.add_child(lists)
	_machines_title = _label("Makineler", 12, MUTED)
	lists.add_child(_machines_title)
	_machines = _grid()
	lists.add_child(_machines)
	_products_title = _label("Ürünler", 12, MUTED)
	lists.add_child(_products_title)
	_products = _grid()
	lists.add_child(_products)
	_empty = _label("Envanter boş.", 12, MUTED)
	lists.add_child(_empty)
	box.add_child(_label("Hızlı erişim (alt çubuk)", 13, INK))
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	box.add_child(quick)
	for i in range(10):
		var slot := InventorySlot.new(SLOT)
		slot.show_number(i)
		slot.on_drop = func(index: int, key: String) -> void: pin_requested.emit(key, index)
		slot.pressed.connect(func() -> void: _place(slot.key))
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not slot.key.is_empty():
				unpin_requested.emit(i)
				accept_event())
		slot.mouse_entered.connect(func() -> void: _hover = slot.key)
		slot.mouse_exited.connect(func() -> void: _hover = "")
		quick.add_child(slot)
		quick_slots.append(slot)

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	return grid

func toggle() -> void:
	visible = not visible
	_hover = ""
	if visible:
		refresh(_sim)

func refresh(sim: RefCounted) -> void:
	_sim = sim
	if not visible:
		return
	var keys: Array = sim.carried_keys()
	if keys != _keys:
		_rebuild(keys)
	for key in items:
		var slot: InventorySlot = items[key]
		slot.pinned = key in sim.hotbar
		slot.set_item(sim, key)
		slot.disabled = key.begins_with("machine:") and not sim.can_place(key.trim_prefix("machine:"))
	for i in range(quick_slots.size()):
		quick_slots[i].set_item(sim, sim.hotbar[i])

func _rebuild(keys: Array) -> void:
	_keys = keys
	items.clear()
	for grid in [_machines, _products]:
		for child in grid.get_children():
			child.queue_free()
	var machine_count := 0
	for key in keys:
		var slot := InventorySlot.new(SLOT)
		slot.set_item(_sim, str(key))
		slot.pressed.connect(func() -> void: _place(slot.key))
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				_toggle_pin(slot.key)
				accept_event())
		slot.mouse_entered.connect(func() -> void: _hover = slot.key)
		slot.mouse_exited.connect(func() -> void: _hover = "")
		if str(key).begins_with("machine:"):
			_machines.add_child(slot)
			machine_count += 1
		else:
			_products.add_child(slot)
		items[key] = slot
	_machines_title.visible = machine_count > 0
	_machines.visible = machine_count > 0
	_products_title.visible = keys.size() > machine_count
	_products.visible = keys.size() > machine_count
	_empty.visible = keys.is_empty()

func _toggle_pin(key: String) -> void:
	var index: int = _sim.hotbar.find(key)
	if index >= 0:
		unpin_requested.emit(index)
	else:
		pin_requested.emit(key, -1)

func _place(key: String) -> void:
	if key.begins_with("machine:") and _sim.can_place(key.trim_prefix("machine:")):
		hide()
		machine_requested.emit(key.trim_prefix("machine:"))

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not visible:
		return
	if key.keycode == KEY_I or key.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
		return
	var index := -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9:
		index = key.keycode - KEY_1
	elif key.keycode == KEY_0:
		index = 9
	if index >= 0:
		if not _hover.is_empty():
			pin_requested.emit(_hover, index)
		get_viewport().set_input_as_handled()
