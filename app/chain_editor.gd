extends Control
## Üretim Zinciri Node Editörü (Bağımsız Ürün Akışı Tasarım Aracı).
## Yalnızca ürünlerin birbirleriyle olan dönüşüm bağlarını (hangi üründen kaç adet
## girdiyle hangi ürünün kaç adet çıktığını) görsel node'lar üzerinden düzenler ve
## doğrudan res://data/prototype.json dosyasına aktarır.

const FlowGraph = preload("res://app/flow_graph.gd")
const Icons = preload("res://app/icons.gd")
const Simulation = preload("res://sim/production_sim.gd")

const CATALOG_PATH := "res://data/prototype.json"
const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
const DANGER := Color("e0634b")
const BG_DARK := Color("081119")
const PANEL_BG := Color("0f1d29")
const CARD_BG := Color("152431")
const CARD_HEADER := Color("1d3244")
const BORDER := Color("294356")

var catalog: Dictionary = {}
var sim_helper: RefCounted
var graph: GraphEdit
var nodes: Dictionary = {}
## product_id -> {left_port_idx: {"recipe_id": String, "input_product": String}}
var port_map: Dictionary = {}
var selected_node_id := ""
var highlight_ancestors := true
var dirty := false
var _syncing := false

var status_label: Label
var dirty_badge: Label
var inspector_scroll: ScrollContainer
var inspector_box: VBoxContainer
var new_product_modal: PanelContainer
var new_id_edit: LineEdit
var new_name_edit: LineEdit
var new_tier_spin: SpinBox
var new_color_picker: ColorPickerButton

func _ready() -> void:
	DisplayServer.window_set_title("Flowgame — Ürün Akışı ve Zincir Editörü")
	_build_theme()
	_load_catalog_from_disk()
	_build_ui()
	_rebuild_all_nodes()
	if not catalog.has("editor_layout") or not (catalog.editor_layout is Dictionary) or catalog.editor_layout.is_empty():
		_auto_layout()
	else:
		_apply_saved_layout()
	_frame_graph.call_deferred()
	if "--chain-editor-smoke" in OS.get_cmdline_user_args():
		_run_smoke_test.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			_save_catalog_to_disk()
			get_viewport().set_input_as_handled()

func _build_theme() -> void:
	var skin := Theme.new()
	skin.default_font_size = 13
	skin.set_color("font_color", "Label", INK)
	skin.set_color("font_color", "Button", INK)
	skin.set_stylebox("normal", "Button", _box(Color("162836"), BORDER, 5, 8, 5))
	skin.set_stylebox("hover", "Button", _box(Color("213b4d"), TEAL, 5, 8, 5))
	skin.set_stylebox("pressed", "Button", _box(Color("295258"), TEAL, 5, 8, 5))
	skin.set_stylebox("disabled", "Button", _box(Color("101c26"), Color("1b2d3b"), 5, 8, 5))
	skin.set_stylebox("normal", "LineEdit", _box(Color("0b1620"), BORDER, 4, 6, 4))
	skin.set_stylebox("focus", "LineEdit", _box(Color("0f1f2d"), TEAL, 4, 6, 4))
	theme = skin

func _box(background: Color, border: Color, radius: int = 6, pad_x: int = 10, pad_y: int = 6, border_w: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	return style

func _label(text: String, font_size: int = 13, color: Color = INK) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _button(text: String, action: Callable, parent: Node = null, accent: Color = Color.TRANSPARENT) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if accent != Color.TRANSPARENT:
		btn.add_theme_stylebox_override("normal", _box(accent.darkened(0.65), accent, 5, 10, 5))
		btn.add_theme_stylebox_override("hover", _box(accent.darkened(0.5), accent.lightened(0.2), 5, 10, 5))
	btn.pressed.connect(action)
	if parent != null:
		parent.add_child(btn)
	return btn

func _refresh_sim_helper() -> void:
	Icons.clear_cache()
	if sim_helper == null:
		sim_helper = Simulation.new()
	sim_helper.catalog = catalog

func _load_catalog_from_disk() -> void:
	var raw := FileAccess.get_file_as_string(CATALOG_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		catalog = parsed.duplicate(true)
	_refresh_sim_helper()
	dirty = false
	_update_dirty_badge()

func _mark_dirty(msg: String = "") -> void:
	dirty = true
	_refresh_sim_helper()
	_update_dirty_badge()
	if not msg.is_empty() and status_label != null:
		status_label.text = msg

func _update_dirty_badge() -> void:
	if dirty_badge == null:
		return
	if dirty:
		dirty_badge.text = "● Değişiklik var (Ctrl+S)"
		dirty_badge.add_theme_color_override("font_color", GOLD)
	else:
		dirty_badge.text = "✓ Güncel"
		dirty_badge.add_theme_color_override("font_color", TEAL)

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BG_DARK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# Üst Araç Çubuğu
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _box(PANEL_BG, BORDER, 0, 12, 7))
	root_vbox.add_child(header)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	header.add_child(head)

	var title := _label("⚙ ÜRÜN AKIŞ EDİTÖRÜ", 15, TEAL)
	head.add_child(title)
	head.add_child(VSeparator.new())

	_button("+ Yeni Ürün", _open_new_product_modal, head, TEAL).tooltip_text = "Üretim zincirine yeni bir ürün ekler."
	_button("Otomatik Diz", _on_auto_layout_pressed, head).tooltip_text = "Ürün kartlarını kademelerine (K1–K5) göre soldan sağa düzenli hizalar."
	_button("Tümünü Gör", _frame_graph, head).tooltip_text = "Bütün ürün ağını ekrana sığdırır."
	_button("1:1 Yakınlaş", _zoom_selected_or_center, head).tooltip_text = "Seçili ürüne veya merkeze %100 yakınlaşır."

	var anc_toggle := CheckBox.new()
	anc_toggle.text = "Öncülleri Vurgula"
	anc_toggle.button_pressed = highlight_ancestors
	anc_toggle.tooltip_text = "Seçilen ürünün üretim zincirindeki öncüllerini parlak tutar, diğer ürünlerin ve çizgilerin opaklığını düşürür."
	anc_toggle.toggled.connect(func(on: bool) -> void:
		highlight_ancestors = on
		_update_ancestor_highlight()
	)
	head.add_child(anc_toggle)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)

	dirty_badge = _label("", 12, TEAL)
	head.add_child(dirty_badge)
	head.add_child(VSeparator.new())

	_button("Doğrula", _validate_chain, head).tooltip_text = "Ürün zincirinde girdisi eksik kademe 2+ ürün olup olmadığını denetler."
	_button("💾 Kaydet", _save_catalog_to_disk, head, GOLD).tooltip_text = "Değişiklikleri doğrudan data/prototype.json dosyasına kaydeder (Ctrl+S)."
	_button("Geri Yükle", _reload_from_disk, head).tooltip_text = "Kaydedilmemiş değişiklikleri iptal edip diskteki dosyayı yeniden yükler."
	_button("▶ Oyunu Aç", _launch_game_instance, head, TEAL).tooltip_text = "Gerçek oyunu ayrı pencerede başlatarak güncel ürün zincirini test eder."

	# Orta Çalışma Alanı (Sol: GraphEdit, Sağ: Denetçi Paneli)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = -360
	root_vbox.add_child(split)

	graph = FlowGraph.new()
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph.right_disconnects = true
	graph.minimap_enabled = true
	graph.snapping_enabled = true
	graph.snapping_distance = 20
	graph.get_menu_hbox().visible = false
	graph.add_theme_stylebox_override("panel", _box(Color("09131c"), Color.TRANSPARENT, 0, 0, 0))
	graph.add_theme_color_override("grid_minor", Color("10202c"))
	graph.add_theme_color_override("grid_major", Color("183040"))
	graph.add_theme_color_override("activity", Color(0.10, 0.17, 0.23, 0.14))
	graph.add_valid_connection_type(0, 0)
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	graph.node_selected.connect(func(node: Node) -> void: _select_node(str(node.name)))
	graph.node_deselected.connect(func(_node: Node) -> void: _on_node_deselected.call_deferred())
	graph.delete_nodes_request.connect(_on_delete_nodes_request)
	split.add_child(graph)

	# Sağ Denetçi Paneli
	var inspector_panel := PanelContainer.new()
	inspector_panel.custom_minimum_size.x = 350
	inspector_panel.add_theme_stylebox_override("panel", _box(PANEL_BG, BORDER, 0, 10, 10))
	split.add_child(inspector_panel)

	inspector_scroll = ScrollContainer.new()
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_panel.add_child(inspector_scroll)

	var insp_margin := MarginContainer.new()
	insp_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_margin.add_theme_constant_override("margin_left", 4)
	insp_margin.add_theme_constant_override("margin_right", 10)
	insp_margin.add_theme_constant_override("margin_top", 2)
	insp_margin.add_theme_constant_override("margin_bottom", 8)
	inspector_scroll.add_child(insp_margin)

	inspector_box = VBoxContainer.new()
	inspector_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_box.add_theme_constant_override("separation", 10)
	insp_margin.add_child(inspector_box)

	# Alt Durum Çubuğu
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _box(PANEL_BG, BORDER, 0, 14, 5))
	root_vbox.add_child(footer)

	var foot_hbox := HBoxContainer.new()
	foot_hbox.add_theme_constant_override("separation", 16)
	footer.add_child(foot_hbox)

	status_label = _label("İpucu: Bir ürünün sağ çıkışından başka bir ürünün sol girişine çizgi çekerek ürün bağını kurun ve adetleri ayarlayın.", 12, INK)
	foot_hbox.add_child(status_label)

	var foot_spacer := Control.new()
	foot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot_hbox.add_child(foot_spacer)

	var help_lbl := _label("Sağ port → Sol port: Ürün bağla · Bağlantıya sağ tık veya ×: Kaldır · Ctrl+S: Kaydet", 12, MUTED)
	foot_hbox.add_child(help_lbl)

	_build_new_product_modal()
	_update_dirty_badge()
	_refresh_inspector()

