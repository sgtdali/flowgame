extends GraphNode
## Standard illustrated machine card (art_src/STANDART.md): inputs left, 256x256 animated
## artwork centre, outputs right, cycle bar below. Nothing is drawn outside the card.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)
signal supplier_requested(card_id: String, product: String, at: Vector2)
## Clicking an output gauge (or a depot's stock) moves it into the player's inventory.
signal take_requested(card_id: String, product: String)
## A product dragged from the inventory was dropped on one of this card's inputs.
signal deposit_requested(card_id: String, product: String)

const Icons = preload("res://app/icons.gd")
## kind -> sheet of 4x3 frames (frame size = sheet width / 4). Add a line here for each new
## machine; machines not listed use their still placeholder from app/art/placeholder.
## Art smaller than ART (the old 128 px sheets) is scaled up by a whole factor.
const SHEETS := {
	"iron_mine": "res://app/art/iron_mine_b/iron_mine_sheet.png",
	"smelter": "res://app/art/smelter_b/smelter_sheet.png",
}
const ART := 256.0
const PLACEHOLDER := "res://app/art/placeholder/%s.png"
const SIDE := 64.0
const INK := Color("3d3a33")
const MUTED := Color("7a7466")
const TEAL := Color("4f9a8a")
const GOLD := Color("b98330")
const PLATE := Color("f3eee4")
const HEADER := Color("e9e2d3")
const EDGE := Color("c4b9a3")
const RIVET := Color("b3a78f")
const FRAME := 2
## Port slot size on the card (px).
const SLOT := 40.0

## One port column cell: a framed slot holding what the buffer has. Empty at zero; otherwise
## the product icon with the count in the corner (gold when the buffer is full).
class PortGauge extends Control:
	var mirrored := false
	var color := Color.WHITE
	var count := 0
	var capacity := 1
	var ingot := false
	## The open input of a machine whose recipe follows what gets linked to it.
	var open := false
	var icon: Texture2D
	## Inputs: while the slot is empty, the expected product is drawn faded.
	var ghost := false
	## Shown instead of the gauge while an input has no incoming line.
	var add_button: Button
	## Recipe amount for this product, drawn on the icon when above one.
	var amount := 1
	## Inputs only: how many of a product the player could drop here (0: not accepted),
	## and what to do when they do.
	var accepts: Callable
	var on_deposit: Callable

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if not accepts.is_valid() or not (data is Dictionary) or not str(data.get("inventory_key", "")).begins_with("product:"):
			return false
		return int(accepts.call(str(data.inventory_key).trim_prefix("product:"))) > 0

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		on_deposit.call(str(data.inventory_key).trim_prefix("product:"))

	## Framed slot, SLOT px square (smaller in crowded rows), set against the card's outer edge.
	func slot_rect() -> Rect2:
		var side := clampf(minf(size.y - 4.0, SLOT), 24.0, SLOT)
		var x := size.x - 2.0 - side if mirrored else 2.0
		return Rect2(x, roundf((size.y - side) * 0.5), side, side)

	func _draw() -> void:
		var box := slot_rect()
		var full := count >= capacity and count > 0
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ece6da")
		style.border_color = GOLD if full else Color("a89d88")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		draw_style_box(style, box)
		var c := box.get_center()
		if open:
			draw_arc(c, 7.0, 0.0, TAU, 20, color, 1.5)
			return
		# 32px icons only fit whole; in crowded rows they are drawn at half size.
		var icon_size := 32.0 if box.size.x >= 36.0 else 16.0
		var icon_rect := Rect2(c - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
		if count <= 0:
			if ghost and icon != null:
				draw_texture_rect(icon, icon_rect, false, Color(1, 1, 1, 0.3))
			return
		if icon != null:
			draw_texture_rect(icon, icon_rect, false)
		else:
			var shape := PackedVector2Array([Vector2(-6, 0), Vector2(-2, -6), Vector2(6, -3), Vector2(6, 3), Vector2(-2, 6)])
			if ingot:
				shape = PackedVector2Array([Vector2(-7, 2), Vector2(-3, -4), Vector2(7, -4), Vector2(4, 4), Vector2(-5, 4)])
			for i in range(shape.size()):
				shape[i] += c
			draw_colored_polygon(shape, color)
		var font := ThemeDB.fallback_font
		var text := str(count)
		var at := Vector2(box.end.x - 3.0 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, box.end.y - 3.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color("f6f2ea"))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD if full else INK)

