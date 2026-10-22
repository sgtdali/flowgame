extends GraphNode
## Standard illustrated machine card (art_src/STANDART.md): inputs left, 128x128 animated
## artwork centre, outputs right, cycle bar below. Nothing is drawn outside the card.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)

## kind -> 512x384 sheet (4x3 frames of 128x128). Add a line here for each new machine.
const SHEETS := {
	"iron_mine": "res://app/art/iron_mine_b/iron_mine_sheet.png",
	"smelter": "res://app/art/smelter_a/smelter_sheet.png",
}
const ART := 128.0
const SIDE := 64.0
const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")

## One port column cell: product icon plus a small buffer gauge.
class PortGauge extends Control:
	var mirrored := false
	var color := Color.WHITE
	var count := 0
	var capacity := 1
	var ingot := false

	func _draw() -> void:
		var cy := size.y * 0.5
		var icon_x := size.x - 18.0 if mirrored else 18.0
		var bar := Rect2(8.0 if mirrored else 30.0, cy - 2.0, 26.0, 4.0)
		var shape := PackedVector2Array([Vector2(-6, 0), Vector2(-2, -6), Vector2(6, -3), Vector2(6, 3), Vector2(-2, 6)])
		if ingot:
			shape = PackedVector2Array([Vector2(-7, 2), Vector2(-3, -4), Vector2(7, -4), Vector2(4, 4), Vector2(-5, 4)])
		for i in range(shape.size()):
			shape[i] += Vector2(icon_x, cy)
		draw_colored_polygon(shape, color)
		draw_line(Vector2(icon_x - 3, cy - 3), Vector2(icon_x + 2, cy - 4), color.lightened(0.4))
		draw_rect(bar, Color("09131c"))
		var fill := clampf(float(count) / float(maxi(capacity, 1)), 0.0, 1.0)
		var filled := Rect2(bar.position + Vector2(bar.size.x * (1.0 - fill) if mirrored else 0.0, 0), Vector2(bar.size.x * fill, bar.size.y))
		draw_rect(filled, GOLD if count >= capacity else color)

var card_id := ""
var kind := ""
var is_working := false
var animation_active := false
var animation_frame := 0
var animation_elapsed := 0.0
var animation_scale := 1.0
var simulation_paused := false
var pause_btn: Button
var rate_label: Label
var cycle_bar: ProgressBar
var art: TextureRect
var input_gauges: Dictionary = {}
var output_gauges: Dictionary = {}
var _atlas: AtlasTexture