## Ürünü ana çıktı olarak üreten reçeteleri döndürür (`outputs` içindeki ilk anahtar o ürün olanlar).
func _recipes_for_product(product_id: String) -> Array[String]:
	var result: Array[String] = []
	for r_var in catalog.recipes.keys():
		var r_id := str(r_var)
		var r_spec: Dictionary = catalog.recipes[r_id]
		var outs: Dictionary = r_spec.get("outputs", {})
		if not outs.is_empty() and str(outs.keys()[0]) == product_id:
			result.append(r_id)
	return result

## Arka planda oyun uyumluluğu için reçeteyi varsayılan bir makineyle ilişkilendirir.
func _machine_for_recipe(recipe_id: String) -> String:
	for m_var in catalog.machines.keys():
		var m_kind := str(m_var)
		var m_spec: Dictionary = catalog.machines[m_kind]
		var allowed: Array = m_spec.get("recipes", [m_spec.get("recipe", "")])
		if recipe_id in allowed or str(m_spec.get("recipe", "")) == recipe_id:
			return m_kind
	return ""

func _assign_recipe_to_machine(recipe_id: String, new_kind: String) -> void:
	for m_var in catalog.machines.keys():
		var m_kind := str(m_var)
		var m_spec: Dictionary = catalog.machines[m_kind]
		var list: Array = m_spec.get("recipes", []).duplicate()
		if recipe_id in list and m_kind != new_kind:
			list.erase(recipe_id)
			m_spec["recipes"] = list
			if str(m_spec.get("recipe", "")) == recipe_id:
				m_spec["recipe"] = str(list[0]) if not list.is_empty() else ""
	if catalog.machines.has(new_kind):
		var target_spec: Dictionary = catalog.machines[new_kind]
		var target_list: Array = target_spec.get("recipes", []).duplicate()
		if not (recipe_id in target_list):
			target_list.append(recipe_id)
		target_spec["recipes"] = target_list
		if str(target_spec.get("recipe", "")).is_empty():
			target_spec["recipe"] = recipe_id

func _set_unlock_source_for_recipe(recipe_id: String, target_tech: String) -> void:
	var init_list: Array = catalog.get("initial_unlocked_recipes", []).duplicate()
	init_list.erase(recipe_id)
	for tech_var in catalog.researches.keys():
		var tech_id := str(tech_var)
		var r_list: Array = catalog.researches[tech_id].get("unlock_recipes", []).duplicate()
		r_list.erase(recipe_id)
		catalog.researches[tech_id]["unlock_recipes"] = r_list
	if target_tech.is_empty():
		init_list.append(recipe_id)
	elif catalog.researches.has(target_tech):
		var target_list: Array = catalog.researches[target_tech].get("unlock_recipes", []).duplicate()
		target_list.append(recipe_id)
		catalog.researches[target_tech]["unlock_recipes"] = target_list
	catalog["initial_unlocked_recipes"] = init_list

func _capture_layout() -> void:
	if not catalog.has("editor_layout") or not (catalog.editor_layout is Dictionary):
		catalog["editor_layout"] = {}
	for node_id in nodes.keys():
		var gnode: GraphNode = nodes[node_id]
		if is_instance_valid(gnode):
			catalog.editor_layout[str(node_id)] = [roundi(gnode.position_offset.x), roundi(gnode.position_offset.y)]

