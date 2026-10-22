@tool
extends GraphNode
## Tekil makine kartı (Node) sahnesi.
## @tool desteği sayesinde Godot Editöründe (machine_card.tscn) doğrudan görülür ve Inspector'dan düzenlenebilir.

signal recipe_changed(card_id: String, recipe_id: String)
signal toggle_pressed(card_id: String)

const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
const GEAR_TEX := preload("res://app/icons/gear.svg")

@export_enum("iron_mine", "copper_mine", "coal_mine", "quartz_quarry", "smelter", "steel_furnace", "rolling_mill", "press", "lathe", "cnc", "foundry", "wire_winder", "assembler", "scrap_disposal", "lab", "project_hub")
var preview_kind: String = "cnc":
	set(value):
		preview_kind = value
		if Engine.is_editor_hint() and is_inside_tree():
			_rebuild_editor_preview()

@export var preview_working: bool = true:
	set(value):
		preview_working = value
		is_working = value
		if is_instance_valid(gear_icon):
			gear_icon.self_modulate = TEAL if value else GOLD
		if is_instance_valid(pause_btn) and Engine.is_editor_hint():
			pause_btn.text = "⏸" if value else "▶"

@export var card_min_width: float = 245.0:
	set(value):
		card_min_width = value
		custom_minimum_size.x = value

var card_id: String = ""
var is_working: bool = true
var top_bar: HBoxContainer
var gear_holder: Control
var gear_icon: TextureRect
var recipe_dropdown: OptionButton
var pause_btn: Button
var footer_row: VBoxContainer
var progress_bar: ProgressBar
var rate_label: Label

var in_labels: Dictionary = {}
var out_labels: Dictionary = {}
var dropdown_recipe_ids: Array[String] = []
var displayed_recipe: String = ""

func _ready() -> void:
	_ensure_structure()
	if Engine.is_editor_hint():
		is_working = preview_working
		_rebuild_editor_preview()

func _process(delta: float) -> void:
	var active := preview_working if Engine.is_editor_hint() else is_working
	if active and is_instance_valid(gear_icon):
		gear_icon.pivot_offset = gear_icon.size * 0.5
		gear_icon.rotation = fposmod(gear_icon.rotation + delta * 2.6, TAU)

func _box(background: Color, border: Color, radius: int = 8, pad_x: int = 10, pad_y: int = 8) -> StyleBoxFlat:
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

func _ensure_structure() -> void:
	custom_minimum_size.x = card_min_width
	if has_node("HeaderControls"):
		top_bar = $HeaderControls
		if top_bar.has_node("StatusDot"):
			var old_dot := top_bar.get_node("StatusDot")
			top_bar.remove_child(old_dot)
			old_dot.queue_free()
		if top_bar.has_node("GearHolder"):
			gear_holder = $HeaderControls/GearHolder
			gear_icon = $HeaderControls/GearHolder/GearIcon
		else:
			_create_gear_nodes()
			top_bar.move_child(gear_holder, 0)
		recipe_dropdown = $HeaderControls/RecipeDropdown
		pause_btn = $HeaderControls/PauseButton
		footer_row = $FooterSection
		if footer_row.has_node("StatusLabel"):
			var old_status := footer_row.get_node("StatusLabel")
			footer_row.remove_child(old_status)
			old_status.queue_free()
		progress_bar = $FooterSection/ProgressRow/CycleBar
		rate_label = $FooterSection/ProgressRow/RateLabel
	else:
		top_bar = HBoxContainer.new()
		top_bar.name = "HeaderControls"
		top_bar.add_theme_constant_override("separation", 6)
		add_child(top_bar)
		_create_gear_nodes()
		recipe_dropdown = OptionButton.new()
		recipe_dropdown.name = "RecipeDropdown"
		recipe_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recipe_dropdown.custom_minimum_size.y = 26
		recipe_dropdown.clip_text = true
		recipe_dropdown.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		top_bar.add_child(recipe_dropdown)
		pause_btn = Button.new()
		pause_btn.name = "PauseButton"
		pause_btn.text = "⏸"
		pause_btn.custom_minimum_size = Vector2(28, 26)
		pause_btn.tooltip_text = "Makineyi Durdur / Çalıştır"
		pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		top_bar.add_child(pause_btn)
		footer_row = VBoxContainer.new()
		footer_row.name = "FooterSection"
		footer_row.add_theme_constant_override("separation", 4)
		add_child(footer_row)
		var prog_row := HBoxContainer.new()
		prog_row.name = "ProgressRow"
		prog_row.add_theme_constant_override("separation", 8)
		footer_row.add_child(prog_row)
		progress_bar = ProgressBar.new()
		progress_bar.name = "CycleBar"
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		progress_bar.custom_minimum_size.y = 8
		progress_bar.show_percentage = false
		prog_row.add_child(progress_bar)
		rate_label = Label.new()
		rate_label.name = "RateLabel"
		rate_label.text = "5.0 sn · 12/dk"
		rate_label.add_theme_font_size_override("font_size", 11)
		rate_label.add_theme_color_override("font_color", MUTED)
		prog_row.add_child(rate_label)
	if is_instance_valid(gear_icon):
		gear_icon.texture = GEAR_TEX
		gear_icon.pivot_offset = Vector2(9, 9)
	if not recipe_dropdown.item_selected.is_connected(_on_dropdown_selected):
		recipe_dropdown.item_selected.connect(_on_dropdown_selected)
	if not pause_btn.pressed.is_connected(_on_pause_pressed):
		pause_btn.pressed.connect(_on_pause_pressed)

