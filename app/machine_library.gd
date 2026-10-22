extends PanelContainer
## Sol kütüphane: [Makineler | Ürünler] sekmeleri, makine altında üretilen ürün listesi ve arama.

signal machine_requested(kind: String)
signal machine_with_recipe_requested(kind: String, recipe_id: String)

const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const LOCKED_COLOR := Color("556b7a")
var search: LineEdit
var tab_machines_btn: Button
var tab_products_btn: Button
var machines_list: VBoxContainer
var products_list: VBoxContainer
var entries: Dictionary = {}
var product_entries: Dictionary = {}
var empty: Label
var result_count: Label
var active_tab := "machines"

func build(catalog: Dictionary) -> void:
	custom_minimum_size.x = 230
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	body.add_child(tabs)
	tab_machines_btn = Button.new()
	tab_machines_btn.text = "Makineler"
	tab_machines_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_machines_btn.custom_minimum_size.y = 30
	tab_machines_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab_machines_btn.pressed.connect(func() -> void: _switch_tab("machines"))
	tabs.add_child(tab_machines_btn)
	tab_products_btn = Button.new()
	tab_products_btn.text = "Ürünler (24)"
	tab_products_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_products_btn.custom_minimum_size.y = 30
	tab_products_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab_products_btn.pressed.connect(func() -> void: _switch_tab("products"))
	tabs.add_child(tab_products_btn)
	search = LineEdit.new()
	search.placeholder_text = "Makine veya ürün ara..."
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 32
	body.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)
	machines_list = VBoxContainer.new()
	machines_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	machines_list.add_theme_constant_override("separation", 6)
	container.add_child(machines_list)
	products_list = VBoxContainer.new()
	products_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products_list.add_theme_constant_override("separation", 6)
	products_list.visible = false
	container.add_child(products_list)
	_build_machine_entries(catalog)
	_build_product_entries(catalog)
	empty = Label.new()
	empty.text = "Eşleşen sonuç yok."
	empty.add_theme_color_override("font_color", MUTED)
	empty.visible = false
	container.add_child(empty)
	result_count = Label.new()
	result_count.add_theme_font_size_override("font_size", 11)
	result_count.add_theme_color_override("font_color", MUTED)
	body.add_child(result_count)
	search.text_changed.connect(_filter)
	_switch_tab("machines")

func _switch_tab(tab_name: String) -> void:
	active_tab = tab_name
	machines_list.visible = tab_name == "machines"
	products_list.visible = tab_name == "products"
	tab_machines_btn.add_theme_color_override("font_color", TEAL if tab_name == "machines" else INK)
	tab_products_btn.add_theme_color_override("font_color", TEAL if tab_name == "products" else INK)
	_filter(search.text)

func _build_machine_entries(catalog: Dictionary) -> void:
	var unlock_by: Dictionary = {}
	for tech_id in catalog.get("researches", {}):
		for m_kind in catalog.researches[tech_id].get("unlock_machines", []):
			if not unlock_by.has(m_kind):
				unlock_by[m_kind] = str(tech_id)
	for kind in catalog.machines:
		var spec: Dictionary = catalog.machines[kind]
		var out_names: PackedStringArray = []
		for r_var in spec.get("recipes", [spec.recipe]):
			var r_spec: Dictionary = catalog.recipes[str(r_var)]
			var outs: Array = r_spec.outputs.keys()
			if not outs.is_empty():
				var p_name: String = str(catalog.products[str(outs[0])].name)
				if not (p_name in out_names):
					out_names.append(p_name)
		var outputs_summary := "Üretir: " + " · ".join(out_names) if not out_names.is_empty() else str(spec.get("role", "TÜKETİCİ")).capitalize()
		var button := Button.new()
		button.custom_minimum_size.y = 58
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s\n%s" % [str(spec.get("description", spec.name)), outputs_summary]
		machines_list.add_child(button)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.offset_top = 6
		row.offset_bottom = -6
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(4, 0)
		bar.color = Color(spec.color)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 1)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(content)
		var name_label := Label.new()
		name_label.text = spec.name
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", INK)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(name_label)
		var role_label := Label.new()
		role_label.text = outputs_summary
		role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		role_label.add_theme_font_size_override("font_size", 11)
		role_label.add_theme_color_override("font_color", MUTED)
		role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(role_label)
		var kind_id := str(kind)
		button.pressed.connect(func() -> void: machine_requested.emit(kind_id))
		entries[kind] = {
			"button": button,
			"bar": bar,
			"name_label": name_label,
			"role_label": role_label,
			"base_name": str(spec.name),
			"base_role": outputs_summary,
			"color": Color(spec.color),
			"unlock_tech": str(unlock_by.get(kind, "")),
			"search": _normalize(spec.name + " " + outputs_summary + " " + str(spec.get("description", "")))
		}