func _apply_saved_layout() -> void:
	var layout_dict: Dictionary = catalog.get("editor_layout", {})
	for node_id in nodes.keys():
		var gnode: GraphNode = nodes[node_id]
		if layout_dict.has(node_id) and layout_dict[node_id] is Array and layout_dict[node_id].size() >= 2:
			gnode.position_offset = Vector2(float(layout_dict[node_id][0]), float(layout_dict[node_id][1]))

func _on_auto_layout_pressed() -> void:
	_auto_layout()
	_mark_dirty("Ürün kartları kademelerine göre otomatik hizalandı.")
	_frame_graph.call_deferred()

func _auto_layout() -> void:
	var by_tier: Dictionary = {}
	for p_var in catalog.products.keys():
		var p_id := str(p_var)
		var tier := int(catalog.products[p_id].get("tier", 1))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(p_id)
	var col_w := 410.0
	var tiers: Array = by_tier.keys()
	tiers.sort()
	for t_var in tiers:
		var t := int(t_var)
		var list: Array = by_tier[t]
		var y_cursor := 40.0
		for i in range(list.size()):
			var p_id := str(list[i])
			if nodes.has(p_id):
				var gnode: GraphNode = nodes[p_id]
				gnode.position_offset = Vector2((t - 1) * col_w + 40.0, y_cursor)
				var h := maxf(gnode.size.y, gnode.get_combined_minimum_size().y)
				y_cursor += h + 32.0
	_capture_layout()

func _zoom_selected_or_center() -> void:
	graph.zoom = 1.0
	if not selected_node_id.is_empty() and nodes.has(selected_node_id):
		var gnode: GraphNode = nodes[selected_node_id]
		var center := gnode.position_offset + gnode.size * 0.5
		graph.scroll_offset = center - graph.size * 0.5
	else:
		graph.scroll_offset = Vector2(400, 180)

func _frame_graph() -> void:
	if nodes.is_empty():
		return
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for gnode: GraphNode in nodes.values():
		min_pt.x = minf(min_pt.x, gnode.position_offset.x)
		min_pt.y = minf(min_pt.y, gnode.position_offset.y)
		var sz := gnode.size if gnode.size.x > 0 else Vector2(280, 150)
		max_pt.x = maxf(max_pt.x, gnode.position_offset.x + sz.x)
		max_pt.y = maxf(max_pt.y, gnode.position_offset.y + sz.y)
	var span := (max_pt - min_pt) + Vector2(120, 120)
	var view := graph.size
	if view.x <= 10 or view.y <= 10:
		return
	graph.zoom = clampf(minf(view.x / maxf(span.x, 1.0), view.y / maxf(span.y, 1.0)), 0.48, 1.0)
	var center := (min_pt + max_pt) * 0.5
	graph.scroll_offset = center * graph.zoom - view * 0.5

func _rebuild_all_nodes() -> void:
	_capture_layout()
	graph.clear_connections()
	for child in graph.get_children():
		if child is GraphNode:
			graph.remove_child(child)
			child.free()
	nodes.clear()
	port_map.clear()

	for p_var in catalog.products.keys():
		var p_id := str(p_var)
		_create_product_node(p_id)

	_apply_saved_layout()
	_sync_connections()

func _rebuild_single_node(product_id: String) -> void:
	var old_pos := Vector2(100, 100)
	if nodes.has(product_id) and is_instance_valid(nodes[product_id]):
		old_pos = nodes[product_id].position_offset
		graph.remove_child(nodes[product_id])
		nodes[product_id].free()
		nodes.erase(product_id)
	port_map.erase(product_id)
	if catalog.products.has(product_id):
		_create_product_node(product_id).position_offset = old_pos
	_sync_connections()

func _style_graph_node(gnode: GraphNode, accent: Color) -> void:
	gnode.add_theme_stylebox_override("panel", _box(CARD_BG, accent.darkened(0.25), 6, 8, 8, 2))
	gnode.add_theme_stylebox_override("panel_selected", _box(CARD_BG.lightened(0.05), GOLD, 6, 8, 8, 2))
	gnode.add_theme_stylebox_override("titlebar", _box(CARD_HEADER, accent, 6, 10, 6, 2))
	gnode.add_theme_stylebox_override("titlebar_selected", _box(CARD_HEADER.lightened(0.08), GOLD, 6, 10, 6, 2))
	gnode.add_theme_constant_override("separation", 5)