## Small status symbol beside the cycle bar; the status text is its tooltip.
class StatusIcon extends Control:
	var state := ""

	func _draw() -> void:
		var c := size * 0.5
		match state:
			"Working", "Last experiment running":
				draw_circle(c, 4.0, TEAL)
			"Waiting for input", "Waiting for prerequisite":
				# hourglass
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -6), c + Vector2(5, -6), c, c + Vector2(5, 6), c + Vector2(-5, 6)]), GOLD)
			"Output buffer full":
				# full crate with an up arrow
				draw_rect(Rect2(c + Vector2(-6, -2), Vector2(12, 8)), GOLD)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -3), c + Vector2(0, -7), c + Vector2(4, -3)]), GOLD)
			"Stopped", "Game paused":
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
## Header chip naming what the machine makes (its recipe's main product).
var target_icon: TextureRect
var target_label: Label
var _machine_enabled := true
var _frame_count := 1
## Frame size in the sheet (px); drawn at ART.
var _frame_px := ART
var _storage := false

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
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.theme_type_variation = "Heading"
	header_icon = TextureRect.new()
	header_icon.custom_minimum_size = Vector2(16, 16)
	header_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	get_titlebar_hbox().add_child(header_icon)
	get_titlebar_hbox().move_child(header_icon, 0)
	get_titlebar_hbox().add_theme_constant_override("separation", 6)
	var target := HBoxContainer.new()
	target.add_theme_constant_override("separation", 3)
	target.mouse_filter = Control.MOUSE_FILTER_PASS
	# Shares the header with the title; long product names are cut with an ellipsis.
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target.alignment = BoxContainer.ALIGNMENT_END
	target_icon = TextureRect.new()
	target_icon.custom_minimum_size = Vector2(16, 16)
	target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	target_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(target_icon)
	target_label = Label.new()
	target_label.add_theme_font_size_override("font_size", 11)
	target_label.add_theme_color_override("font_color", GOLD)
	target_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target_label.custom_minimum_size.x = 20
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(target_label)
	get_titlebar_hbox().add_child(target)
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
	# A depot has no cycle to stop.
	pause_btn.visible = not _storage
	_atlas = AtlasTexture.new()
	_atlas.atlas = load(art_path(kind))
	var sheet := _atlas.atlas
	_frame_px = sheet.get_width() / 4.0 if SHEETS.has(kind) else float(sheet.get_width())
	_frame_count = maxi(1, int(sheet.get_width() / _frame_px) * int(sheet.get_height() / _frame_px))
	_atlas.region = Rect2(0, 0, _frame_px, _frame_px)
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

## What the machine is set to make, in the header: the main output's icon and name, the
## recipe name for machines without a product output (labs, project), "?" for an auto
## machine that has nothing fed in yet. A depot shows nothing.
func _show_target(sim: RefCounted, id: String) -> void:
	var chip := target_icon.get_parent() as Control
	var product: String = sim.output_product(id)
	chip.visible = not _storage
	if sim.recipe_mode(kind) == "auto" and sim.linked_inputs(id).is_empty():
		target_icon.visible = false
		target_label.text = "?"
		chip.tooltip_text = "Set by the product linked or put in"
	elif product.is_empty():
		target_icon.visible = false
		target_label.text = str(sim.recipe_for(id).get("name", ""))
		chip.tooltip_text = target_label.text
	else:
		target_icon.texture = Icons.product(sim, product)
		target_icon.visible = true
		target_label.text = sim.product_name(product)
		chip.tooltip_text = "Making: %s" % target_label.text

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
	draw_rect(Rect2(-1, -1, size.x + 2, size.y + 2), Color("b9ae97"), false, 1.0)
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
	_storage = sim.is_storage(kind)
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
	cycle_bar.add_theme_stylebox_override("background", _box(Color("e2dacb"), Color.TRANSPARENT, 0, 0, 3))
	footer.add_child(cycle_bar)
	cycle_bar.modulate.a = 0.0 if _storage else 1.0
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
	if not is_output and not gauge.open:
		gauge.ghost = true
	gauge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gauge.position = Vector2(SIDE + ART if is_output else 0.0, 0)
	gauge.size = Vector2(SIDE, row.custom_minimum_size.y)
	gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(gauge)
	if (is_output or _storage) and not gauge.open:
		gauge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gauge.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
				take_requested.emit(card_id, product)
				gauge.accept_event())
	if not is_output:
		# The open port of an auto machine or depot takes whatever fits; others only their product.
		gauge.accepts = func(dropped: String) -> int:
			return 0 if not gauge.open and dropped != product else sim.can_deposit(card_id, dropped)
		gauge.on_deposit = func(dropped: String) -> void: deposit_requested.emit(card_id, dropped)
		var add := Button.new()
		add.text = "+"
		add.flat = true
		# Beside the slot, between it and the artwork.
		add.position = Vector2(SLOT + 1.0, row.custom_minimum_size.y * 0.5 - 11)
		add.size = Vector2(22, 22)
		add.add_theme_font_size_override("font_size", 20)
		add.add_theme_color_override("font_color", TEAL)
		add.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add.tooltip_text = "Build supplier" if gauge.open else "Build %s supplier" % sim.product_name(product)
		add.pressed.connect(func() -> void: supplier_requested.emit(card_id, product, add.global_position + Vector2(0, add.size.y)))
		gauge.add_child(add)
		gauge.add_button = add
	return gauge