func _build_product_entries(catalog: Dictionary) -> void:
	for prod_id in catalog.products:
		var p_spec: Dictionary = catalog.products[prod_id]
		var producers: Array = []
		for kind in catalog.machines:
			var m_spec: Dictionary = catalog.machines[kind]
			for r_var in m_spec.get("recipes", [m_spec.recipe]):
				var r_id := str(r_var)
				var r_spec: Dictionary = catalog.recipes[r_id]
				var outs: Array = r_spec.outputs.keys()
				if outs.is_empty():
					continue
				if str(outs[0]) == str(prod_id) or (prod_id == "metal_scrap" and r_spec.outputs.has("metal_scrap")):
					var in_parts: PackedStringArray = []
					for in_p in r_spec.inputs:
						in_parts.append("%d %s" % [int(r_spec.inputs[in_p]), catalog.products[in_p].name.to_lower()])
					var in_text := "Hammadde" if in_parts.is_empty() else " + ".join(in_parts)
					producers.append({
						"kind": str(kind),
						"machine_name": str(m_spec.name),
						"recipe": r_id,
						"inputs_text": in_text
					})
		var button := Button.new()
		button.custom_minimum_size.y = 56
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		products_list.add_child(button)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.offset_top = 5
		row.offset_bottom = -5
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(4, 0)
		bar.color = Color(p_spec.color)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 1)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(content)
		var name_label := Label.new()
		name_label.text = str(p_spec.name)
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(p_spec.color))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(name_label)
		var sub_label := Label.new()
		var sub_parts: PackedStringArray = []
		for pr in producers:
			sub_parts.append("%s (%s)" % [pr.machine_name, pr.inputs_text])
		var sub_text := " · ".join(sub_parts) if not sub_parts.is_empty() else "Yan ürün"
		sub_label.text = sub_text
		sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_label.add_theme_font_size_override("font_size", 10)
		sub_label.add_theme_color_override("font_color", MUTED)
		sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(sub_label)
		var p_key := str(prod_id)
		button.pressed.connect(func() -> void:
			var entry_data: Dictionary = product_entries[p_key]
			var chosen_kind: String = str(entry_data.get("active_kind", ""))
			var chosen_recipe: String = str(entry_data.get("active_recipe", ""))
			if not chosen_kind.is_empty():
				machine_with_recipe_requested.emit(chosen_kind, chosen_recipe))
		product_entries[p_key] = {
			"button": button,
			"bar": bar,
			"name_label": name_label,
			"sub_label": sub_label,
			"base_name": str(p_spec.name),
			"base_sub": sub_text,
			"color": Color(p_spec.color),
			"producers": producers,
			"active_kind": str(producers[0].kind) if not producers.is_empty() else "",
			"active_recipe": str(producers[0].recipe) if not producers.is_empty() else "",
			"search": _normalize(str(p_spec.name) + " " + sub_text)
		}

func refresh_locks(sim: RefCounted) -> void:
	var unlocked_count := 0
	for kind in entries:
		var entry: Dictionary = entries[kind]
		var unlocked: bool = sim.is_machine_unlocked(str(kind))
		if unlocked:
			unlocked_count += 1
		entry.button.disabled = not unlocked
		entry.button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
		if unlocked:
			entry.bar.color = entry.color
			entry.name_label.text = entry.base_name
			entry.name_label.add_theme_color_override("font_color", INK)
			entry.role_label.text = entry.base_role
		else:
			entry.bar.color = LOCKED_COLOR
			entry.name_label.text = "🔒 %s (%s)" % [entry.base_name, entry.unlock_tech]
			entry.name_label.add_theme_color_override("font_color", LOCKED_COLOR)
			entry.role_label.text = entry.base_role
	for prod_id in product_entries:
		var p_entry: Dictionary = product_entries[prod_id]
		var chosen_kind := ""
		var chosen_recipe := ""
		var need_tech := ""
		for pr in p_entry.producers:
			if sim.is_machine_unlocked(str(pr.kind)) and sim.is_recipe_unlocked(str(pr.recipe)):
				chosen_kind = str(pr.kind)
				chosen_recipe = str(pr.recipe)
				break
			elif need_tech.is_empty():
				need_tech = sim.unlock_tech_for_recipe(str(pr.recipe))
				if need_tech.is_empty():
					need_tech = sim.unlock_tech_for_machine(str(pr.kind))
		p_entry.active_kind = chosen_kind
		p_entry.active_recipe = chosen_recipe
		var p_unlocked := not chosen_kind.is_empty()
		p_entry.button.disabled = not p_unlocked
		if p_unlocked:
			p_entry.bar.color = p_entry.color
			p_entry.name_label.text = p_entry.base_name
			p_entry.name_label.add_theme_color_override("font_color", p_entry.color)
			p_entry.button.tooltip_text = "%s üreten makineyi (%s) eklemek için tıkla." % [p_entry.base_name, sim.catalog.machines[chosen_kind].name]
		else:
			p_entry.bar.color = LOCKED_COLOR
			var suffix := (" (%s)" % need_tech) if not need_tech.is_empty() else ""
			p_entry.name_label.text = "🔒 %s%s" % [p_entry.base_name, suffix]
			p_entry.name_label.add_theme_color_override("font_color", LOCKED_COLOR)
			p_entry.button.tooltip_text = "%s araştırmasıyla açılır." % need_tech
	result_count.text = "%d/%d makine açık" % [unlocked_count, entries.size()]

func _normalize(text: String) -> String:
	return text.to_lower().replace("ı", "i").replace("İ", "i").replace("ü", "u").replace("ö", "o").replace("ç", "c").replace("ş", "s").replace("ğ", "g")

func _filter(query: String) -> void:
	var count := 0
	var normalized := _normalize(query.strip_edges())
	var target_dict: Dictionary = entries if active_tab == "machines" else product_entries
	for entry in target_dict.values():
		entry.button.visible = normalized.is_empty() or normalized in entry.search
		if entry.button.visible:
			count += 1
	empty.visible = count == 0
