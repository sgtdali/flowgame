extends PanelContainer
## Seçili kartın reçete seçimi, hız/kapasite özeti, stok tamponları ve tek tıkla üretici makine kurup bağlama paneli.

signal toggle_requested(id: String)
signal speed_requested(id: String)
signal recipe_selected(id: String, recipe_id: String)
signal clear_outputs_requested(id: String)
signal open_research_requested()
signal spawn_supplier_requested(target_id: String, product: String, supplier_kind: String, supplier_recipe: String)
signal close_requested()

const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
const Simulation = preload("res://sim/production_sim.gd")
var selected_id := ""
var last_recipe := ""
var last_unlocked_hash := ""
var placeholder: Label
var details: VBoxContainer
var title_label: Label
var role_label: Label
var recipe_label: Label
var recipe_buttons_box: VBoxContainer
var work_value: Label
var speed_value: Label
var duration_value: Label
var capacity_value: Label
var capacity_title: Label
var state: Label
var progress: ProgressBar
var inventories: VBoxContainer
var clear_button: Button
var speed_button: Button
var toggle_button: Button
var stocks: Array = []
var totals: Label

func build() -> void:
	custom_minimum_size.x = 290
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	visible = false
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	var head_row := HBoxContainer.new()
	outer.add_child(head_row)
	role_label = Label.new()
	role_label.text = "SEÇİLİ MAKİNE"
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", MUTED)
	head_row.add_child(role_label)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 26)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	head_row.add_child(close_btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	placeholder = Label.new()
	placeholder.text = "Bir kart seç."
	placeholder.add_theme_color_override("font_color", MUTED)
	body.add_child(placeholder)
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	details.visible = false
	body.add_child(details)
	title_label = _text("", 18)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_label = _text("", 12)
	recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_label.add_theme_color_override("font_color", MUTED)
	recipe_buttons_box = VBoxContainer.new()
	recipe_buttons_box.add_theme_constant_override("separation", 4)
	details.add_child(recipe_buttons_box)
	_separator()
	var state_row := HBoxContainer.new()
	details.add_child(state_row)
	var state_caption := Label.new()
	state_caption.text = "Durum"
	state_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_caption.add_theme_font_size_override("font_size", 12)
	state_caption.add_theme_color_override("font_color", MUTED)
	state_row.add_child(state_caption)
	state = Label.new()
	state.add_theme_font_size_override("font_size", 13)
	state_row.add_child(state)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 10
	progress.show_percentage = false
	details.add_child(progress)
	_separator()
	work_value = _field("Gereken iş")
	speed_value = _field("İşleme hızı")
	duration_value = _field("Çevrim süresi")
	var row := HBoxContainer.new()
	details.add_child(row)
	capacity_title = Label.new()
	capacity_title.text = "Üretim kapasitesi"
	capacity_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capacity_title.add_theme_font_size_override("font_size", 12)
	capacity_title.add_theme_color_override("font_color", MUTED)
	row.add_child(capacity_title)
	capacity_value = Label.new()
	capacity_value.add_theme_font_size_override("font_size", 13)
	row.add_child(capacity_value)
	_separator()
	_heading("Girdiler, Nerede Üretilir & Tamponlar")
	inventories = VBoxContainer.new()
	inventories.add_theme_constant_override("separation", 10)
	details.add_child(inventories)
	clear_button = Button.new()
	clear_button.text = "Çıkış Tamponunu Boşalt"
	clear_button.custom_minimum_size.y = 30
	clear_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clear_button.pressed.connect(func() -> void:
		if not selected_id.is_empty():
			clear_outputs_requested.emit(selected_id))
	details.add_child(clear_button)
	totals = _text("", 11)
	totals.add_theme_color_override("font_color", MUTED)
	var bottom_actions := HBoxContainer.new()
	bottom_actions.add_theme_constant_override("separation", 6)
	outer.add_child(bottom_actions)
	toggle_button = Button.new()
	toggle_button.custom_minimum_size.y = 36
	toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle_button.pressed.connect(func() -> void:
		if not selected_id.is_empty():
			toggle_requested.emit(selected_id))
	bottom_actions.add_child(toggle_button)
	speed_button = Button.new()
	speed_button.text = "20/40 Hız"
	speed_button.custom_minimum_size.y = 36
	speed_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	speed_button.tooltip_text = "Makine işleme hızını 20 ve 40 birim/sn arasında değiştirir."
	speed_button.pressed.connect(func() -> void:
		if not selected_id.is_empty():
			speed_requested.emit(selected_id))
	bottom_actions.add_child(speed_button)

func _text(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	details.add_child(label)
	return label

func _heading(text: String) -> void:
	var lbl := _text(text, 12)
	lbl.add_theme_color_override("font_color", MUTED)

func _separator() -> void:
	details.add_child(HSeparator.new())

func _field(text: String) -> Label:
	var row := HBoxContainer.new()
	details.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 13)
	row.add_child(value)
	return value

func clear_selection() -> void:
	selected_id = ""
	last_recipe = ""
	last_unlocked_hash = ""
	visible = false
	placeholder.visible = true
	details.visible = false
	toggle_button.visible = false
	stocks.clear()
	for child in inventories.get_children():
		inventories.remove_child(child)
		child.queue_free()
	for child in recipe_buttons_box.get_children():
		recipe_buttons_box.remove_child(child)
		child.queue_free()

func _unlocked_signature(sim: Simulation) -> String:
	return "%d:%d:%s" % [sim.unlocked_machines.size(), sim.unlocked_recipes.size(), str(sim.sandbox_mode)]

func show_machine(sim: Simulation, id: String) -> void:
	if not sim.machines.has(id):
		clear_selection()
		return
	var machine: Dictionary = sim.machines[id]
	var sig := _unlocked_signature(sim)
	if selected_id != id or last_recipe != str(machine.recipe) or last_unlocked_hash != sig:
		clear_selection()
		selected_id = id
		last_recipe = str(machine.recipe)
		last_unlocked_hash = sig
		var spec: Dictionary = sim.catalog.machines[machine.kind]
		var recipe: Dictionary = sim.recipe_for(id)
		role_label.text = str(spec.get("role", "MAKİNE"))
		title_label.text = "%s  #%s" % [spec.name, id.trim_prefix("machine_")]
		title_label.add_theme_color_override("font_color", Color(spec.color))
		recipe_label.text = _products_text(sim, recipe.inputs, "Kaynak") + " → " + _products_text(sim, recipe.outputs, "Tüketim")
		_build_recipe_selector(sim, id, machine, spec)
		for field in ["input", "output"]:
			var products: Dictionary = recipe.inputs if field == "input" else recipe.outputs
			for product in products:
				var p_id := str(product)
				var column := VBoxContainer.new()
				column.add_theme_constant_override("separation", 4)
				inventories.add_child(column)
				var label := Label.new()
				label.add_theme_font_size_override("font_size", 12)
				label.add_theme_color_override("font_color", Color(sim.catalog.products[p_id].color))
				column.add_child(label)
				var bar := ProgressBar.new()
				bar.max_value = float(spec[field + "_capacity"])
				bar.custom_minimum_size.y = 7
				bar.show_percentage = false
				column.add_child(bar)
				if field == "input":
					_build_supplier_helpers(sim, id, p_id, column)
				stocks.append({"field": field, "product": p_id, "label": label, "bar": bar, "capacity": int(spec[field + "_capacity"])})
		clear_button.visible = not recipe.outputs.is_empty()
	visible = true
	placeholder.visible = false
	details.visible = true
	toggle_button.visible = true
	update_values(sim)

func _build_supplier_helpers(sim: Simulation, target_id: String, product: String, parent: VBoxContainer) -> void:
	var producers: Array = sim.producers_for(product)
	for info in producers:
		var source_lbl := Label.new()
		source_lbl.text = "↳ Üretici: %s (%s)" % [info.machine_name, info.inputs_text]
		source_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source_lbl.add_theme_font_size_override("font_size", 11)
		source_lbl.add_theme_color_override("font_color", MUTED)
		parent.add_child(source_lbl)
		var btn := Button.new()
		btn.custom_minimum_size.y = 26
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if info.unlocked:
			btn.text = "+ %s Kur ve Bağla" % info.machine_name
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.tooltip_text = "%s (%s) kartını sol tarafa ekler ve bu girişe otomatik bağlar." % [info.machine_name, info.recipe_name]
		else:
			btn.text = "🔒 %s (%s ile açılır)" % [info.machine_name, info.unlock_tech]
			btn.disabled = true
			btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		var t_id := target_id
		var p_id := product
		var s_kind := str(info.kind)
		var s_recipe := str(info.recipe)
		btn.pressed.connect(func() -> void: spawn_supplier_requested.emit(t_id, p_id, s_kind, s_recipe))
		parent.add_child(btn)

func _build_recipe_selector(sim: Simulation, id: String, machine: Dictionary, spec: Dictionary) -> void:
	if machine.kind == "lab":
		var btn := Button.new()
		btn.text = "🔬 Araştırma Hedefi Seç"
		btn.custom_minimum_size.y = 32
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func() -> void: open_research_requested.emit())
		recipe_buttons_box.add_child(btn)
		return
	var allowed: Array = spec.get("recipes", [spec.recipe])
	if allowed.size() <= 1:
		return
	var unlock_by: Dictionary = {}
	for tech_id in sim.catalog.get("researches", {}):
		for r_id in sim.catalog.researches[tech_id].get("unlock_recipes", []):
			if not unlock_by.has(r_id):
				unlock_by[r_id] = str(tech_id)
	for r_var in allowed:
		var r_id := str(r_var)
		var r_spec: Dictionary = sim.catalog.recipes[r_id]
		var unlocked := sim.is_recipe_unlocked(r_id)
		var btn := Button.new()
		btn.custom_minimum_size.y = 28
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var r_name: String = str(r_spec.get("name", r_id))
		if r_id == str(machine.recipe):
			btn.text = "● " + r_name
			btn.add_theme_color_override("font_color", TEAL)
		elif unlocked:
			btn.text = "○ " + r_name
		else:
			btn.text = "🔒 %s (%s)" % [r_name, str(unlock_by.get(r_id, ""))]
			btn.disabled = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
		var target_id := id
		var target_recipe := r_id
		btn.pressed.connect(func() -> void: recipe_selected.emit(target_id, target_recipe))
		recipe_buttons_box.add_child(btn)

