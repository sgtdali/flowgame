extends GraphNode
## Standard illustrated machine card (art_src/STANDART.md): inputs left, 128x128 animated
## artwork centre, outputs right, cycle bar below. Nothing is drawn outside the card.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)
signal supplier_requested(card_id: String, product: String, at: Vector2)

const Icons = preload("res://app/icons.gd")
## kind -> 512x384 sheet (4x3 frames of 128x128). Add a line here for each new machine;
## machines not listed use their still placeholder from app/art/placeholder.
const SHEETS := {
	"iron_mine": "res://app/art/iron_mine_b/iron_mine_sheet.png",
	"smelter": "res://app/art/smelter_a/smelter_sheet.png",
}
const ART := 128.0
const PLACEHOLDER := "res://app/art/placeholder/%s.png"
const SIDE := 64.0
const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
const PLATE := Color("16242f")
const HEADER := Color("1e3141")
const EDGE := Color("2c4356")
const RIVET := Color("4d6a7e")
const FRAME := 2

## One port column cell: product icon plus a small buffer gauge.
class PortGauge extends Control:
	var mirrored := false
	var color := Color.WHITE
	var count := 0
	var capacity := 1
	var ingot := false
	## The open input of a machine whose recipe follows what gets linked to it.
	var open := false
	var icon: Texture2D
	## Shown instead of the gauge while an input has no incoming line.
	var add_button: Button
	## Recipe amount for this product, drawn on the icon when above one.
	var amount := 1

	func _draw() -> void:
		var cy := size.y * 0.5
		var icon_x := size.x - 20.0 if mirrored else 20.0
		var bar := Rect2(6.0 if mirrored else 38.0, cy - 2.0, 20.0, 4.0)
		var shape := PackedVector2Array([Vector2(-6, 0), Vector2(-2, -6), Vector2(6, -3), Vector2(6, 3), Vector2(-2, 6)])
		if ingot:
			shape = PackedVector2Array([Vector2(-7, 2), Vector2(-3, -4), Vector2(7, -4), Vector2(4, 4), Vector2(-5, 4)])
		if open:
			draw_arc(Vector2(icon_x, cy), 8.0, 0.0, TAU, 20, color, 1.5)
		elif icon != null:
			draw_texture_rect(icon, Rect2(icon_x - 16.0, cy - 16.0, 32.0, 32.0), false)
			if amount > 1:
				var font := ThemeDB.fallback_font
				var at := Vector2(icon_x + 9.0, cy + 15.0)
				draw_string_outline(font, at, str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("09131c"))
				draw_string(font, at, str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
		else:
			for i in range(shape.size()):
				shape[i] += Vector2(icon_x, cy)
			draw_colored_polygon(shape, color)
			draw_line(Vector2(icon_x - 3, cy - 3), Vector2(icon_x + 2, cy - 4), color.lightened(0.4))
		if add_button != null and add_button.visible:
			return
		draw_rect(bar, Color("09131c"))
		var fill := clampf(float(count) / float(maxi(capacity, 1)), 0.0, 1.0)
		var filled := Rect2(bar.position + Vector2(bar.size.x * (1.0 - fill) if mirrored else 0.0, 0), Vector2(bar.size.x * fill, bar.size.y))
		draw_rect(filled, GOLD if count >= capacity else color)

## Small status symbol beside the cycle bar; the status text is its tooltip.
class StatusIcon extends Control:
	var state := ""

	func _draw() -> void:
		var c := size * 0.5
		match state:
			"İşleniyor", "Son deney sürüyor":
				draw_circle(c, 4.0, TEAL)
			"Girdi bekliyor", "Ön koşul bekliyor":
				# hourglass
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -6), c + Vector2(5, -6), c, c + Vector2(5, 6), c + Vector2(-5, 6)]), GOLD)
			"Çıkış tamponu dolu":
				# full crate with an up arrow
				draw_rect(Rect2(c + Vector2(-6, -2), Vector2(12, 8)), GOLD)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -3), c + Vector2(0, -7), c + Vector2(4, -3)]), GOLD)
			"Durduruldu", "Oyun duraklatıldı":
				draw_rect(Rect2(c + Vector2(-4, -4), Vector2(8, 8)), MUTED)
			_:
				draw_circle(c, 4.0, MUTED)

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
var status_icon: StatusIcon
var art: TextureRect
var input_gauges: Dictionary = {}
var output_gauges: Dictionary = {}
var _atlas: AtlasTexture
var accent_color := MUTED
var header_icon: TextureRect
var _machine_enabled := true
var _frame_count := 1

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

