extends PanelContainer
## 9 araştırmalık teknoloji ağacını (A-01 – A-09) kademelerine göre gösteren ve seçim yaptıran panel.

signal research_selected(tech_id: String)
signal unlock_all_requested()
signal close_requested()

const INK := Color("dce9ef")
const MUTED := Color("8ca5b6")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
var cards: Dictionary = {}
var status_label: Label
var unlock_all_button: Button

func build(catalog: Dictionary) -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var dialog := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f1d28")
	style.border_color = Color("30495b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	dialog.add_theme_stylebox_override("panel", style)
	margin.add_child(dialog)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	vbox.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := Label.new()
	title.text = "TEKNOLOJİ AĞACI  (K-001 & K-007 — 9 Araştırma)"
	title.add_theme_font_size_override("font_size", 20)
	title_box.add_child(title)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", MUTED)
	title_box.add_child(status_label)
	unlock_all_button = Button.new()
	unlock_all_button.text = "Tüm Kilitleri Aç (Serbest Mod)"
	unlock_all_button.custom_minimum_size.y = 36
	unlock_all_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	unlock_all_button.pressed.connect(func() -> void: unlock_all_requested.emit())
	header.add_child(unlock_all_button)
	var close_btn := Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(90, 36)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_btn)
	vbox.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	scroll.add_child(columns)
	var tier_titles := {
		1: "1. KADEME — Temel İmalat, Döküm ve İletkenler",
		2: "2. KADEME — Mekanik, Bobin, Motor ve Elektronik",
		3: "3. KADEME — Algılama ve Otomasyon Sistemleri"
	}
	var tier_boxes := {}
	for tier in [1, 2, 3]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 10)
		columns.add_child(col)
		var t_head := Label.new()
		t_head.text = tier_titles[tier]
		t_head.add_theme_font_size_override("font_size", 14)
		t_head.add_theme_color_override("font_color", TEAL)
		col.add_child(t_head)
		tier_boxes[tier] = col
	for tech_id in catalog.get("researches", {}):
		var spec: Dictionary = catalog.researches[tech_id]
		var tier: int = int(spec.get("tier", 1))
		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("162938")
		card_style.border_color = Color("2b475c")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_style)
		tier_boxes[tier].add_child(card)
		var c_box := VBoxContainer.new()
		c_box.add_theme_constant_override("separation", 6)
		card.add_child(c_box)
		var name_lbl := Label.new()
		name_lbl.text = str(spec.name)
		name_lbl.add_theme_font_size_override("font_size", 15)
		c_box.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = str(spec.get("description", ""))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", MUTED)
		c_box.add_child(desc_lbl)
		var recipe: Dictionary = catalog.recipes[spec.recipe]
		var in_parts: PackedStringArray = []
		for p in recipe.inputs:
			in_parts.append("%d %s" % [int(recipe.inputs[p]), catalog.products[p].name.to_lower()])
		var req_lbl := Label.new()
		req_lbl.text = "Deney girdisi: " + " + ".join(in_parts)
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		req_lbl.add_theme_font_size_override("font_size", 12)
		c_box.add_child(req_lbl)
		var prereqs: Array = spec.get("prerequisites", [])
		var pre_lbl := Label.new()
		pre_lbl.text = "Ön koşul: Başlangıç" if prereqs.is_empty() else ("Ön koşul: " + ", ".join(PackedStringArray(prereqs)))
		pre_lbl.add_theme_font_size_override("font_size", 11)
		pre_lbl.add_theme_color_override("font_color", MUTED)
		c_box.add_child(pre_lbl)
		var bar := ProgressBar.new()
		bar.max_value = float(spec.experiments)
		bar.custom_minimum_size.y = 10
		bar.show_percentage = false
		c_box.add_child(bar)
		var row := HBoxContainer.new()
		c_box.add_child(row)
		var prog_lbl := Label.new()
		prog_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prog_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(prog_lbl)
		var select_btn := Button.new()
		select_btn.custom_minimum_size = Vector2(140, 30)
		select_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var t_id := str(tech_id)
		select_btn.pressed.connect(func() -> void: research_selected.emit(t_id))
		row.add_child(select_btn)
		cards[t_id] = {
			"name_lbl": name_lbl,
			"bar": bar,
			"prog_lbl": prog_lbl,
			"button": select_btn,
			"experiments": int(spec.experiments)
		}

func refresh(sim: RefCounted) -> void:
	if not visible:
		return
	var done_total: int = sim.completed_researches.size()
	var all_total: int = sim.catalog.researches.size()
	status_label.text = "Tamamlanan araştırma: %d / %d  ·  Laboratuvar kartları aktif araştırmanın girdilerini tüketir." % [done_total, all_total]
	unlock_all_button.text = "Serbest Mod Açık (Tüm Makineler Açık)" if sim.sandbox_mode else "Tüm Kilitleri Aç (Serbest Mod)"
	unlock_all_button.disabled = sim.sandbox_mode
	for tech_id in cards:
		var view: Dictionary = cards[tech_id]
		var progress_val: int = int(sim.research_progress.get(tech_id, 0))
		var total_val: int = int(view.experiments)
		view.bar.value = progress_val
		view.prog_lbl.text = "%d / %d deney" % [progress_val, total_val]
		if tech_id in sim.completed_researches:
			view.name_lbl.add_theme_color_override("font_color", TEAL)
			view.button.text = "Tamamlandı"
			view.button.disabled = true
		elif sim.active_research == tech_id:
			view.name_lbl.add_theme_color_override("font_color", GOLD)
			view.button.text = "✓ Aktif Araştırma"
			view.button.disabled = true
		elif sim.can_research(tech_id):
			view.name_lbl.add_theme_color_override("font_color", INK)
			view.button.text = "Araştırmayı Seç"
			view.button.disabled = false
		else:
			view.name_lbl.add_theme_color_override("font_color", MUTED)
			view.button.text = "Ön Koşul Kilitli"
			view.button.disabled = true
