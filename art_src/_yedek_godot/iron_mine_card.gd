extends GraphNode
## Animated iron mine skin. Production and connection rules stay in the simulator.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)

const SHEET_PATH := "res://app/art/iron_mine_b/iron_mine_sheet.png"
const FRAME_SIZE := Vector2(288, 256)
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
var rate_label: Label
var stock_label: Label
var pause_btn: Button
var status_color := MUTED
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
	for style_name in ["panel", "panel_selected", "titlebar", "titlebar_selected"]:
		add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	var spacer := Control.new()
	spacer.name = "TopClearance"
	spacer.custom_minimum_size = Vector2(288, 42)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)
	var surface := Control.new()
	surface.name = "OutputAnchor"
	surface.custom_minimum_size = Vector2(288, 214)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	# Slot 1 is centered at y = 42 + 214/2 = 149, matching the socket.
	var overlay := Control.new()
	overlay.name = "LiveControls"
	overlay.position = Vector2(0, -42)
	overlay.size = FRAME_SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(overlay)
	rate_label = Label.new()
	rate_label.position = Vector2(138, 211)
	rate_label.size = Vector2(63, 20)
	rate_label.add_theme_font_size_override("font_size", 12)
	rate_label.add_theme_color_override("font_color", Color("d2dcd4"))
	rate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(rate_label)
	stock_label = Label.new()
	stock_label.position = Vector2(248, 166)
	stock_label.size = Vector2(40, 18)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_label.add_theme_font_size_override("font_size", 10)
	stock_label.add_theme_color_override("font_color", MUTED)
	stock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(stock_label)
	pause_btn = Button.new()
	pause_btn.position = Vector2(195, 66)
	pause_btn.size = Vector2(19, 20)
	pause_btn.add_theme_font_size_override("font_size", 12)
	pause_btn.add_theme_color_override("font_color", Color("d2dcd4"))
	for style_name in ["normal", "pressed", "hover", "focus"]:
		pause_btn.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(func() -> void: toggle_pressed.emit(card_id))
	overlay.add_child(pause_btn)
	_sheet = load(SHEET_PATH)
	queue_redraw()

func setup_from_sim(sim: RefCounted, id: String) -> void:
	_build_visual()
	card_id = id
	name = id
	var product: String = sim.output_product(id)
	var port_type := int(sim.product_port_type(product))
	var port_color := Color(sim.catalog.products[product].color)
	set_slot(1, false, 0, Color.WHITE, true, port_type, port_color)
	update_from_sim(sim, id)

func update_from_sim(sim: RefCounted, id: String) -> void:
	if not sim.machines.has(id):
		return
	var machine: Dictionary = sim.machines[id]
	var recipe: Dictionary = sim.recipe_for(id)
	var product: String = sim.output_product(id)
	var seconds := float(recipe.work) / float(machine.speed)
	var output_count := int(recipe.outputs.get(product, 1))
	rate_label.text = "%.0f/dk" % (output_count * 60.0 / seconds)
	var stock := int(machine.output.get(product, 0))
	var capacity := int(sim.catalog.machines[machine.kind].output_capacity)
	stock_label.text = "%d/%d" % [stock, capacity]
	is_working = bool(machine.running)
	animation_active = is_working and not simulation_paused
	status_color = TEAL if animation_active else (MUTED if simulation_paused or not machine.enabled else GOLD)
	pause_btn.text = "Ⅱ" if machine.enabled else "▶"
	pause_btn.tooltip_text = "Durdur" if machine.enabled else "Çalıştır"
	tooltip_text = "%s\n%s\n%s: %d/%d\n%.1f sn · %s" % [
		sim.catalog.machines[machine.kind].name,
		"Oyun duraklatıldı" if simulation_paused else str(machine.status),
		sim.catalog.products[product].name, stock, capacity, seconds, rate_label.text]
	stock_label.add_theme_color_override("font_color", GOLD if stock >= capacity else MUTED)
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
		var advance := int(animation_elapsed / 0.1)
		animation_elapsed = fmod(animation_elapsed, 0.1)
		animation_frame = (animation_frame + advance) % 12
		queue_redraw()

func _draw() -> void:
	if _sheet == null:
		return
	var source := Rect2(Vector2(animation_frame % 4, floori(animation_frame / 4.0)) * FRAME_SIZE, FRAME_SIZE)
	draw_texture_rect_region(_sheet, Rect2(Vector2.ZERO, FRAME_SIZE), source)
	# Live state replaces the painted concept indicator.
	draw_circle(Vector2(55, 219), 4.0, status_color)
	if selected:
		draw_rect(Rect2(25, 26, 207, 215), Color(0.44, 0.84, 0.70, 0.85), false, 1.0)