## Riveted steel plate: the header and body share one square-cornered frame; the header
## is a darker band with the machine colour as a thin line under it.
func _plate(background: Color, border: Color, header: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(FRAME)
	if header:
		style.border_width_bottom = 0
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.content_margin_left = 8
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 6
	else:
		style.border_width_top = 0
		# Rows run edge to edge (the rim overlaps them) so the card stays 256 wide.
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		style.content_margin_top = 4
		style.content_margin_bottom = 6
	return style

func _build(accent: Color) -> void:
	accent_color = accent
	custom_minimum_size.x = ART + SIDE * 2
	add_theme_constant_override("separation", 0)
	add_theme_stylebox_override("panel", _plate(PLATE, EDGE, false))
	add_theme_stylebox_override("panel_selected", _plate(PLATE, TEAL, false))
	add_theme_stylebox_override("titlebar", _plate(HEADER, EDGE, true))
	add_theme_stylebox_override("titlebar_selected", _plate(HEADER, TEAL, true))
	add_theme_color_override("title_color", INK)
	var title_label := get_titlebar_hbox().get_child(0) as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 13)
	header_icon = TextureRect.new()
	header_icon.custom_minimum_size = Vector2(16, 16)
	header_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	get_titlebar_hbox().add_child(header_icon)
	get_titlebar_hbox().move_child(header_icon, 0)
	get_titlebar_hbox().add_theme_constant_override("separation", 6)
	pause_btn = Button.new()
	pause_btn.flat = true
	pause_btn.custom_minimum_size = Vector2(20, 18)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_btn.pressed.connect(func() -> void: toggle_pressed.emit(card_id))
	pause_btn.draw.connect(_draw_toggle)
	pause_btn.mouse_entered.connect(pause_btn.queue_redraw)
	pause_btn.mouse_exited.connect(pause_btn.queue_redraw)
	get_titlebar_hbox().add_child(pause_btn)
	_atlas = AtlasTexture.new()
	_atlas.atlas = load(art_path(kind))
	_frame_count = maxi(1, int(_atlas.atlas.get_width() / ART) * int(_atlas.atlas.get_height() / ART))
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

func set_header_icon(texture: Texture2D) -> void:
	header_icon.texture = texture

## Pixel pause bars while running, a play triangle while stopped.
func _draw_toggle() -> void:
	var color := TEAL if pause_btn.is_hovered() else INK
	var c := (pause_btn.size * 0.5).floor()
	if _machine_enabled:
		pause_btn.draw_rect(Rect2(c + Vector2(-4, -5), Vector2(3, 10)), color)
		pause_btn.draw_rect(Rect2(c + Vector2(1, -5), Vector2(3, 10)), color)
	else:
		pause_btn.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -5), c + Vector2(4, 0), c + Vector2(-3, 5)]), color)

## Accent line under the header and rivets in the plate corners.
func _draw() -> void:
	var header_h := get_theme_stylebox("titlebar").get_minimum_size().y + get_titlebar_hbox().size.y
	draw_rect(Rect2(FRAME, header_h - 2, size.x - FRAME * 2, 2), accent_color)
	draw_rect(Rect2(FRAME, FRAME, size.x - FRAME * 2, 1), HEADER.lightened(0.12))
	# Dark outline just outside the rim so the plate stands off the grid.
	draw_rect(Rect2(-1, -1, size.x + 2, size.y + 2), Color("070d13"), false, 1.0)
	for corner in [Vector2(5, header_h + 4), Vector2(size.x - 8, header_h + 4), Vector2(5, size.y - 8), Vector2(size.x - 8, size.y - 8)]:
		draw_rect(Rect2(corner, Vector2(3, 3)), RIVET)
		draw_rect(Rect2(corner, Vector2(1, 1)), RIVET.lightened(0.35))
		draw_rect(Rect2(corner + Vector2(2, 2), Vector2(1, 1)), PLATE.darkened(0.4))