func _create_gear_nodes() -> void:
	gear_holder = Control.new()
	gear_holder.name = "GearHolder"
	gear_holder.custom_minimum_size = Vector2(20, 20)
	gear_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(gear_holder)
	gear_icon = TextureRect.new()
	gear_icon.name = "GearIcon"
	gear_icon.texture = GEAR_TEX
	gear_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gear_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gear_icon.custom_minimum_size = Vector2(18, 18)
	gear_icon.size = Vector2(18, 18)
	gear_icon.position = Vector2(1, 1)
	gear_icon.pivot_offset = Vector2(9, 9)
	gear_icon.self_modulate = TEAL
	gear_holder.add_child(gear_icon)

func _on_dropdown_selected(idx: int) -> void:
	if idx >= 0 and idx < dropdown_recipe_ids.size() and not card_id.is_empty():
		recipe_changed.emit(card_id, dropdown_recipe_ids[idx])

func _on_pause_pressed() -> void:
	if Engine.is_editor_hint():
		preview_working = not preview_working
		return
	if not card_id.is_empty():
		toggle_pressed.emit(card_id)

func _clear_port_rows() -> void:
	clear_all_slots()
	in_labels.clear()
	out_labels.clear()
	for child in get_children():
		if str(child.name).begins_with("PortRow_"):
			remove_child(child)
			child.queue_free()

func _apply_card_styles(accent: Color) -> void:
	add_theme_stylebox_override("panel", _box(Color("12222e"), accent.darkened(0.55), 8, 10, 8))
	add_theme_stylebox_override("panel_selected", _box(Color("193140"), accent, 8, 10, 8))
	add_theme_stylebox_override("titlebar", _box(Color("1b3140"), accent.darkened(0.55), 8, 10, 6))
	add_theme_stylebox_override("titlebar_selected", _box(Color("244454"), accent, 8, 10, 6))
	if is_instance_valid(recipe_dropdown):
		recipe_dropdown.add_theme_stylebox_override("normal", _box(Color("162836"), Color("294356"), 5, 8, 4))
		recipe_dropdown.add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL, 5, 8, 4))
		recipe_dropdown.add_theme_stylebox_override("pressed", _box(Color("295258"), TEAL, 5, 8, 4))
		recipe_dropdown.add_theme_color_override("font_color", INK)
		recipe_dropdown.add_theme_font_size_override("font_size", 12)
	if is_instance_valid(pause_btn):
		pause_btn.add_theme_stylebox_override("normal", _box(Color("162836"), Color("294356"), 5, 6, 3))
		pause_btn.add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL, 5, 6, 3))
		pause_btn.add_theme_color_override("font_color", INK)
	if is_instance_valid(progress_bar):
		progress_bar.add_theme_stylebox_override("background", _box(Color("09131c"), Color.TRANSPARENT, 3, 0, 0))
		progress_bar.add_theme_stylebox_override("fill", _box(TEAL, Color.TRANSPARENT, 3, 0, 0))