func _create_product_node(product_id: String) -> GraphNode:
	var spec: Dictionary = catalog.products[product_id]
	var prod_color := Color.from_string(str(spec.get("color", "7fa6c4")), Color("7fa6c4"))
	var gnode := GraphNode.new()
	gnode.name = product_id
	gnode.title = str(spec.get("name", product_id))
	gnode.custom_minimum_size.x = 284
	_style_graph_node(gnode, prod_color)

	# Titlebar içine ürün ikonu ve kademe rozeti ekle
	var tbar := gnode.get_titlebar_hbox()
	var icon_rect := TextureRect.new()
	icon_rect.texture = Icons.product(sim_helper, product_id)
	icon_rect.custom_minimum_size = Vector2(22, 22)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tbar.add_child(icon_rect)
	tbar.move_child(icon_rect, 0)

	var tier_lbl := _label("K%d" % int(spec.get("tier", 1)), 11, prod_color.lightened(0.25))
	tbar.add_child(tier_lbl)

	port_map[product_id] = {}
	var slot_idx := 0
	var left_port_idx := 0
	var recipes := _recipes_for_product(product_id)

	# Tek reçeteli ürünlerde çıktı adedi doğrudan üst çıkış satırında yer alır
	if recipes.size() == 1:
		var r_id := recipes[0]
		var r_spec: Dictionary = catalog.recipes[r_id]
		var out_row := HBoxContainer.new()
		out_row.add_theme_constant_override("separation", 6)
		out_row.add_child(_label("Üretilen:", 11, MUTED))
		var out_spin := SpinBox.new()
		out_spin.min_value = 1
		out_spin.max_value = 99
		out_spin.step = 1
		out_spin.value = int(r_spec.outputs.get(product_id, 1))
		out_spin.tooltip_text = "Bu girdilerle kaç adet %s üretilir" % gnode.title
		out_spin.value_changed.connect(func(val: float) -> void:
			if _syncing:
				return
			catalog.recipes[r_id].outputs[product_id] = int(val)
			_mark_dirty("%s üretim adedi %d yapıldı." % [gnode.title, int(val)])
			if selected_node_id == product_id:
				_refresh_inspector()
		)
		out_row.add_child(out_spin)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		out_row.add_child(spacer)
		out_row.add_child(_label("ÇIKIŞ ▶", 11, prod_color.lightened(0.2)))
		gnode.add_child(out_row)
		gnode.set_slot(slot_idx, false, 0, Color.WHITE, true, 0, prod_color)
		slot_idx += 1
	else:
		# Çok reçeteli veya reçetesiz (yan ürün) kartlarda üst çıkış satırı
		var out_row := HBoxContainer.new()
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		out_row.add_child(spacer)
		out_row.add_child(_label("ÇIKIŞ ▶", 11, prod_color.lightened(0.2)))
		gnode.add_child(out_row)
		gnode.set_slot(slot_idx, false, 0, Color.WHITE, true, 0, prod_color)
		slot_idx += 1

	for r_idx in range(recipes.size()):
		var r_id := recipes[r_idx]
		var r_spec: Dictionary = catalog.recipes[r_id]

		# Yalnızca birden fazla üretim yolu varsa yöntem başlığı göster
		if recipes.size() > 1:
			var rec_header := PanelContainer.new()
			rec_header.add_theme_stylebox_override("panel", _box(Color("0e1a24"), BORDER, 4, 6, 4))
			var top_line := HBoxContainer.new()
			top_line.add_theme_constant_override("separation", 6)
			rec_header.add_child(top_line)

			var m_lbl := _label("Alternatif #%d" % (r_idx + 1), 11, TEAL)
			m_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_line.add_child(m_lbl)

			top_line.add_child(_label("Üretilen:", 11, MUTED))
			var out_spin := SpinBox.new()
			out_spin.min_value = 1
			out_spin.max_value = 99
			out_spin.step = 1
			out_spin.value = int(r_spec.outputs.get(product_id, 1))
			out_spin.value_changed.connect(func(val: float) -> void:
				if _syncing:
					return
				catalog.recipes[r_id].outputs[product_id] = int(val)
				_mark_dirty("%s üretim adedi %d yapıldı." % [gnode.title, int(val)])
				if selected_node_id == product_id:
					_refresh_inspector()
			)
			top_line.add_child(out_spin)

			var del_rec_btn := _button("×", _delete_recipe.bind(product_id, r_id), top_line)
			del_rec_btn.tooltip_text = "Bu alternatif üretim yolunu kaldır"
			del_rec_btn.custom_minimum_size = Vector2(22, 22)

			gnode.add_child(rec_header)
			gnode.set_slot(slot_idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
			slot_idx += 1

		# Reçetenin Girdi Ürün Satırları (Sol Portlu)
		var inputs: Dictionary = r_spec.get("inputs", {})
		for in_var in inputs.keys():
			var in_prod := str(in_var)
			var in_count := int(inputs[in_prod])
			var in_spec: Dictionary = catalog.products.get(in_prod, {"name": in_prod, "color": "7f99aa"})
			var in_color := Color.from_string(str(in_spec.get("color", "7f99aa")), MUTED)

			var in_row := HBoxContainer.new()
			in_row.add_theme_constant_override("separation", 6)

			var in_icon := TextureRect.new()
			in_icon.texture = Icons.product(sim_helper, in_prod)
			in_icon.custom_minimum_size = Vector2(20, 20)
			in_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			in_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			in_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			in_row.add_child(in_icon)

			var in_name := _label(str(in_spec.get("name", in_prod)), 12, INK)
			in_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			in_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			in_row.add_child(in_name)

			var qty_spin := SpinBox.new()
			qty_spin.min_value = 1
			qty_spin.max_value = 99
			qty_spin.step = 1
			qty_spin.value = in_count
			qty_spin.tooltip_text = "Gereken %s adedi" % str(in_spec.get("name", in_prod))
			qty_spin.value_changed.connect(func(val: float) -> void:
				if _syncing:
					return
				catalog.recipes[r_id].inputs[in_prod] = int(val)
				_mark_dirty("%s → %s girdisi %d adet yapıldı." % [str(in_spec.get("name", in_prod)), gnode.title, int(val)])
				if selected_node_id == product_id:
					_refresh_inspector()
			)
			in_row.add_child(qty_spin)

			var rm_btn := _button("×", _remove_recipe_input.bind(product_id, r_id, in_prod), in_row)
			rm_btn.tooltip_text = "Bu girdiyi kaldır"
			rm_btn.custom_minimum_size = Vector2(24, 24)

			gnode.add_child(in_row)
			gnode.set_slot(slot_idx, true, 0, in_color, false, 0, Color.WHITE)
			port_map[product_id][left_port_idx] = {"recipe_id": r_id, "input_product": in_prod}
			left_port_idx += 1
			slot_idx += 1

		# Yan Ürün Satırları (Varsa)
		for out_var in r_spec.outputs.keys():
			var out_prod := str(out_var)
			if out_prod == product_id:
				continue
			var by_spec: Dictionary = catalog.products.get(out_prod, {"name": out_prod})
			var by_row := HBoxContainer.new()
			by_row.add_theme_constant_override("separation", 6)
			var by_lbl := _label("↳ Yan ürün: %s" % str(by_spec.get("name", out_prod)), 11, GOLD)
			by_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			by_row.add_child(by_lbl)
			var by_spin := SpinBox.new()
			by_spin.min_value = 1
			by_spin.max_value = 99
			by_spin.value = int(r_spec.outputs[out_prod])
			by_spin.value_changed.connect(func(val: float) -> void:
				if _syncing:
					return
				catalog.recipes[r_id].outputs[out_prod] = int(val)
				_mark_dirty("Yan ürün adedi güncellendi.")
			)
			by_row.add_child(by_spin)
			var by_rm := _button("×", _remove_byproduct.bind(product_id, r_id, out_prod), by_row)
			by_rm.custom_minimum_size = Vector2(22, 22)
			gnode.add_child(by_row)
			gnode.set_slot(slot_idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
			slot_idx += 1

		# "+ Girdi Bağla" Açık Giriş Portu Satırı
		var drop_row := HBoxContainer.new()
		drop_row.add_theme_constant_override("separation", 4)
		var add_in_btn := MenuButton.new()
		add_in_btn.text = "⊕ Girdi bağla veya seç..."
		add_in_btn.flat = true
		add_in_btn.add_theme_font_size_override("font_size", 11)
		add_in_btn.add_theme_color_override("font_color", TEAL)
		add_in_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_in_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_populate_product_menu(add_in_btn.get_popup(), product_id, func(chosen_prod: String) -> void:
			_add_recipe_input(product_id, r_id, chosen_prod)
		)
		drop_row.add_child(add_in_btn)

		gnode.add_child(drop_row)
		gnode.set_slot(slot_idx, true, 0, TEAL, false, 0, Color.WHITE)
		port_map[product_id][left_port_idx] = {"recipe_id": r_id, "input_product": ""}
		left_port_idx += 1
		slot_idx += 1

	# Kart Alt Çubuğu (+ Alternatif Yöntem)
	var foot_row := HBoxContainer.new()
	foot_row.add_theme_constant_override("separation", 6)
	var alt_btn := _button("+ Alternatif Yöntem", _add_alternative_recipe.bind(product_id), foot_row)
	alt_btn.add_theme_font_size_override("font_size", 11)
	gnode.add_child(foot_row)
	gnode.set_slot(slot_idx, false, 0, Color.WHITE, false, 0, Color.WHITE)

	gnode.position_offset_changed.connect(func() -> void: _capture_layout())
	graph.add_child(gnode)
	nodes[product_id] = gnode
	return gnode

func _populate_product_menu(popup: PopupMenu, exclude_product: String, callback: Callable) -> void:
	popup.clear()
	var items: Array[String] = []
	for p_var in catalog.products.keys():
		var p_id := str(p_var)
		if p_id == exclude_product:
			continue
		var p_spec: Dictionary = catalog.products[p_id]
		popup.add_item("K%d · %s" % [int(p_spec.get("tier", 1)), str(p_spec.get("name", p_id))])
		items.append(p_id)
	popup.id_pressed.connect(func(idx: int) -> void:
		if idx >= 0 and idx < items.size():
			callback.call(items[idx])
	)

func _sync_connections() -> void:
	graph.clear_connections()
	for target_key in port_map.keys():
		var target_ports: Dictionary = port_map[target_key]
		for port_idx in target_ports.keys():
			var info: Dictionary = target_ports[port_idx]
			var in_prod := str(info.get("input_product", ""))
			if not in_prod.is_empty() and nodes.has(in_prod) and nodes.has(target_key):
				graph.connect_node(StringName(in_prod), 0, StringName(target_key), int(port_idx))
	_update_ancestor_highlight()

## Seçilen ürünün tüm üst üretim zinciri öncüllerini (hammaddelere kadar) bulur.
func _compute_ancestors(start_id: String) -> Dictionary:
	var active: Dictionary = {start_id: true}
	var queue: Array[String] = [start_id]
	while not queue.is_empty():
		var cur: String = str(queue.pop_front())
		var cur_ports: Dictionary = port_map.get(cur, {})
		for port_idx in cur_ports.keys():
			var info: Dictionary = cur_ports[port_idx]
			var in_prod := str(info.get("input_product", ""))
			if not in_prod.is_empty() and nodes.has(in_prod) and not active.has(in_prod):
				active[in_prod] = true
				queue.append(in_prod)
	return active

## Öncül vurgulama açıksa ve bir ürün seçiliyse, öncül olmayan ürünlerin ve bağlantı
## çizgilerinin opaklığını düşürür.
func _update_ancestor_highlight() -> void:
	if graph == null:
		return
	var should_dim := highlight_ancestors and not selected_node_id.is_empty() and nodes.has(selected_node_id)
	var active: Dictionary = _compute_ancestors(selected_node_id) if should_dim else {}
	for k in nodes.keys():
		var id := str(k)
		var gnode: GraphNode = nodes[id]
		if not is_instance_valid(gnode):
			continue
		if not should_dim or active.has(id):
			gnode.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			gnode.modulate = Color(1.0, 1.0, 1.0, 0.22)
	for conn in graph.get_connection_list():
		var from_id := str(conn.from_node)
		var to_id := str(conn.to_node)
		var from_p := int(conn.from_port)
		var to_p := int(conn.to_port)
		var is_active_line := (not should_dim) or (active.has(to_id) and active.has(from_id))
		graph.set_connection_activity(StringName(from_id), from_p, StringName(to_id), to_p, 0.0 if is_active_line else 1.0)

func _on_connection_request(from_node: StringName, _from_port: int, to_node: StringName, to_port: int) -> void:
	var src_prod := str(from_node)
	var dst_key := str(to_node)
	if not catalog.products.has(src_prod):
		return
	if src_prod == dst_key:
		status_label.text = "⚠ Bir ürün doğrudan kendisine girdi olarak bağlanamaz."
		return
	if not port_map.has(dst_key) or not port_map[dst_key].has(to_port):
		return
	var info: Dictionary = port_map[dst_key][to_port]
	var r_id := str(info.get("recipe_id", ""))
	if r_id.is_empty() or not catalog.recipes.has(r_id):
		return
	_add_recipe_input(dst_key, r_id, src_prod)

func _on_disconnection_request(_from_node: StringName, _from_port: int, to_node: StringName, to_port: int) -> void:
	var dst_key := str(to_node)
	if not port_map.has(dst_key) or not port_map[dst_key].has(to_port):
		return
	var info: Dictionary = port_map[dst_key][to_port]
	var r_id := str(info.get("recipe_id", ""))
	var in_prod := str(info.get("input_product", ""))
	if not r_id.is_empty() and not in_prod.is_empty():
		_remove_recipe_input(dst_key, r_id, in_prod)

func _add_recipe_input(product_id: String, recipe_id: String, input_product: String) -> void:
	if not catalog.recipes.has(recipe_id) or not catalog.products.has(input_product):
		return
	var inputs: Dictionary = catalog.recipes[recipe_id].inputs
	if inputs.has(input_product):
		inputs[input_product] = int(inputs[input_product]) + 1
	else:
		inputs[input_product] = 1
	var src_name := str(catalog.products[input_product].name)
	var dst_name := str(catalog.products[product_id].name) if catalog.products.has(product_id) else product_id
	_rebuild_single_node(product_id)
	_select_node(product_id)
	_mark_dirty("✓ %s → %s girdisi olarak bağlandı (%d adet)." % [src_name, dst_name, int(inputs[input_product])])

func _remove_recipe_input(product_id: String, recipe_id: String, input_product: String) -> void:
	if not catalog.recipes.has(recipe_id):
		return
	catalog.recipes[recipe_id].inputs.erase(input_product)
	_rebuild_single_node(product_id)
	_select_node(product_id)
	_mark_dirty("Girdi kaldırıldı: %s" % input_product)

func _add_alternative_recipe(product_id: String) -> void:
	var existing := _recipes_for_product(product_id)
	var suffix := existing.size() + 1
	var new_r_id := "%s_alt_%d" % [product_id, suffix]
	while catalog.recipes.has(new_r_id):
		suffix += 1
		new_r_id = "%s_alt_%d" % [product_id, suffix]
	var p_name := str(catalog.products[product_id].get("name", product_id))
	catalog.recipes[new_r_id] = {
		"name": "%s (Yöntem %d)" % [p_name, suffix],
		"inputs": {},
		"outputs": {product_id: 1},
		"work": 60.0
	}
	var default_machine := "assembler"
	if not existing.is_empty():
		var m := _machine_for_recipe(existing[0])
		if not m.is_empty():
			default_machine = m
	_assign_recipe_to_machine(new_r_id, default_machine)
	_set_unlock_source_for_recipe(new_r_id, "")
	_rebuild_single_node(product_id)
	_select_node(product_id)
	_mark_dirty("✓ %s için alternatif üretim yolu eklendi." % p_name)

func _delete_recipe(product_id: String, recipe_id: String) -> void:
	var existing := _recipes_for_product(product_id)
	if existing.size() <= 1:
		status_label.text = "⚠ Ürünün son üretim yolu silinemez; ürünü tamamen kaldırmak için sağ panelden 'Ürünü Sil' kullanın."
		return
	_assign_recipe_to_machine(recipe_id, "")
	var init_list: Array = catalog.get("initial_unlocked_recipes", []).duplicate()
	init_list.erase(recipe_id)
	catalog["initial_unlocked_recipes"] = init_list
	for tech_var in catalog.researches.keys():
		var r_list: Array = catalog.researches[str(tech_var)].get("unlock_recipes", []).duplicate()
		r_list.erase(recipe_id)
		catalog.researches[str(tech_var)]["unlock_recipes"] = r_list
	catalog.recipes.erase(recipe_id)
	_rebuild_single_node(product_id)
	_select_node(product_id)
	_mark_dirty("Alternatif üretim yolu silindi.")

func _remove_byproduct(product_id: String, recipe_id: String, byproduct_id: String) -> void:
	if catalog.recipes.has(recipe_id):
		catalog.recipes[recipe_id].outputs.erase(byproduct_id)
		_rebuild_single_node(product_id)
		_select_node(product_id)
		_mark_dirty("Yan ürün kaldırıldı: %s" % byproduct_id)

func _select_node(node_id: String) -> void:
	selected_node_id = node_id
	for k in nodes.keys():
		if is_instance_valid(nodes[k]):
			nodes[k].selected = (str(k) == node_id)
	_update_ancestor_highlight()
	_refresh_inspector()

func _on_node_deselected() -> void:
	for k in nodes.keys():
		if is_instance_valid(nodes[k]) and nodes[k].selected:
			return
	if not selected_node_id.is_empty():
		selected_node_id = ""
		_update_ancestor_highlight()
		_refresh_inspector()

func _on_delete_nodes_request(node_names: Array[StringName]) -> void:
	for sname in node_names:
		var id := str(sname)
		if catalog.products.has(id):
			_delete_product(id)

func _delete_product(product_id: String) -> void:
	if not catalog.products.has(product_id):
		return
	var p_name := str(catalog.products[product_id].get("name", product_id))
	for r_id in _recipes_for_product(product_id):
		_assign_recipe_to_machine(r_id, "")
		var init_list: Array = catalog.get("initial_unlocked_recipes", []).duplicate()
		init_list.erase(r_id)
		catalog["initial_unlocked_recipes"] = init_list
		for tech_var in catalog.researches.keys():
			var r_list: Array = catalog.researches[str(tech_var)].get("unlock_recipes", []).duplicate()
			r_list.erase(r_id)
			catalog.researches[str(tech_var)]["unlock_recipes"] = r_list
		catalog.recipes.erase(r_id)
	for r_var in catalog.recipes.keys():
		var r_spec: Dictionary = catalog.recipes[str(r_var)]
		r_spec.inputs.erase(product_id)
		r_spec.outputs.erase(product_id)
	for m_var in catalog.machines.keys():
		var m_spec: Dictionary = catalog.machines[str(m_var)]
		if m_spec.has("build_cost"):
			m_spec.build_cost.erase(product_id)
	if catalog.has("starting_inventory") and catalog.starting_inventory.has("products"):
		catalog.starting_inventory.products.erase(product_id)
	if catalog.has("editor_layout") and catalog.editor_layout is Dictionary:
		catalog.editor_layout.erase(product_id)
	catalog.products.erase(product_id)
	selected_node_id = ""
	_rebuild_all_nodes()
	_refresh_inspector()
	_mark_dirty("🗑 '%s' (%s) ürünü ve bağlı hatları silindi." % [p_name, product_id])

## Sağ Denetçi Panelini seçili ürüne göre doldurur (yalnızca ürün ve dönüşüm bilgileri).
func _refresh_inspector() -> void:
	if inspector_box == null:
		return
	for child in inspector_box.get_children():
		child.queue_free()

	if selected_node_id.is_empty() or not catalog.products.has(selected_node_id):
		_build_overview_inspector()
		return

	var product_id := selected_node_id
	var spec: Dictionary = catalog.products[product_id]
	_syncing = true

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 8)
	var icon_rect := TextureRect.new()
	icon_rect.texture = Icons.product(sim_helper, product_id)
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head_row.add_child(icon_rect)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_child(_label(str(spec.get("name", product_id)), 16, TEAL))
	title_vbox.add_child(_label("Ürün Kodu: %s" % product_id, 11, MUTED))
	head_row.add_child(title_vbox)
	inspector_box.add_child(head_row)
	inspector_box.add_child(HSeparator.new())

	# 1. Ürün Özellikleri
	inspector_box.add_child(_label("ÜRÜN ÖZELLİKLERİ", 12, GOLD))

	var name_row := HBoxContainer.new()
	name_row.add_child(_label("Ürün Adı:", 12, INK))
	var name_edit := LineEdit.new()
	name_edit.text = str(spec.get("name", product_id))
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(func(new_txt: String) -> void:
		if not new_txt.strip_edges().is_empty():
			catalog.products[product_id]["name"] = new_txt.strip_edges()
			_rebuild_all_nodes()
			_select_node(product_id)
			_mark_dirty("Ürün adı güncellendi: %s" % new_txt)
	)
	name_edit.focus_exited.connect(func() -> void:
		var new_txt := name_edit.text.strip_edges()
		if not new_txt.is_empty() and new_txt != str(catalog.products[product_id].get("name", "")):
			catalog.products[product_id]["name"] = new_txt
			_rebuild_all_nodes()
			_select_node(product_id)
			_mark_dirty("Ürün adı güncellendi: %s" % new_txt)
	)
	name_row.add_child(name_edit)
	inspector_box.add_child(name_row)

	var tier_color_row := HBoxContainer.new()
	tier_color_row.add_theme_constant_override("separation", 10)
	tier_color_row.add_child(_label("Kademe (1-5):", 12, INK))
	var tier_spin := SpinBox.new()
	tier_spin.min_value = 1
	tier_spin.max_value = 5
	tier_spin.value = int(spec.get("tier", 1))
	tier_spin.value_changed.connect(func(val: float) -> void:
		if _syncing:
			return
		catalog.products[product_id]["tier"] = int(val)
		_rebuild_single_node(product_id)
		_mark_dirty("Kademe K%d yapıldı." % int(val))
	)
	tier_color_row.add_child(tier_spin)

	tier_color_row.add_child(_label("Renk:", 12, INK))
	var color_btn := ColorPickerButton.new()
	color_btn.custom_minimum_size = Vector2(46, 28)
	color_btn.edit_alpha = false
	color_btn.color = Color.from_string(str(spec.get("color", "7fa6c4")), Color("7fa6c4"))
	color_btn.color_changed.connect(func(col: Color) -> void:
		if _syncing:
			return
		catalog.products[product_id]["color"] = col.to_html(false)
		_mark_dirty("Ürün rengi güncellendi.")
		_rebuild_all_nodes()
		_select_node(product_id)
	)
	tier_color_row.add_child(color_btn)
	inspector_box.add_child(tier_color_row)

	inspector_box.add_child(HSeparator.new())

	# 2. Ürünün Dönüşüm Tarifleri (Girdiler, Çıktı ve Yan Ürün)
	inspector_box.add_child(_label("ÜRETİM BAĞLARI (GİRDİ → ÇIKTI)", 12, GOLD))
	var recipes := _recipes_for_product(product_id)
	for r_idx in range(recipes.size()):
		var r_id := recipes[r_idx]
		var r_spec: Dictionary = catalog.recipes[r_id]
		var rec_card := PanelContainer.new()
		rec_card.add_theme_stylebox_override("panel", _box(Color("132433"), BORDER, 6, 10, 8))
		var rvbox := VBoxContainer.new()
		rvbox.add_theme_constant_override("separation", 6)
		rec_card.add_child(rvbox)

		var title_txt := "Yöntem #%d" % (r_idx + 1) if recipes.size() > 1 else "Dönüşüm Oranı"
		rvbox.add_child(_label(title_txt, 12, TEAL))

		var in_parts: PackedStringArray = []
		for in_p in r_spec.inputs.keys():
			var in_name: String = str(catalog.products[in_p].name) if catalog.products.has(in_p) else str(in_p)
			in_parts.append("%d× %s" % [int(r_spec.inputs[in_p]), in_name])
		var out_amt := int(r_spec.outputs.get(product_id, 1))
		var formula_txt := "Hammadde (Girdisiz) → %d× %s" % [out_amt, str(spec.get("name", product_id))]
		if not in_parts.is_empty():
			formula_txt = "%s → %d× %s" % [" + ".join(in_parts), out_amt, str(spec.get("name", product_id))]
		var form_lbl := _label(formula_txt, 12, INK)
		form_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rvbox.add_child(form_lbl)

		var by_btn := MenuButton.new()
		by_btn.text = "+ Yan Ürün Ekle (örn. Metal Talaşı)"
		_populate_product_menu(by_btn.get_popup(), product_id, func(chosen_by: String) -> void:
			catalog.recipes[r_id].outputs[chosen_by] = 1
			_rebuild_single_node(product_id)
			_select_node(product_id)
			_mark_dirty("Yan ürün eklendi: %s" % str(catalog.products[chosen_by].name))
		)
		rvbox.add_child(by_btn)

		inspector_box.add_child(rec_card)

	# 3. Bu Ürünün Kullanıldığı Diğer Ürünler
	inspector_box.add_child(HSeparator.new())
	inspector_box.add_child(_label("BU ÜRÜNÜN KULLANILDIĞI ÜRÜNLER", 12, GOLD))
	var used_count := 0
	for p_var in catalog.products.keys():
		var target_prod := str(p_var)
		for r_id in _recipes_for_product(target_prod):
			var r_spec: Dictionary = catalog.recipes[r_id]
			if r_spec.inputs.has(product_id):
				var amt := int(r_spec.inputs[product_id])
				var target_name := str(catalog.products[target_prod].get("name", target_prod))
				inspector_box.add_child(_label("• %s (%d adet)" % [target_name, amt], 12, INK))
				used_count += 1
	if used_count == 0:
		inspector_box.add_child(_label("Başka bir ürünün girdisi olarak kullanılmıyor (Uç ürün).", 12, MUTED))

	inspector_box.add_child(HSeparator.new())
	var del_prod_btn := _button("🗑 Bu Ürünü Zincirden Sil", _delete_product.bind(product_id), inspector_box, DANGER)
	del_prod_btn.custom_minimum_size.y = 34

	_syncing = false

func _build_overview_inspector() -> void:
	inspector_box.add_child(_label("ÜRÜN ZİNCİRİ ÖZETİ", 14, GOLD))
	inspector_box.add_child(_label("Toplam Ürün Sayısı: %d" % catalog.products.size(), 12, INK))
	inspector_box.add_child(HSeparator.new())
	inspector_box.add_child(_label("NASIL KULLANILIR?", 12, TEAL))
	var steps := _label(
		"1. Bir ürünün SAĞ çıkış portundan diğer ürünün SOL giriş portuna çizgi çekerek ürün bağını kurun.\n" +
		"2. Kart üzerindeki sayı kutularından kaç adet girdi gerektiğini ve kaç adet çıktı üretildiğini ayarlayın.\n" +
		"3. Bir ürüne tıkladığınızda sadece onun öncül zinciri parlak kalır.\n" +
		"4. '💾 Kaydet' (Ctrl+S) ile değişiklikleri doğrudan oyuna aktarın.",
		12, MUTED
	)
	steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_box.add_child(steps)

## Yeni Ürün Ekleme Penceresi (Yalnızca Ürün Bilgileri)
func _build_new_product_modal() -> void:
	new_product_modal = PanelContainer.new()
	new_product_modal.visible = false
	new_product_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_product_modal.add_theme_stylebox_override("panel", _box(Color(0.02, 0.05, 0.08, 0.72), Color.TRANSPARENT, 0, 0, 0))
	add_child(new_product_modal)

	var center := CenterContainer.new()
	new_product_modal.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(390, 0)
	dialog.add_theme_stylebox_override("panel", _box(PANEL_BG, TEAL, 8, 18, 16, 2))
	center.add_child(dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)

	vbox.add_child(_label("+ Yeni Ürün Oluştur", 16, TEAL))
	vbox.add_child(HSeparator.new())

	vbox.add_child(_label("Ürün Adı (örn. Titanyum Levha):", 12, INK))
	new_name_edit = LineEdit.new()
	new_name_edit.placeholder_text = "Örn: Titanyum Levha"
	new_name_edit.text_changed.connect(func(txt: String) -> void:
		new_id_edit.text = _slugify(txt)
	)
	vbox.add_child(new_name_edit)

	vbox.add_child(_label("Ürün Kodu (İngilizce küçük harf):", 12, INK))
	new_id_edit = LineEdit.new()
	new_id_edit.placeholder_text = "Örn: titanium_plate"
	vbox.add_child(new_id_edit)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	row1.add_child(_label("Kademe (1-5):", 12, INK))
	new_tier_spin = SpinBox.new()
	new_tier_spin.min_value = 1
	new_tier_spin.max_value = 5
	new_tier_spin.value = 3
	row1.add_child(new_tier_spin)

	row1.add_child(_label("Renk:", 12, INK))
	new_color_picker = ColorPickerButton.new()
	new_color_picker.custom_minimum_size = Vector2(54, 28)
	new_color_picker.edit_alpha = false
	new_color_picker.color = Color("61d8bb")
	row1.add_child(new_color_picker)
	vbox.add_child(row1)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 8)
	_button("İptal", func() -> void: new_product_modal.visible = false, btn_row)
	_button("Oluştur ve Tuvale Ekle", _confirm_create_product, btn_row, TEAL)
	vbox.add_child(btn_row)

