extends PanelContainer
## Recipe screen for "choose" machines (same inputs, different products). A grid of product
## slots; hovering one shows its recipe as icons (inputs → output, time) under the grid.

signal recipe_selected(id: String, recipe_id: String)

const Icons = preload("res://app/icons.gd")
const INK := Color("3d3a33")
const MUTED := Color("7a7466")
const TEAL := Color("4f9a8a")

var target_id := ""
var tiles: Dictionary = {}
var _sim: RefCounted
var _title: Label
var _grid: GridContainer
var _preview: HBoxContainer

func _box(background: Color, border: Color, width: int = 1, pad: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(pad)
	return style

func build() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _box(Color(0.24, 0.2, 0.14, 0.22), Color.TRANSPARENT, 0, 0))
	# Clicking the dimmed backdrop closes the screen.
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var dialog := PanelContainer.new()
	dialog.add_theme_stylebox_override("panel", _box(Color("f6f2ea"), Color("b9ae97"), 2, 14))
	center.add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	dialog.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	_title.theme_type_variation = "Heading"
	_title.add_theme_color_override("font_color", INK)
	box.add_child(_title)
	var grid_panel := PanelContainer.new()
	grid_panel.add_theme_stylebox_override("panel", _box(Color("e2dacb"), Color("cfc6b3"), 1, 6))
	box.add_child(grid_panel)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	grid_panel.add_child(_grid)
	_preview = HBoxContainer.new()
	_preview.add_theme_constant_override("separation", 6)
	_preview.custom_minimum_size.y = 40
	box.add_child(_preview)

func show_machine(sim: RefCounted, id: String) -> void:
	_sim = sim
	target_id = id
	tiles.clear()
	for child in _grid.get_children():
		child.queue_free()
	var machine: Dictionary = sim.machines[id]
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	_title.text = str(spec.name)
	for r_var in spec.get("recipes", [spec.recipe]):
		var r_id := str(r_var)
		var recipe: Dictionary = sim.catalog.recipes[r_id]
		var unlocked: bool = sim.is_recipe_unlocked(r_id)
		var current := r_id == str(machine.recipe)
		var product := str(recipe.outputs.keys()[0])
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(48, 48)
		tile.disabled = not unlocked
		tile.tooltip_text = str(recipe.get("name", r_id)) if unlocked else "Locked: %s" % sim.unlock_tech_for_recipe(r_id)
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
		for state in ["normal", "disabled", "focus"]:
			tile.add_theme_stylebox_override(state, _box(Color("f3e6cc") if current else Color("ece6da"), Color("b98330") if current else Color("cfc6b3"), 2 if current else 1, 4))
		tile.add_theme_stylebox_override("hover", _box(Color("e8dfcc"), TEAL, 2, 4))
		tile.add_theme_stylebox_override("pressed", _box(Color("ddd2bb"), TEAL, 2, 4))
		tile.modulate.a = 1.0 if unlocked else 0.4
		var slot := Icons.Slot.new(Icons.product(sim, product), int(recipe.outputs[product]))
		slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.add_child(slot)
		tile.mouse_entered.connect(_show_recipe.bind(r_id))
		tile.mouse_exited.connect(func() -> void: _show_recipe(str(_sim.machines[target_id].recipe)))
		tile.pressed.connect(func() -> void:
			hide()
			recipe_selected.emit(id, r_id))
		_grid.add_child(tile)
		tiles[r_id] = tile
	_grid.columns = clampi(tiles.size(), 2, 6)
	_show_recipe(str(machine.recipe))
	visible = true

## Recipe as icons: inputs with counts, an arrow, the outputs, then the cycle time.
func _show_recipe(r_id: String) -> void:
	if not _sim.machines.has(target_id):
		return
	for child in _preview.get_children():
		child.queue_free()
	var recipe: Dictionary = _sim.catalog.recipes[r_id]
	for product in recipe.inputs:
		_preview.add_child(Icons.Slot.new(Icons.product(_sim, str(product)), int(recipe.inputs[product])))
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", MUTED)
	_preview.add_child(arrow)
	for product in recipe.outputs:
		_preview.add_child(Icons.Slot.new(Icons.product(_sim, str(product)), int(recipe.outputs[product])))
	var time := Label.new()
	time.text = "  %.1f s" % (float(recipe.work) / _sim.effective_speed(target_id))
	time.add_theme_font_size_override("font_size", 12)
	time.add_theme_color_override("font_color", MUTED)
	_preview.add_child(time)
	for child in _preview.get_children():
		if child is Label:
			child.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