func update_from_sim(sim: RefCounted, id: String) -> void:
	if not sim.machines.has(id):
		return
	_show_target(sim, id)
	var machine: Dictionary = sim.machines[id]
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	var recipe: Dictionary = sim.recipe_for(id)
	var product: String = sim.output_product(id)
	var seconds: float = float(recipe.work) / sim.effective_speed(id)
	rate_label.text = "%.0f/min" % (int(recipe.outputs.get(product, 1)) * 60.0 / seconds)
	# Labs make research points instead of goods: their rate takes the tier colour.
	for tier in recipe.get("research_points", {}):
		for t in sim.catalog.get("research_tiers", []):
			if str(t.id) == str(tier):
				rate_label.add_theme_color_override("font_color", Color(t.color))
				rate_label.tooltip_text = "%s per min" % t.name
	var details := PackedStringArray([str(spec.name), str(recipe.name), str(machine.status)])
	for input in input_gauges:
		var gauge: PortGauge = input_gauges[input]
		gauge.count = int(machine.input.get(input, 0))
		gauge.capacity = sim.capacity(str(machine.kind), "input")
		gauge.amount = int(recipe.inputs.get(input, 1))
		gauge.add_button.visible = not _storage and (gauge.open or not sim.is_input_linked(id, input))
		if gauge.open and _storage:
			gauge.tooltip_text = "Any product can be linked"
		elif gauge.open:
			var accepted := PackedStringArray()
			for product_id in sim.recipe_input_union(kind):
				if sim.accepts_new_input(id, product_id) and not sim.is_input_linked(id, product_id):
					accepted.append(sim.product_name(product_id))
			gauge.tooltip_text = "Can link: %s" % ", ".join(accepted)
		else:
			gauge.tooltip_text = "%s %d/%d" % [sim.product_name(input), gauge.count, gauge.capacity]
			if _storage:
				gauge.tooltip_text += "\nClick: take to inventory"
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	for output in output_gauges:
		var gauge: PortGauge = output_gauges[output]
		gauge.count = int(machine.output.get(output, 0))
		gauge.capacity = sim.capacity(str(machine.kind), "output")
		gauge.amount = int(recipe.outputs.get(output, 1))
		gauge.tooltip_text = "%s %d/%d\nClick: take to inventory" % [sim.product_name(output), gauge.count, gauge.capacity]
		details.append(gauge.tooltip_text)
		gauge.queue_redraw()
	if _storage:
		var stored := 0
		for product_id in machine.input:
			stored += int(machine.input[product_id])
		rate_label.text = str(stored)
		rate_label.tooltip_text = "Total items in storage"
	else:
		details.append("%.0f work · %.0f work/s · %.1f s · %s" % [float(recipe.work), sim.effective_speed(id), seconds, rate_label.text])
	tooltip_text = "\n".join(details)
	is_working = bool(machine.running)
	animation_active = is_working and not simulation_paused
	cycle_bar.value = (1.0 - float(machine.remaining) / float(recipe.work)) * 100.0 if is_working else 0.0
	var status_color := TEAL if animation_active else (MUTED if simulation_paused or not machine.enabled else GOLD)
	cycle_bar.add_theme_stylebox_override("fill", _box(status_color, Color.TRANSPARENT, 0, 0, 3))
	status_icon.state = "Game paused" if simulation_paused else str(machine.status)
	status_icon.tooltip_text = status_icon.state
	status_icon.queue_redraw()
	if _machine_enabled != bool(machine.enabled):
		_machine_enabled = bool(machine.enabled)
		pause_btn.queue_redraw()
	pause_btn.tooltip_text = "Stop" if machine.enabled else "Run"

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
	_atlas.region = Rect2(Vector2(frame % 4, floori(frame / 4.0)) * _frame_px, Vector2(_frame_px, _frame_px))
