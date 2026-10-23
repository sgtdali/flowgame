extends VBoxContainer
## Bottom quick-use bar: the hammer opens the craft screen, the crate opens the inventory
## window, then ten fixed slots the player pins items to. Slots share the inventory's counts
## and stay put when empty. Clicking a machine (or pressing its number, 1-9 then 0) places
## it; right click unpins; dropping an item from the inventory window pins it there.
## The hand-craft queue sits above it; clicking a queued job cancels it and returns its materials.

signal machine_requested(kind: String)
signal craft_screen_requested()
signal inventory_requested()
signal craft_cancelled(index: int)
signal pin_requested(key: String, slot: int)
signal unpin_requested(slot: int)

const Icons = preload("res://app/icons.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const CraftScreen = preload("res://app/craft_screen.gd")
const InventorySlot = preload("res://app/inventory_slot.gd")
const TEAL := Color("61d8bb")
const INVENTORY_ICON := 6

var craft_button: Button
var inventory_button: Button
## Quick-use slots, index 0-9 (keys 1-9, 0).
var slots: Array[InventorySlot] = []
var queue_slots: Array[Button] = []
## Returns true while another window owns the number keys (craft screen, inventory...).
var is_blocked: Callable
var _queue_row: HBoxContainer
var _queue_keys: Array = []

func _box(background: Color, border: Color, pad: int, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

func _style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(Color("12222e"), Color("294356"), 4))
	button.add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("295258"), TEAL, 4))
	button.add_theme_stylebox_override("disabled", _box(Color("0d1a24"), Color("1c3142"), 4))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _icon_button(icon_index: int, tip: String) -> Button:
	var button := Button.new()
	button.icon = CraftScreen.icon(icon_index)
	button.expand_icon = true
	button.custom_minimum_size = Vector2(44, 44)
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.tooltip_text = tip
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style(button)
	return button

func build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 6)
	_queue_row = HBoxContainer.new()
	_queue_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_queue_row.add_theme_constant_override("separation", 4)
	_queue_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_queue_row)
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("panel", _box(Color("0d1a24e6"), Color("1c3142"), 6, 8))
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	bar.add_child(row)
	craft_button = _icon_button(CraftScreen.CRAFT_ICON, "Üret (C)")
	craft_button.pressed.connect(func() -> void: craft_screen_requested.emit())
	row.add_child(craft_button)
	inventory_button = _icon_button(INVENTORY_ICON, "Envanter (I)")
	inventory_button.pressed.connect(func() -> void: inventory_requested.emit())
	row.add_child(inventory_button)
	row.add_child(VSeparator.new())
	for i in range(10):
		var slot := InventorySlot.new()
		slot.show_number(i)
		slot.on_drop = func(index: int, key: String) -> void: pin_requested.emit(key, index)
		slot.pressed.connect(_use.bind(i))
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not slot.key.is_empty():
				unpin_requested.emit(i)
				accept_event())
		row.add_child(slot)
		slots.append(slot)

## Quick-use slot holding `key`, or null when it is not pinned.
func slot_for(key: String) -> InventorySlot:
	for slot in slots:
		if slot.key == key:
			return slot
	return null

func _use(index: int) -> void:
	var key := slots[index].key
	if key.begins_with("machine:") and not slots[index].disabled:
		machine_requested.emit(key.trim_prefix("machine:"))

func refresh(sim: RefCounted) -> void:
	for i in range(slots.size()):
		var key: String = sim.hotbar[i]
		slots[i].set_item(sim, key)
		slots[i].disabled = key.begins_with("machine:") and not sim.can_place(key.trim_prefix("machine:"))
	_refresh_queue(sim)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or (is_blocked.is_valid() and is_blocked.call()):
		return
	var index := -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9:
		index = key.keycode - KEY_1
	elif key.keycode == KEY_0:
		index = 9
	elif key.keycode == KEY_I:
		inventory_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if index >= 0:
		_use(index)
		get_viewport().set_input_as_handled()

func _refresh_queue(sim: RefCounted) -> void:
	var keys: Array = []
	for job in sim.craft_queue:
		keys.append("%s:%s" % [job.type, job.id])
	if keys != _queue_keys:
		_queue_keys = keys
		queue_slots.clear()
		for child in _queue_row.get_children():
			child.queue_free()
		for i in range(sim.craft_queue.size()):
			var job: Dictionary = sim.craft_queue[i]
			var button := Button.new()
			button.custom_minimum_size = Vector2(40, 40)
			_style(button)
			var slot: Icons.Slot
			if job.type == "machine":
				slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(str(job.id))), 1)
				slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			else:
				var outputs: Dictionary = sim.catalog.recipes[job.id].outputs
				var product := str(outputs.keys()[0])
				slot = Icons.Slot.new(Icons.product(sim, product), int(outputs[product]))
			slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			button.add_child(slot)
			var bar := ProgressBar.new()
			bar.name = "Progress"
			bar.show_percentage = false
			bar.max_value = 1.0
			bar.step = 0.0
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			bar.offset_top = -5
			bar.offset_left = 3
			bar.offset_right = -3
			bar.offset_bottom = -2
			button.add_child(bar)
			button.tooltip_text = "Tıkla: iptal et"
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.pressed.connect(func() -> void: craft_cancelled.emit(i))
			_queue_row.add_child(button)
			queue_slots.append(button)
	for i in range(queue_slots.size()):
		var job: Dictionary = sim.craft_queue[i]
		var bar: ProgressBar = queue_slots[i].get_node("Progress")
		bar.value = 1.0 - float(job.remaining) / sim.craft_work(str(job.type), str(job.id))