func _products_text(sim: Simulation, products: Dictionary, empty_text: String) -> String:
	var parts: PackedStringArray = []
	for product in products:
		parts.append("%d %s" % [int(products[product]), sim.catalog.products[product].name.to_lower()])
	return empty_text if parts.is_empty() else " + ".join(parts)

func update_values(sim: Simulation) -> void:
	if selected_id.is_empty():
		return
	if not sim.machines.has(selected_id):
		clear_selection()
		return
	var machine: Dictionary = sim.machines[selected_id]
	if last_recipe != str(machine.recipe) or last_unlocked_hash != _unlocked_signature(sim):
		show_machine(sim, selected_id)
		return
	var recipe: Dictionary = sim.recipe_for(selected_id)
	var seconds := float(recipe.work) / float(machine.speed)
	work_value.text = "%.0f birim" % recipe.work
	speed_value.text = "%.0f iş/sn" % machine.speed
	duration_value.text = "%.1f sn" % seconds
	var primary_out := sim.output_product(selected_id)
	var output_count := 1
	if not primary_out.is_empty():
		output_count = int(recipe.outputs[primary_out])
	capacity_title.text = "Üretim kapasitesi" if not recipe.outputs.is_empty() else "Tüketim kapasitesi"
	capacity_value.text = "%.1f adet/dk" % (output_count * 60.0 / seconds)
	state.text = machine.status
	state.add_theme_color_override("font_color", TEAL if machine.running else GOLD)
	progress.value = (1.0 - float(machine.remaining) / float(recipe.work)) * 100.0 if machine.running else 0.0
	for stock in stocks:
		var value := int(machine[stock.field].get(stock.product, 0))
		var direction := "Giriş" if stock.field == "input" else "Çıkış"
		stock.label.text = "%s · %s  (%d/%d)" % [direction, sim.catalog.products[stock.product].name, value, stock.capacity]
		stock.bar.value = value
	totals.text = "Tamamlanan: %d  ·  Alınan: %d" % [machine.completed, machine.received]
	toggle_button.text = "Durdur" if machine.enabled else "Çalıştır"
	speed_button.text = "%d iş/sn" % int(machine.speed)