func setup_from_sim(sim: RefCounted, id: String) -> void:
	_ensure_structure()
	card_id = id
	name = id
	var machine: Dictionary = sim.machines[id]
	var kind: String = str(machine.kind)
	var spec: Dictionary = sim.catalog.machines[kind]
	var accent := Color(spec.color)
	title = "%s" % spec.name
	_apply_card_styles(accent)
	_populate_recipe_dropdown(sim, machine, spec)
	_build_ports(sim, id, machine, spec)
	displayed_recipe = str(machine.recipe)
	update_from_sim(sim, id)

func _populate_recipe_dropdown(sim: RefCounted, machine: Dictionary, spec: Dictionary) -> void:
	recipe_dropdown.clear()
	dropdown_recipe_ids.clear()
	var allowed: Array = spec.get("recipes", [spec.recipe])
	if machine.kind == "lab":
		var r_spec: Dictionary = sim.recipe_for(card_id)
		recipe_dropdown.add_item(str(r_spec.get("name", machine.recipe)))
		dropdown_recipe_ids.append(str(machine.recipe))
		recipe_dropdown.disabled = true
		return
	var selected_idx := 0
	var item_idx := 0
	for r_var in allowed:
		var r_id := str(r_var)
		var r_spec: Dictionary = sim.catalog.recipes[r_id]
		var unlocked: bool = sim.is_recipe_unlocked(r_id)
		var label_text: String = str(r_spec.get("name", r_id))
		if not unlocked:
			var req: String = sim.unlock_tech_for_recipe(r_id)
			label_text = "🔒 %s (%s)" % [label_text, req]
		recipe_dropdown.add_item(label_text)
		recipe_dropdown.set_item_disabled(item_idx, not unlocked)
		dropdown_recipe_ids.append(r_id)
		if r_id == str(machine.recipe):
			selected_idx = item_idx
		item_idx += 1
	recipe_dropdown.selected = selected_idx
	recipe_dropdown.disabled = allowed.size() <= 1

func _build_ports(sim: RefCounted, id: String, _machine: Dictionary, _spec: Dictionary) -> void:
	_clear_port_rows()
	set_slot(0, false, 0, Color.WHITE, false, 0, Color.WHITE)
	var ins: Array = sim.input_products(id)
	var outs: Array = sim.output_products(id)
	var port_rows := maxi(maxi(ins.size(), outs.size()), 1)
	for i in range(port_rows):
		var row := HBoxContainer.new()
		row.name = "PortRow_%d" % i
		row.custom_minimum_size.y = 24
		row.add_theme_constant_override("separation", 16)
		var has_in := i < ins.size()
		var has_out := i < outs.size()
		var in_prod := str(ins[i]) if has_in else ""
		var out_prod := str(outs[i]) if has_out else ""
		var left := Label.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.add_theme_font_size_override("font_size", 12)
		left.add_theme_color_override("font_color", Color(sim.catalog.products[in_prod].color) if has_in else MUTED)
		if has_in:
			left.mouse_filter = Control.MOUSE_FILTER_PASS
			left.tooltip_text = sim.product_tooltip(in_prod)
		row.add_child(left)
		var right := Label.new()
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_theme_font_size_override("font_size", 12)
		right.add_theme_color_override("font_color", Color(sim.catalog.products[out_prod].color) if has_out else MUTED)
		if has_out:
			right.mouse_filter = Control.MOUSE_FILTER_PASS
			right.tooltip_text = sim.product_tooltip(out_prod)
		row.add_child(right)
		add_child(row)
		move_child(row, i + 1)
		if has_in:
			in_labels[in_prod] = left
		if has_out:
			out_labels[out_prod] = right
		var in_type: int = sim.product_port_type(in_prod) if has_in else 0
		var out_type: int = sim.product_port_type(out_prod) if has_out else 0
		var in_color := Color(sim.catalog.products[in_prod].color) if has_in else Color.WHITE
		var out_color := Color(sim.catalog.products[out_prod].color) if has_out else Color.WHITE
		set_slot(i + 1, has_in, in_type, in_color, has_out, out_type, out_color)
	move_child(footer_row, get_child_count() - 1)

