extends GraphNode
## Tower-furnace artwork with recipe-aware, real GraphEdit ports.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)

const FRAME_SIZE := Vector2(288, 288)
const TEAL := Color("70d6b2")
const GOLD := Color("efb65a")
const MUTED := Color("7f99aa")
var card_id := ""
var is_working := false
var animation_active := false
var animation_frame := 0
var animation_elapsed := 0.0
var animation_scale := 1.0
var simulation_paused := false
var status_color := MUTED
var rate_label: Label
var stock_label: Label
var pause_btn: Button
var input_labels: Array[Label] = []
var input_colors: Array[Color] = []
var output_color := MUTED
var _sheet: Texture2D
var _built := false

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	if _built:
		return
	_built = true
	custom_minimum_size = FRAME_SIZE
	title = ""
	get_titlebar_hbox().hide()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("separation", 0)
	for key in ["panel", "panel_selected", "titlebar", "titlebar_selected"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var row_names := ["TopClearance", "MaterialInput", "FuelInput", "MetalOutput", "BottomClearance"]
	var row_heights := [86.0, 48.0, 48.0, 16.0, 90.0]
	for i in range(row_names.size()):
		var row := Control.new()
		row.name = row_names[i]
		row.custom_minimum_size = Vector2(288, row_heights[i])
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
	var overlay := Control.new()
	overlay.name = "LiveControls"
	overlay.position = Vector2(0, -86)
	overlay.size = FRAME_SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("MaterialInput").add_child(overlay)
	rate_label = _label_at(overlay, Vector2(176, 255), Vector2(47, 21), 12)
	stock_label = _label_at(overlay, Vector2(248, 207), Vector2(40, 18), 10)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for y in [127.0, 175.0]:
		var label := _label_at(overlay, Vector2(0, y), Vector2(39, 16), 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_labels.append(label)
	pause_btn = Button.new()
	pause_btn.position = Vector2(201, 88)
	pause_btn.size = Vector2(15, 18)
	pause_btn.add_theme_font_size_override("font_size", 12)
	pause_btn.add_theme_color_override("font_color", Color("d2dcd4"))
	for key in ["normal", "hover", "pressed", "focus"]:
		pause_btn.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(func() -> void: toggle_pressed.emit(card_id))
	overlay.add_child(pause_btn)
	_sheet = load("res://app/art/smelter_a/smelter_sheet.png")
	queue_redraw()

func _label_at(parent: Node, pos: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d2dcd4"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func setup_from_sim(sim: RefCounted, id: String) -> void:
	_build_visual()
	card_id = id
	name = id
	clear_all_slots()
	var inputs: Array = sim.input_products(id)
	for i in range(inputs.size()):
		var product := str(inputs[i])
		set_slot(i + 1, true, int(sim.product_port_type(product)), Color(sim.catalog.products[product].color), false, 0, Color.WHITE)
	var product: String = sim.output_product(id)
	set_slot(3, false, 0, Color.WHITE, true, int(sim.product_port_type(product)), Color(sim.catalog.products[product].color))
	update_from_sim(sim, id)

func update_from_sim(sim: RefCounted, id: String) -> void:
	if not sim.machines.has(id):
		return
	var machine: Dictionary = sim.machines[id]
	var recipe: Dictionary = sim.recipe_for(id)
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	var product: String = sim.output_product(id)
	var seconds := float(recipe.work) / float(machine.speed)
	rate_label.text = "%.0f/dk" % (int(recipe.outputs.get(product, 1)) * 60.0 / seconds)
	var stock := int(machine.output.get(product, 0))
	var capacity := int(spec.output_capacity)
	stock_label.text = "%d/%d" % [stock, capacity]
	stock_label.add_theme_color_override("font_color", GOLD if stock >= capacity else MUTED)
	output_color = Color(sim.catalog.products[product].color)
	input_colors.clear()
	var inputs: Array = sim.input_products(id)
	var details := PackedStringArray([str(spec.name), str(recipe.name), str(machine.status)])
	for i in range(input_labels.size()):
		if i < inputs.size():
			var input := str(inputs[i])
			input_colors.append(Color(sim.catalog.products[input].color))
			var count := int(machine.input.get(input, 0))
			input_labels[i].text = "%d/%d" % [count, int(spec.input_capacity)]
			details.append("%s: %d/%d" % [sim.catalog.products[input].name, count, int(spec.input_capacity)])
		else:
			input_labels[i].text = ""
	details.append("%s: %d/%d · %s" % [sim.catalog.products[product].name, stock, capacity, rate_label.text])
	tooltip_text = "\n".join(details)
	is_working = bool(machine.running)
	animation_active = is_working and not simulation_paused
	status_color = TEAL if animation_active else (MUTED if simulation_paused or not machine.enabled else GOLD)
	pause_btn.text = "Ⅱ" if machine.enabled else "▶"
	pause_btn.tooltip_text = "Durdur" if machine.enabled else "Çalıştır"
	queue_redraw()

func set_simulation_playback(paused: bool, speed: float) -> void:
	simulation_paused = paused
	animation_scale = speed
	animation_active = is_working and not paused

func _process(delta: float) -> void:
	if not animation_active:
		return
	animation_elapsed += delta * animation_scale
	if animation_elapsed >= 0.1:
		animation_frame = (animation_frame + int(animation_elapsed / 0.1)) % 12
		animation_elapsed = fmod(animation_elapsed, 0.1)
		queue_redraw()

func _draw_material_icon(center: Vector2, color: Color, ingot: bool = false) -> void:
	var shape := PackedVector2Array([Vector2(-6, 0), Vector2(-2, -6), Vector2(6, -3), Vector2(6, 3), Vector2(-2, 6)])
	if ingot:
		shape = PackedVector2Array([Vector2(-7, 1), Vector2(-2, -5), Vector2(7, -5), Vector2(4, 4), Vector2(-5, 5)])
	for i in range(shape.size()):
		shape[i] += center
	draw_colored_polygon(shape, color)
	draw_line(center + Vector2(-3, -3), center + Vector2(2, -4), color.lightened(0.4))

func _draw() -> void:
	if _sheet == null:
		return
	draw_set_transform(Vector2(0, get_node("TopClearance").position.y))
	var source := Rect2(Vector2(animation_frame % 4, floori(animation_frame / 4.0)) * FRAME_SIZE, FRAME_SIZE)
	draw_texture_rect_region(_sheet, Rect2(Vector2.ZERO, FRAME_SIZE), source)
	for i in range(2):
		var center := Vector2(16, 110 + i * 48)
		if i < input_colors.size():
			_draw_material_icon(center, input_colors[i])
		else:
			draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), MUTED, 2)
	_draw_material_icon(Vector2(270, 190), output_color, true)
	draw_circle(Vector2(86, 265), 4, status_color)
	if selected:
		draw_rect(Rect2(72, 18, 160, 266), Color(0.44, 0.84, 0.70, 0.85), false, 1)