static func art_path(machine_kind: String) -> String:
	return SHEETS.get(machine_kind, PLACEHOLDER % machine_kind)

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
		set_slot(i, has_in, sim.port_type(id, str(ins[i])) if has_in else 0,
			sim.product_color(str(ins[i])) if has_in else Color.WHITE,
			has_out, sim.port_type(id, str(outs[i])) if has_out else 0,
			sim.product_color(str(outs[i])) if has_out else Color.WHITE)
	get_node("PortRow_0").add_child(art)
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.custom_minimum_size = Vector2(ART + SIDE * 2, 18)
	footer.add_theme_constant_override("separation", 8)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	status_icon = StatusIcon.new()
	status_icon.custom_minimum_size = Vector2(18, 18)
	status_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	footer.add_child(status_icon)
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
	gauge.color = sim.product_color(product)
	gauge.open = product == sim.ANY
	gauge.icon = Icons.product(sim, product)
	gauge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gauge.position = Vector2(SIDE + ART if is_output else 0.0, 0)
	gauge.size = Vector2(SIDE, row.custom_minimum_size.y)
	gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(gauge)
	if not is_output:
		var add := Button.new()
		add.text = "+"
		add.flat = true
		add.position = Vector2(36, row.custom_minimum_size.y * 0.5 - 11)
		add.size = Vector2(22, 22)
		add.add_theme_font_size_override("font_size", 20)
		add.add_theme_color_override("font_color", TEAL)
		add.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add.tooltip_text = "Üretici kur" if gauge.open else "%s üreticisi kur" % sim.product_name(product)
		add.pressed.connect(func() -> void: supplier_requested.emit(card_id, product, add.global_position + Vector2(0, add.size.y)))
		gauge.add_child(add)
		gauge.add_button = add
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
		gauge.amount = int(recipe.inputs.get(input, 1))
		gauge.add_button.visible = gauge.open or not sim.is_input_linked(id, input)
		if gauge.open:
			var accepted := PackedStringArray()
			for product_id in sim.recipe_input_union(kind):
				if sim.accepts_new_input(id, product_id) and not sim.is_input_linked(id, product_id):
					accepted.append(sim.product_name(product_id))
			gauge.tooltip_text = "Bağlanabilir: %s" % ", ".join(accepted)
		else:
			gauge.tooltip_text = "%s %d/%d" % [sim.product_name(input), gauge.count, gauge.capacity]
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	for output in output_gauges:
		var gauge: PortGauge = output_gauges[output]
		gauge.count = int(machine.output.get(output, 0))
		gauge.capacity = int(spec.output_capacity)
		gauge.amount = int(recipe.outputs.get(output, 1))
		gauge.tooltip_text = "%s %d/%d" % [sim.product_name(output), gauge.count, gauge.capacity]
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	details.append("%.0f birim iş · %.0f iş/sn · %.1f sn · %s" % [float(recipe.work), float(machine.speed), seconds, rate_label.text])
	tooltip_text = "\n".join(details)
	is_working = bool(machine.running)
	animation_active = is_working and not simulation_paused
	cycle_bar.value = (1.0 - float(machine.remaining) / float(recipe.work)) * 100.0 if is_working else 0.0
	var status_color := TEAL if animation_active else (MUTED if simulation_paused or not machine.enabled else GOLD)
	cycle_bar.add_theme_stylebox_override("fill", _box(status_color, Color.TRANSPARENT, 0, 0, 3))
	status_icon.state = "Oyun duraklatıldı" if simulation_paused else str(machine.status)
	status_icon.tooltip_text = status_icon.state
	status_icon.queue_redraw()
	if _machine_enabled != bool(machine.enabled):
		_machine_enabled = bool(machine.enabled)
		pause_btn.queue_redraw()
	pause_btn.tooltip_text = "Durdur" if machine.enabled else "Çalıştır"

func set_simulation_playback(paused: bool, speed: float) -> void:
	simulation_paused = paused
	animation_scale = speed
	animation_active = is_working and not paused

func _process(delta: float) -> void:
	if not animation_active or _frame_count <= 1:
		return
	animation_elapsed += delta * animation_scale
	if animation_elapsed >= 0.1:
		_set_frame((animation_frame + int(animation_elapsed / 0.1)) % _frame_count)
		animation_elapsed = fmod(animation_elapsed, 0.1)

func _set_frame(frame: int) -> void:
	animation_frame = frame
	_atlas.region = Rect2(Vector2(frame % 4, floori(frame / 4.0)) * ART, Vector2(ART, ART))