func update_from_sim(sim: RefCounted, id: String) -> void:
	if not sim.machines.has(id):
		return
	var machine: Dictionary = sim.machines[id]
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	var recipe: Dictionary = sim.recipe_for(id)
	var seconds := float(recipe.work) / float(machine.speed)
	var primary_out: String = sim.output_product(id)
	var out_count: int = int(recipe.outputs.get(primary_out, 1)) if not primary_out.is_empty() else 1
	rate_label.text = "%.1f sn · %.0f/dk" % [seconds, out_count * 60.0 / seconds]
	var in_cap := int(spec.input_capacity)
	var out_cap := int(spec.output_capacity)
	for in_prod in in_labels:
		var lbl: Label = in_labels[in_prod]
		var need := int(recipe.inputs.get(in_prod, 1))
		var cur := int(machine.input.get(in_prod, 0))
		lbl.text = "%d× %s [%d/%d]" % [need, sim.catalog.products[in_prod].name, cur, in_cap]
	for out_prod in out_labels:
		var lbl: Label = out_labels[out_prod]
		var make := int(recipe.outputs.get(out_prod, 1))
		var cur := int(machine.output.get(out_prod, 0))
		lbl.text = "[%d/%d] %d× %s" % [cur, out_cap, make, sim.catalog.products[out_prod].name]
	is_working = bool(machine.running)
	progress_bar.value = (1.0 - float(machine.remaining) / float(recipe.work)) * 100.0 if is_working else 0.0
	var active_color := TEAL if is_working else (MUTED if not machine.enabled else GOLD)
	if is_instance_valid(gear_icon):
		gear_icon.self_modulate = active_color
		gear_icon.tooltip_text = str(machine.status)
	if is_instance_valid(gear_holder):
		gear_holder.tooltip_text = str(machine.status)
	pause_btn.text = "⏸" if machine.enabled else "▶"

func _rebuild_editor_preview() -> void:
	if not FileAccess.file_exists("res://data/prototype.json"):
		return
	var cat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype.json"))
	if not cat.machines.has(preview_kind):
		return
	var spec: Dictionary = cat.machines[preview_kind]
	var r_id: String = str(spec.recipe)
	var r_spec: Dictionary = cat.recipes[r_id]
	var accent := Color(spec.color)
	title = str(spec.name)
	_apply_card_styles(accent)
	recipe_dropdown.clear()
	for allowed_r in spec.get("recipes", [r_id]):
		recipe_dropdown.add_item(str(cat.recipes[str(allowed_r)].get("name", allowed_r)))
	_clear_port_rows()
	set_slot(0, false, 0, Color.WHITE, false, 0, Color.WHITE)
	var ins: Array = r_spec.inputs.keys()
	var outs: Array = r_spec.outputs.keys()
	var port_rows := maxi(maxi(ins.size(), outs.size()), 1)
	for i in range(port_rows):
		var row := HBoxContainer.new()
		row.name = "PortRow_%d" % i
		row.custom_minimum_size.y = 24
		row.add_theme_constant_override("separation", 16)
		var has_in := i < ins.size()
		var has_out := i < outs.size()
		var in_prod := str(ins[i]) if has_in else ""
		var out_prod := str(outs[i]) if has_out else ""
		var left := Label.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.add_theme_font_size_override("font_size", 12)
		if has_in:
			left.text = "%d× %s [4/%d]" % [int(r_spec.inputs[in_prod]), cat.products[in_prod].name, int(spec.input_capacity)]
			left.add_theme_color_override("font_color", Color(cat.products[in_prod].color))
		row.add_child(left)
		var right := Label.new()
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_theme_font_size_override("font_size", 12)
		if has_out:
			right.text = "[2/%d] %d× %s" % [int(spec.output_capacity), int(r_spec.outputs[out_prod]), cat.products[out_prod].name]
			right.add_theme_color_override("font_color", Color(cat.products[out_prod].color))
		row.add_child(right)
		add_child(row)
		move_child(row, i + 1)
		var in_color := Color(cat.products[in_prod].color) if has_in else Color.WHITE
		var out_color := Color(cat.products[out_prod].color) if has_out else Color.WHITE
		set_slot(i + 1, has_in, 0, in_color, has_out, 0, out_color)
	move_child(footer_row, get_child_count() - 1)
	var seconds := float(r_spec.work) / float(spec.speed)
	rate_label.text = "%.1f sn · %.0f/dk" % [seconds, 60.0 / seconds]
	progress_bar.value = 65.0
	if is_instance_valid(gear_icon):
		gear_icon.self_modulate = TEAL if preview_working else GOLD