func _box(background: Color, border: Color, pad_x: int, pad_y: int, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	return style

func _build(accent: Color) -> void:
	custom_minimum_size.x = ART + SIDE * 2
	add_theme_constant_override("separation", 0)
	add_theme_stylebox_override("panel", _box(Color("12222e"), accent.darkened(0.55), 0, 4))
	add_theme_stylebox_override("panel_selected", _box(Color("193140"), TEAL, 0, 4))
	add_theme_stylebox_override("titlebar", _box(Color("1b3140"), accent.darkened(0.55), 10, 4))
	add_theme_stylebox_override("titlebar_selected", _box(Color("244454"), TEAL, 10, 4))
	add_theme_color_override("title_color", INK)
	pause_btn = Button.new()
	pause_btn.flat = true
	pause_btn.custom_minimum_size = Vector2(22, 20)
	pause_btn.add_theme_font_size_override("font_size", 12)
	pause_btn.add_theme_color_override("font_color", INK)
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(func() -> void: toggle_pressed.emit(card_id))
	get_titlebar_hbox().add_child(pause_btn)
	_atlas = AtlasTexture.new()
	_atlas.atlas = load(SHEETS[kind])
	_atlas.region = Rect2(0, 0, ART, ART)
	art = TextureRect.new()
	art.name = "Art"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Only the pixel art is sampled nearest; card text keeps smooth filtering.
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = _atlas
	art.size = Vector2(ART, ART)
	art.position = Vector2(SIDE, 0)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_frame(0)

func setup_from_sim(sim: RefCounted, id: String) -> void:
	card_id = id
	name = id
	var machine: Dictionary = sim.machines[id]
	kind = str(machine.kind)
	var spec: Dictionary = sim.catalog.machines[kind]
	title = str(spec.name)
	_build(Color(spec.color))
	var ins: Array = sim.input_products(id)
	var outs: Array = sim.output_products(id)
	var rows := maxi(maxi(ins.size(), outs.size()), 1)
	var used := 0.0
	for i in range(rows):
		# Rows split the artwork height evenly so ports sit beside the art.
		var height := roundf(ART * (i + 1) / rows) - used
		used += height
		var row := Control.new()
		row.name = "PortRow_%d" % i
		row.custom_minimum_size = Vector2(ART + SIDE * 2, height)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		var has_in := i < ins.size()
		var has_out := i < outs.size()
		if has_in:
			input_gauges[str(ins[i])] = _gauge(row, sim, str(ins[i]), false)
		if has_out:
			output_gauges[str(outs[i])] = _gauge(row, sim, str(outs[i]), true)
		set_slot(i, has_in, sim.product_port_type(str(ins[i])) if has_in else 0,
			Color(sim.catalog.products[str(ins[i])].color) if has_in else Color.WHITE,
			has_out, sim.product_port_type(str(outs[i])) if has_out else 0,
			Color(sim.catalog.products[str(outs[i])].color) if has_out else Color.WHITE)
	get_node("PortRow_0").add_child(art)
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.custom_minimum_size = Vector2(ART + SIDE * 2, 18)
	footer.add_theme_constant_override("separation", 8)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	var pad := Control.new()
	pad.custom_minimum_size.x = 2
	footer.add_child(pad)
	cycle_bar = ProgressBar.new()
	cycle_bar.show_percentage = false
	cycle_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cycle_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cycle_bar.custom_minimum_size.y = 6
	cycle_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cycle_bar.add_theme_stylebox_override("background", _box(Color("09131c"), Color.TRANSPARENT, 0, 0, 3))
	footer.add_child(cycle_bar)
	rate_label = Label.new()
	rate_label.custom_minimum_size.x = 44
	rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rate_label.add_theme_font_size_override("font_size", 11)
	rate_label.add_theme_color_override("font_color", MUTED)
	footer.add_child(rate_label)
	var pad_end := Control.new()
	pad_end.custom_minimum_size.x = 2
	footer.add_child(pad_end)
	update_from_sim(sim, id)

func _gauge(row: Control, sim: RefCounted, product: String, is_output: bool) -> PortGauge:
	var gauge := PortGauge.new()
	gauge.mirrored = is_output
	gauge.ingot = is_output and kind == "smelter"
	gauge.color = Color(sim.catalog.products[product].color)
	gauge.position = Vector2(SIDE + ART if is_output else 0.0, 0)
	gauge.size = Vector2(SIDE, row.custom_minimum_size.y)
	gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(gauge)
	return gauge

func update_from_sim(sim: RefCounted, id: String) -> void:
	if not sim.machines.has(id):
		return
	var machine: Dictionary = sim.machines[id]
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	var recipe: Dictionary = sim.recipe_for(id)
	var product: String = sim.output_product(id)
	var seconds := float(recipe.work) / float(machine.speed)
	rate_label.text = "%.0f/dk" % (int(recipe.outputs.get(product, 1)) * 60.0 / seconds)
	var details := PackedStringArray([str(spec.name), str(recipe.name), str(machine.status)])
	for input in input_gauges:
		var gauge: PortGauge = input_gauges[input]
		gauge.count = int(machine.input.get(input, 0))
		gauge.capacity = int(spec.input_capacity)
		gauge.tooltip_text = "%s %d/%d" % [sim.catalog.products[input].name, gauge.count, gauge.capacity]
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	for output in output_gauges:
		var gauge: PortGauge = output_gauges[output]
		gauge.count = int(machine.output.get(output, 0))
		gauge.capacity = int(spec.output_capacity)
		gauge.tooltip_text = "%s %d/%d" % [sim.catalog.products[output].name, gauge.count, gauge.capacity]
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	details.append("%.1f sn · %s" % [seconds, rate_label.text])
	tooltip_text = "\n".join(details)
	is_working = bool(machine.running)
	animation_active = is_working and not simulation_paused
	cycle_bar.value = (1.0 - float(machine.remaining) / float(recipe.work)) * 100.0 if is_working else 0.0
	var status_color := TEAL if animation_active else (MUTED if simulation_paused or not machine.enabled else GOLD)
	cycle_bar.add_theme_stylebox_override("fill", _box(status_color, Color.TRANSPARENT, 0, 0, 3))
	pause_btn.text = "Ⅱ" if machine.enabled else "▶"
	pause_btn.tooltip_text = "Durdur" if machine.enabled else "Çalıştır"

func set_simulation_playback(paused: bool, speed: float) -> void:
	simulation_paused = paused
	animation_scale = speed
	animation_active = is_working and not paused

func _process(delta: float) -> void:
	if not animation_active:
		return
	animation_elapsed += delta * animation_scale
	if animation_elapsed >= 0.1:
		_set_frame((animation_frame + int(animation_elapsed / 0.1)) % 12)
		animation_elapsed = fmod(animation_elapsed, 0.1)

func _set_frame(frame: int) -> void:
	animation_frame = frame
	_atlas.region = Rect2(Vector2(frame % 4, floori(frame / 4.0)) * ART, Vector2(ART, ART))
