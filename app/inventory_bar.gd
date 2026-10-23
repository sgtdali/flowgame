extends VBoxContainer
## Bottom inventory: the hammer opens the craft screen, then one slot per carried machine
## (click to place it) and per carried product. The hand-craft queue sits above it; clicking
## a queued job cancels it and returns its materials.

signal machine_requested(kind: String)
signal craft_screen_requested()
signal craft_cancelled(index: int)

const Icons = preload("res://app/icons.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const CraftScreen = preload("res://app/craft_screen.gd")
const TEAL := Color("61d8bb")
const COLUMNS := 16

var craft_button: Button
## "machine:<kind>" or "product:<id>" -> slot button
var slots: Dictionary = {}
var queue_slots: Array[Button] = []
var _grid: GridContainer
var _queue_row: HBoxContainer
var _keys: Array = []
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
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	craft_button = Button.new()
	craft_button.icon = CraftScreen.icon(CraftScreen.CRAFT_ICON)
	craft_button.expand_icon = true
	craft_button.custom_minimum_size = Vector2(44, 44)
	craft_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	craft_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	craft_button.tooltip_text = "Üret (C)"
	craft_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	craft_button.pressed.connect(func() -> void: craft_screen_requested.emit())
	_style(craft_button)
	row.add_child(craft_button)
	row.add_child(VSeparator.new())
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	row.add_child(_grid)

func refresh(sim: RefCounted) -> void:
	var keys: Array = []
	for kind in sim.catalog.machines:
		if int(sim.machine_inventory.get(kind, 0)) > 0:
			keys.append("machine:" + str(kind))
	for product in sim.catalog.products:
		if int(sim.inventory.get(product, 0)) > 0:
			keys.append("product:" + str(product))
	if keys != _keys:
		_rebuild(sim, keys)
	for key in slots:
		var parts: PackedStringArray = str(key).split(":")
		var slot: Icons.Slot = slots[key].get_child(0)
		if parts[0] == "machine":
			slot.count = int(sim.machine_inventory.get(parts[1], 0))
			var placeable: bool = sim.can_place(parts[1])
			slots[key].disabled = not placeable
			slots[key].modulate.a = 1.0 if placeable else 0.5
		else:
			slot.count = int(sim.inventory.get(parts[1], 0))
		slot.queue_redraw()
	_refresh_queue(sim)

func _rebuild(sim: RefCounted, keys: Array) -> void:
	_keys = keys
	slots.clear()
	for child in _grid.get_children():
		child.queue_free()
	for key in keys:
		var parts: PackedStringArray = str(key).split(":")
		var button := Button.new()
		button.custom_minimum_size = Vector2(44, 44)
		_style(button)
		var slot: Icons.Slot
		if parts[0] == "machine":
			slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(parts[1])), 1)
			slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			button.tooltip_text = "%s\nTıkla: yerleştir" % sim.catalog.machines[parts[1]].name
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.pressed.connect(func() -> void: machine_requested.emit(parts[1]))
		else:
			slot = Icons.Slot.new(Icons.product(sim, parts[1]), 1)
			button.tooltip_text = sim.product_name(parts[1])
		slot.show_one = true
		slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(slot)
		_grid.add_child(button)
		slots[key] = button
	_grid.columns = clampi(keys.size(), 1, COLUMNS)

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