func _slugify(text: String) -> String:
	var tr_map := {"ç": "c", "ğ": "g", "ı": "i", "ö": "o", "ş": "s", "ü": "u", "Ç": "c", "Ğ": "g", "İ": "i", "Ö": "o", "Ş": "s", "Ü": "u"}
	var s := text.strip_edges().to_lower()
	for k in tr_map.keys():
		s = s.replace(k, tr_map[k])
	var clean := ""
	for i in range(s.length()):
		var ch := s[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			clean += ch
		elif ch == " " or ch == "-" or ch == "_":
			if not clean.ends_with("_") and not clean.is_empty():
				clean += "_"
	return clean.trim_suffix("_")

func _open_new_product_modal() -> void:
	new_name_edit.text = ""
	new_id_edit.text = ""
	new_product_modal.visible = true
	new_name_edit.grab_focus()

func _confirm_create_product() -> void:
	var p_name := new_name_edit.text.strip_edges()
	var p_id := _slugify(new_id_edit.text)
	if p_name.is_empty() or p_id.is_empty():
		status_label.text = "⚠ Yeni ürün için ad ve kod girilmelidir."
		return
	if catalog.products.has(p_id) or catalog.recipes.has(p_id):
		status_label.text = "⚠ '%s' kimliği zaten kullanılıyor." % p_id
		return
	var tier := int(new_tier_spin.value)
	var col_hex := new_color_picker.color.to_html(false)
	catalog.products[p_id] = {
		"name": p_name,
		"tier": tier,
		"color": col_hex
	}
	catalog.recipes[p_id] = {
		"name": "%s üretimi" % p_name,
		"inputs": {},
		"outputs": {p_id: 1},
		"work": 60.0
	}
	_assign_recipe_to_machine(p_id, "assembler" if tier >= 4 else ("press" if tier >= 2 else "iron_mine"))
	_set_unlock_source_for_recipe(p_id, "")

	new_product_modal.visible = false
	_capture_layout()
	var spawn_pos := (graph.scroll_offset + graph.size * 0.4) / graph.zoom
	catalog.editor_layout[p_id] = [roundi(spawn_pos.x), roundi(spawn_pos.y)]
	_refresh_sim_helper()
	_rebuild_all_nodes()
	_select_node(p_id)
	_mark_dirty("✓ Yeni ürün oluşturuldu: %s. Şimdi girdi portuna diğer ürünleri bağlayabilirsiniz." % p_name)

func _validate_chain() -> Array[String]:
	var issues: Array[String] = []
	for p_var in catalog.products.keys():
		var p_id := str(p_var)
		var p_name := str(catalog.products[p_id].get("name", p_id))
		var recs := _recipes_for_product(p_id)
		if p_id != "metal_scrap" and recs.is_empty():
			issues.append("'%s' (%s) için üretim tanımı yok." % [p_name, p_id])
		for r_id in recs:
			var tier := int(catalog.products[p_id].get("tier", 1))
			if tier > 1 and catalog.recipes[r_id].inputs.is_empty():
				issues.append("'%s' (Kademe %d) ürününün hiç girdisi yok." % [p_name, tier])
	if issues.is_empty():
		status_label.text = "✓ Doğrulama başarılı: Tüm %d ürünün dönüşüm zinciri geçerli." % catalog.products.size()
	else:
		status_label.text = "⚠ Doğrulama uyarısı (%d adet): %s" % [issues.size(), issues[0]]
	return issues

func _save_catalog_to_disk() -> void:
	_capture_layout()
	var issues := _validate_chain()
	var abs_path := ProjectSettings.globalize_path(CATALOG_PATH)
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		file = FileAccess.open(CATALOG_PATH, FileAccess.WRITE)
	if file == null:
		status_label.text = "✗ Kayıt hatası: %s yazılamadı." % CATALOG_PATH
		return
	file.store_string(JSON.stringify(catalog, "  ") + "\n")
	file.close()
	dirty = false
	_update_dirty_badge()
	if issues.is_empty():
		status_label.text = "💾 Kaydedildi → data/prototype.json güncellendi!"
	else:
		status_label.text = "💾 Kaydedildi (Uyarı: %s)" % issues[0]

func _reload_from_disk() -> void:
	_load_catalog_from_disk()
	_rebuild_all_nodes()
	if not catalog.has("editor_layout") or catalog.editor_layout.is_empty():
		_auto_layout()
	else:
		_apply_saved_layout()
	_refresh_inspector()
	status_label.text = "↺ Diskteki data/prototype.json yeniden yüklendi."

func _launch_game_instance() -> void:
	if dirty:
		_save_catalog_to_disk()
	var exe := OS.get_executable_path()
	var proj := ProjectSettings.globalize_path("res://")
	OS.create_process(exe, ["--path", proj])
	status_label.text = "▶ Oyun yeni pencerede başlatıldı."

func _run_smoke_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_select_node("gear")
	await get_tree().create_timer(0.15).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://artifacts/chain-editor.png"))
	get_tree().quit(0)
