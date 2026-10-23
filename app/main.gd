extends Control

const Simulation = preload("res://sim/production_sim.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const FlowGraph = preload("res://app/flow_graph.gd")
const InventoryBar = preload("res://app/inventory_bar.gd")
const InventoryWindow = preload("res://app/inventory_window.gd")
const CraftScreen = preload("res://app/craft_screen.gd")
const MachineMenu = preload("res://app/machine_menu.gd")
const RecipePicker = preload("res://app/recipe_picker.gd")
const ResearchPanel = preload("res://app/research_panel.gd")
const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
var sim := Simulation.new()
var graph: GraphEdit
var inventory_bar: InventoryBar
var inventory_window: InventoryWindow
var craft_screen: CraftScreen
var machine_menu: MachineMenu
var recipe_picker: RecipePicker
var _press_offset := Vector2.INF
var research_panel: ResearchPanel
var selected_id := ""
var cards: Dictionary = {}
var research_button: Button
var unlock_button: Button
var pause_button: Button
var speed_button: Button
var summary: Label
var message: Label
var paused := false
var time_scale := 1.0
var refresh_elapsed := 0.0
var last_completed_count := 0
var storage_path := "user://workshop.json"

func _ready() -> void:
	_build_theme()
	_build_ui()
	_demo()
	if "--smoke-test" in OS.get_cmdline_user_args():
		_smoke_test.call_deferred()

func _build_theme() -> void:
	var skin := Theme.new()
	skin.default_font_size = 14
	skin.set_color("font_color", "Label", INK)
	skin.set_color("font_color", "Button", INK)
	skin.set_stylebox("normal", "Button", _box(Color("162836"), Color("294356"), 6, 10, 6))
	skin.set_stylebox("hover", "Button", _box(Color("213b4d"), TEAL, 6, 10, 6))
	skin.set_stylebox("pressed", "Button", _box(Color("295258"), TEAL, 6, 10, 6))
	skin.set_stylebox("disabled", "Button", _box(Color("101c26"), Color("1b2d3b"), 6, 10, 6))
	skin.set_stylebox("background", "ProgressBar", _box(Color("09131c"), Color.TRANSPARENT, 3, 0, 0))
	skin.set_stylebox("fill", "ProgressBar", _box(TEAL, Color.TRANSPARENT, 3, 0, 0))
	theme = skin

func _box(background: Color, border: Color, radius: int = 8, pad_x: int = 12, pad_y: int = 8) -> StyleBoxFlat:
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

func _label(text: String, font_size: int = 14, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, action: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("081119")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)
	# Tek satırlı sade oyun HUD çubuğu
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _box(Color("0f1d29"), Color("1e3446"), 0, 14, 8))
	layout.add_child(header)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	header.add_child(head)
	var brand := _label("FLOWGAME", 18, TEAL)
	head.add_child(brand)
	var sep1 := VSeparator.new()
	head.add_child(sep1)
	research_button = _button("🔬 Araştırma Ağacı", _toggle_research_panel, head)
	unlock_button = _button("Serbest Mod", _unlock_all_sandbox, head)
	unlock_button.tooltip_text = "Tüm 24 ürünü ve makineleri hemen denemek için kilitleri açar."
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	pause_button = _button("Duraklat", _toggle_pause, head)
	speed_button = _button("1×", _toggle_speed, head)
	var sep2 := VSeparator.new()
	head.add_child(sep2)
	_button("Ortala", _frame_graph, head)
	_button("Kaydet", _save_game, head)
	_button("Yükle", _load_game, head)
	_button("Sıfırla", _demo, head).tooltip_text = "Başlangıç ağını yeniden kurar."
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 0)
	layout.add_child(workspace)
	# The canvas holds the graph with the inventory floating over its bottom edge.
	var canvas := Control.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_child(canvas)
	graph = FlowGraph.new()
	graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph.right_disconnects = true
	graph.minimap_enabled = false
	graph.snapping_enabled = true
	graph.snapping_distance = 20
	graph.get_menu_hbox().visible = false
	graph.add_theme_stylebox_override("panel", _box(Color("09131c"), Color.TRANSPARENT, 0, 0, 0))
	graph.add_theme_color_override("grid_minor", Color("10202c"))
	graph.add_theme_color_override("grid_major", Color("183040"))
	graph.connection_request.connect(_connect_cards)
	graph.disconnection_request.connect(_disconnect_cards)
	graph.delete_nodes_request.connect(_delete_cards)
	graph.node_selected.connect(func(node: Node) -> void: _show_selection(str(node.name)))
	graph.node_deselected.connect(func(_node: Node) -> void: _sync_selection.call_deferred())
	canvas.add_child(graph)
	# Open inputs of auto machines accept any product one of their recipes uses.
	for kind in sim.catalog.machines:
		if sim.recipe_mode(str(kind)) == "auto" or sim.is_storage(str(kind)):
			for product in sim.recipe_input_union(str(kind)):
				graph.add_valid_connection_type(sim.product_port_type(str(product)), sim.any_port_type(str(kind)))
	inventory_bar = InventoryBar.new()
	canvas.add_child(inventory_bar)
	inventory_bar.build()
	inventory_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 12)
	inventory_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory_bar.machine_requested.connect(_add_at_view)
	inventory_bar.craft_screen_requested.connect(func() -> void:
		inventory_window.hide()
		craft_screen.toggle())
	inventory_bar.inventory_requested.connect(_toggle_inventory)
	inventory_bar.craft_cancelled.connect(_cancel_craft)
	inventory_bar.pin_requested.connect(_pin)
	inventory_bar.unpin_requested.connect(_unpin)
	inventory_bar.is_blocked = func() -> bool:
		return craft_screen.visible or inventory_window.visible or research_panel.visible or recipe_picker.visible
	machine_menu = MachineMenu.new()
	add_child(machine_menu)
	machine_menu.toggle_requested.connect(_toggle_machine)
	machine_menu.speed_requested.connect(_change_machine_speed)
	machine_menu.recipe_screen_requested.connect(func(id: String) -> void: recipe_picker.show_machine(sim, id))
	machine_menu.take_requested.connect(_take_all)
	machine_menu.research_requested.connect(_toggle_research_panel)
	machine_menu.delete_requested.connect(func(id: String) -> void: _delete_cards([StringName(id)]))
	machine_menu.supplier_selected.connect(_spawn_supplier)
	# Tek satırlı ince alt durum çubuğu
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _box(Color("0f1d29"), Color("1e3446"), 0, 14, 5))
	layout.add_child(footer)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	footer.add_child(bottom)
	summary = _label("", 12, TEAL)
	bottom.add_child(summary)
	var foot_spacer := Control.new()
	foot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(foot_spacer)
	message = _label("C: üret · I: envanter · 1-0: hızlı erişim · Çıkışa tıkla: envantere al · Sağ tık: makine menüsü", 12, MUTED)
	bottom.add_child(message)
	recipe_picker = RecipePicker.new()
	add_child(recipe_picker)
	recipe_picker.build()
	recipe_picker.recipe_selected.connect(_change_machine_recipe)
	research_panel = ResearchPanel.new()
	add_child(research_panel)
	research_panel.build(sim.catalog)
	research_panel.research_selected.connect(_select_research)
	research_panel.unlock_all_requested.connect(_unlock_all_sandbox)
	research_panel.close_requested.connect(func() -> void: research_panel.visible = false)
	craft_screen = CraftScreen.new()
	add_child(craft_screen)
	craft_screen.build(sim)
	craft_screen.craft_requested.connect(_craft)
	craft_screen.craft_cancelled.connect(_cancel_craft)
	inventory_window = InventoryWindow.new()
	add_child(inventory_window)
	inventory_window.build(sim)
	inventory_window.machine_requested.connect(_add_at_view)
	inventory_window.pin_requested.connect(_pin)
	inventory_window.unpin_requested.connect(_unpin)

func _toggle_research_panel() -> void:
	research_panel.visible = not research_panel.visible
	research_panel.refresh(sim)

func _select_research(tech_id: String) -> void:
	if not sim.set_active_research(tech_id):
		message.text = "Bu araştırma henüz seçilemez; ön koşulları tamamlanmalı."
		return
	research_panel.refresh(sim)
	_refresh()
	message.text = "Aktif araştırma: %s" % sim.catalog.researches[tech_id].name

func _unlock_all_sandbox() -> void:
	sim.unlock_all()
	research_panel.refresh(sim)
	_refresh()
	message.text = "Serbest mod: 24 ürünün tüm makineleri ve reçeteleri açıldı."

func _change_machine_recipe(id: String, recipe_id: String) -> void:
	if not sim.is_recipe_unlocked(recipe_id):
		message.text = "Bu reçete henüz kilitli."
		return
	if not sim.set_recipe(id, recipe_id):
		return
	_rebuild_card(id)
	_sync_graph_connections()
	_select_card(id)
	_refresh()
	message.text = "Reçete: %s" % sim.catalog.recipes[recipe_id].get("name", recipe_id)

func _take_all(id: String) -> void:
	var count := sim.take_all(id)
	_refresh()
	message.text = "+%d ürün envantere alındı." % count if count > 0 else "Alınacak ürün yok."

func _take_product(id: String, product: String) -> void:
	var count := sim.take(id, product)
	_refresh()
	if count > 0:
		message.text = "+%d %s" % [count, sim.product_name(product)]

func _craft(type: String, id: String, count: int) -> void:
	var queued := 0
	for i in range(count):
		if sim.enqueue_craft(type, id):
			queued += 1
	_refresh()
	if queued == 0:
		message.text = "Üretilemez: malzeme eksik, kilitli ya da sınıra ulaşıldı."

func _toggle_inventory() -> void:
	craft_screen.hide()
	inventory_window.toggle()

func _pin(key: String, slot: int) -> void:
	if not sim.pin(key, slot):
		message.text = "Hızlı erişim dolu: önce bir yuvayı sağ tıkla boşalt."
	_refresh()

func _unpin(slot: int) -> void:
	sim.unpin(slot)
	_refresh()

func _cancel_craft(index: int) -> void:
	sim.cancel_craft(index)
	_refresh()

func _add_at_view(kind: String) -> void:
	_add_at_view_with_recipe(kind, "")

func _add_at_view_with_recipe(kind: String, recipe_id: String) -> void:
	if not sim.is_machine_unlocked(kind):
		message.text = "Bu makine henüz kilitli."
		return
	if not sim.can_build(kind):
		message.text = "%s sınırına ulaşıldı (en fazla %d)." % [sim.catalog.machines[kind].name, sim.build_limit(kind)]
		return
	var placed := sim.place_machine(kind, recipe_id)
	if placed.is_empty():
		message.text = "Envanterde %s yok; C ile üret." % sim.catalog.machines[kind].name
		return
	var pos := (graph.scroll_offset + graph.size * 0.35) / graph.zoom
	var id := _add_card(kind, pos + Vector2(cards.size() % 4 * 28, cards.size() % 3 * 24), placed)
	_select_card(id)
	_refresh()
	message.text = "%s eklendi." % sim.catalog.machines[kind].name
	if sim.recipe_mode(kind) == "choose" and recipe_id.is_empty():
		recipe_picker.show_machine(sim, id)

func _spawn_supplier(target_id: String, product: String, supplier_kind: String, supplier_recipe: String) -> void:
	if not cards.has(target_id) or not sim.is_machine_unlocked(supplier_kind) or not sim.is_recipe_unlocked(supplier_recipe):
		message.text = "Bu üretici makine veya reçete henüz kilitli."
		return
	if not sim.can_place(supplier_kind):
		message.text = "Envanterde %s yok ya da sınıra ulaşıldı." % sim.catalog.machines[supplier_kind].name
		return
	var target_node: GraphNode = cards[target_id].node
	var in_idx := sim.input_products(target_id).find(product)
	var base_pos := target_node.position_offset + Vector2(-320, maxi(in_idx, 0) * 230 - 40)
	# Çakışma varsa dikey kaydır
	for attempt in range(8):
		var clash := false
		for view in cards.values():
			if view.node.position_offset.distance_to(base_pos) < 95.0:
				clash = true
				break
		if not clash:
			break
		base_pos += Vector2(0, 230)
	var supplier_id := _add_card(supplier_kind, base_pos, sim.place_machine(supplier_kind, supplier_recipe))
	var out_port := sim.output_products(supplier_id).find(product)
	var in_port := sim.input_products(target_id).find(product)
	if in_port < 0:
		in_port = sim.input_products(target_id).find(sim.ANY)
	if out_port >= 0 and in_port >= 0:
		sim.add_link(supplier_id, target_id, out_port, in_port)
		_sync_graph_connections()
	_refresh()
	message.text = "%s (%s) kuruldu ve %s girişine bağlandı." % [
		sim.catalog.machines[supplier_kind].name,
		sim.catalog.products[product].name,
		sim.catalog.machines[sim.machines[target_id].kind].name
	]

func _show_selection(id: String) -> void:
	if not cards.has(id):
		return
	selected_id = id

func _select_card(id: String) -> void:
	for card_id in cards:
		cards[card_id].node.selected = card_id == id
	if id.is_empty() or not cards.has(id):
		selected_id = ""
	else:
		_show_selection(id)

func _sync_selection() -> void:
	if cards.has(selected_id) and cards[selected_id].node.selected:
		return
	for id in cards:
		if cards[id].node.selected:
			_show_selection(id)
			return
	selected_id = ""

func _frame_graph() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if cards.is_empty() or not is_instance_valid(graph):
		return
	var bounds := Rect2()
	var first := true
	for view in cards.values():
		var card: GraphNode = view.node
		var rect := Rect2(card.position_offset, card.size)
		bounds = rect if first else bounds.merge(rect)
		first = false
	graph.zoom = clampf(minf((graph.size.x - 90.0) / maxf(bounds.size.x, 1.0), (graph.size.y - 90.0) / maxf(bounds.size.y, 1.0)), graph.zoom_min, 1.0)
	graph.scroll_offset = bounds.get_center() * graph.zoom - graph.size * 0.5

func _rebuild_card(id: String) -> void:
	if not cards.has(id) or not sim.machines.has(id):
		return
	var old_node: GraphNode = cards[id].node
	var pos := old_node.position_offset
	var was_selected := old_node.selected
	graph.remove_child(old_node)
	old_node.queue_free()
	cards.erase(id)
	_add_card(sim.machines[id].kind, pos, id)
	cards[id].node.selected = was_selected

func _add_card(kind: String, pos: Vector2, existing_id: String = "", recipe_override: String = "") -> String:
	var id := existing_id if not existing_id.is_empty() else sim.add_machine(kind, recipe_override)
	sim.machines[id].position = [pos.x, pos.y]
	var card: GraphNode = SpriteMachineCard.new()
	card.position_offset = pos
	graph.add_child(card)
	card.setup_from_sim(sim, id)
	card.set_header_icon(CraftScreen.icon_for(kind))
	card.take_requested.connect(_take_product)
	card.recipe_changed.connect(_change_machine_recipe)
	card.toggle_pressed.connect(_toggle_machine)
	card.supplier_requested.connect(func(target: String, product: String, at: Vector2) -> void:
		machine_menu.show_suppliers(sim, target, product, at))
	card.gui_input.connect(_on_card_input.bind(id))
	card.position_offset_changed.connect(func() -> void:
		if sim.machines.has(id):
			sim.machines[id].position = [card.position_offset.x, card.position_offset.y])
	cards[id] = {
		"node": card,
		"ports": sim.port_signature(id)
	}
	return id

func _on_card_input(event: InputEvent, id: String) -> void:
	var click := event as InputEventMouseButton
	if click == null or not sim.machines.has(id):
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		# A click that did not drag the card opens the recipe screen of "choose" machines.
		var offset: Vector2 = cards[id].node.position_offset
		if click.pressed:
			_press_offset = offset
		elif offset == _press_offset and sim.recipe_mode(str(sim.machines[id].kind)) == "choose":
			recipe_picker.show_machine(sim, id)
		return
	if not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT:
		return
	_select_card(id)
	machine_menu.show_machine(sim, id, cards[id].node.get_global_transform() * click.position)
	cards[id].node.accept_event()

func _sync_graph_connections() -> void:
	graph.clear_connections()
	for link in sim.links:
		if not cards.has(link.from) or not cards.has(link.to):
			continue
		var from_port := sim.output_products(link.from).find(link.product)
		var to_port := sim.input_products(link.to).find(link.product)
		if from_port >= 0 and to_port >= 0:
			graph.connect_node(link.from, from_port, link.to, to_port)

func _connect_cards(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	if not sim.add_link(str(from), str(to), from_port, to_port):
		message.text = "Bağlanamadı: çıkış ve giriş aynı ürün olmalı."
		return
	_sync_graph_connections()
	# Linking into an auto machine can settle its recipe and change its ports.
	_refresh.call_deferred()
	message.text = "Bağlantı kuruldu (K-006 eşit paylaşım)."

func _disconnect_cards(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	sim.remove_link(str(from), str(to), from_port, to_port)
	_sync_graph_connections()
	_refresh.call_deferred()

func _delete_cards(ids: Array[StringName]) -> void:
	for name_id in ids:
		var id := str(name_id)
		if not cards.has(id):
			continue
		sim.pick_up_machine(id)
		var node: GraphNode = cards[id].node
		graph.remove_child(node)
		node.queue_free()
		cards.erase(id)
	_sync_graph_connections()
	_sync_selection()
	message.text = "Makine envantere kaldırıldı."
	_refresh()

func _clear_cards() -> void:
	selected_id = ""
	graph.clear_connections()
	for view in cards.values():
		graph.remove_child(view.node)
		view.node.queue_free()
	cards.clear()

func _demo() -> void:
	_clear_cards()
	sim = Simulation.new()
	last_completed_count = 0
	paused = false
	pause_button.text = "Duraklat"
	var iron_mine := _add_card("iron_mine", Vector2(20, 20))
	var coal_mine := _add_card("coal_mine", Vector2(20, 250))
	var smelter := _add_card("smelter", Vector2(340, 20), "", "pig_iron")
	var steel_furnace := _add_card("steel_furnace", Vector2(340, 250), "", "steel_ingot")
	var mill_plate := _add_card("rolling_mill", Vector2(660, 20), "", "steel_plate")
	var mill_rod := _add_card("rolling_mill", Vector2(660, 250), "", "steel_rod")
	var press := _add_card("press", Vector2(660, 480), "", "fastener")
	var lab := _add_card("lab_1", Vector2(980, 250))
	sim.add_link(iron_mine, smelter)
	sim.add_link(coal_mine, smelter)
	sim.add_link(coal_mine, steel_furnace)
	sim.add_link(smelter, steel_furnace)
	sim.add_link(steel_furnace, mill_plate)
	sim.add_link(steel_furnace, mill_rod)
	sim.add_link(mill_plate, lab)
	sim.add_link(mill_rod, press)
	sim.add_link(press, lab)
	_sync_graph_connections()
	graph.scroll_offset = Vector2.ZERO
	_select_card("")
	_frame_graph.call_deferred()
	message.text = "Hızlı erişimdeki makineye tıkla ya da numarasına bas: yerleştir · I: envanter · C: üretim ekranı"
	_refresh()

func _toggle_machine(id: String) -> void:
	if not sim.machines.has(id):
		return
	sim.machines[id].enabled = not sim.machines[id].enabled
	var m: Dictionary = sim.machines[id]
	m.status = ("İşleniyor" if m.enabled else "İşleniyor · duracak") if m.running else ("Hazır" if m.enabled else "Durduruldu")
	_refresh()

func _change_machine_speed(id: String) -> void:
	sim.machines[id].speed = 40.0 if float(sim.machines[id].speed) == 20.0 else 20.0
	_refresh()

func _toggle_pause() -> void:
	paused = not paused
	pause_button.text = "Devam" if paused else "Duraklat"

func _toggle_speed() -> void:
	time_scale = 4.0 if time_scale == 1.0 else 1.0
	speed_button.text = "%d×" % int(time_scale)

func _process(delta: float) -> void:
	if not paused:
		sim.advance(minf(delta, 0.25) * time_scale)
	refresh_elapsed += delta
	if refresh_elapsed >= 0.1:
		refresh_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	var ports_changed := false
	for id in cards.keys():
		if sim.machines.has(id) and cards[id].ports != sim.port_signature(id):
			_rebuild_card(id)
			ports_changed = true
	if ports_changed:
		_sync_graph_connections()
	if sim.completed_researches.size() != last_completed_count:
		last_completed_count = sim.completed_researches.size()
		var latest := str(sim.completed_researches.back()) if not sim.completed_researches.is_empty() else ""
		if not latest.is_empty():
			message.text = "✓ %s tamamlandı! Yeni makineler ve reçeteler açıldı." % sim.catalog.researches[latest].name
	for id in cards:
		var machine: Dictionary = sim.machines[id]
		var view: Dictionary = cards[id]
		if view.node.has_method("set_simulation_playback"):
			view.node.set_simulation_playback(paused, time_scale)
		view.node.update_from_sim(sim, id)
	var active_text := "Tüm araştırmalar tamamlandı"
	if sim.can_research(sim.active_research):
		var percent := roundi(sim.research_fraction(sim.active_research) * 100.0)
		active_text = "%s (%%%d)" % [sim.catalog.researches[sim.active_research].name, percent]
		research_button.text = "🔬 %s  %%%d" % [sim.active_research, percent]
	elif sim.completed_researches.size() < sim.catalog.researches.size():
		active_text = "%s bitti — Yeni hedef seç" % sim.active_research
		research_button.text = "🔬 Hedef Seç (%d/%d)" % [sim.completed_researches.size(), sim.catalog.researches.size()]
	else:
		research_button.text = "🔬 Araştırmalar (%d/%d)" % [sim.completed_researches.size(), sim.catalog.researches.size()]
	var whole_seconds := int(sim.elapsed + Simulation.EPSILON)
	summary.text = "⏱ %02d:%02d   ·   %d Makine / %d Hat   ·   %s   ·   Teknoloji: %d/%d" % [
		whole_seconds / 60, whole_seconds % 60, cards.size(), sim.links.size(),
		active_text, sim.completed_researches.size(), sim.catalog.researches.size()
	]
	research_panel.refresh(sim)
	inventory_bar.refresh(sim)
	inventory_window.refresh(sim)
	craft_screen.refresh(sim)

func _save_game() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		message.text = "Kayıt yazılamadı: %s" % error_string(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(sim.snapshot(), "\t"))
	file.close()
	message.text = "Oyun kaydedildi."

func _load_game() -> void:
	if not FileAccess.file_exists(storage_path):
		message.text = "Henüz kayıt yok."
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
	var restored := Simulation.new()
	if not data is Dictionary or not restored.restore(data):
		message.text = "Kayıt bozuk veya uyumsuz."
		return
	var previous_selection := selected_id
	_clear_cards()
	sim = restored
	last_completed_count = sim.completed_researches.size()
	for id in sim.machines:
		var m: Dictionary = sim.machines[id]
		_add_card(m.kind, Vector2(m.position[0], m.position[1]), id)
	_sync_graph_connections()
	if cards.has(previous_selection):
		_select_card(previous_selection)
	_frame_graph.call_deferred()
	_refresh()
	message.text = "Kayıt yüklendi."

func _smoke_test() -> void:
	paused = true
	pause_button.text = "Devam"
	storage_path = "user://smoke-state.json"
	sim.advance(180.0)
	_refresh()
	assert("A-01" in sim.completed_researches, "Başlangıç ağı A-01 araştırmasını tamamlamalı")
	assert(sim.is_machine_unlocked("cnc") and sim.is_machine_unlocked("lathe"), "A-01 sonrası Torna ve CNC açılmalı")
	_save_game()
	var before := sim.snapshot()
	_load_game()
	if JSON.stringify(sim.snapshot()) != JSON.stringify(before):
		push_error("UI kayıt/yükleme eşleşmedi")
		get_tree().quit(1)
		return
	# Hand-craft a CNC: the rod line feeds the press, so the test hands over the rods it needs.
	sim.inventory["steel_rod"] = 4
	craft_screen.toggle()
	craft_screen.open_category(3)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(craft_screen.tiles["machine:cnc"].is_visible_in_tree() and not craft_screen.tiles["machine:iron_mine"].is_visible_in_tree())
	await _smoke_click(craft_screen.tiles["machine:cnc"].get_global_rect().get_center())
	assert(craft_screen.selected == "machine:cnc" and not craft_screen.craft_button.disabled)
	await _smoke_click(craft_screen.craft_button.get_global_rect().get_center())
	_refresh()
	await get_tree().process_frame
	assert(sim.craft_queue.size() == 1 and inventory_bar.queue_slots.size() == 1 and craft_screen.queue_slots.size() == 1 and not sim.inventory.has("steel_rod"))
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://artifacts")
		get_viewport().get_texture().get_image().save_png("res://artifacts/craft-screen.png")
	craft_screen.hide()
	sim.advance(5.1)
	_refresh()
	assert(sim.machine_inventory.get("cnc", 0) == 1 and sim.craft_queue.is_empty())
	await get_tree().process_frame
	await get_tree().process_frame
	# The crafted CNC took a free quick-use slot; place it from there.
	assert(inventory_bar.slot_for("machine:cnc") != null)
	await _smoke_click(inventory_bar.slot_for("machine:cnc").get_global_rect().get_center())
	var cnc_card := selected_id
	assert(cards.size() == 9 and sim.machines[cnc_card].kind == "cnc")
	# CNC makes gear or bearing from the same rod, so placing it opens the recipe screen.
	assert(recipe_picker.visible and recipe_picker.target_id == cnc_card)
	recipe_picker.tiles["bearing"].pressed.emit()
	assert(sim.machines[cnc_card].recipe == "bearing" and not recipe_picker.visible)
	# Right click opens the card menu; its items drive the recipe screen, speed and stop/run.
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	right.position = Vector2(40, 40)
	_on_card_input(right, cnc_card)
	assert(machine_menu.visible and machine_menu.target_id == cnc_card)
	machine_menu.id_pressed.emit(MachineMenu.RECIPE)
	assert(recipe_picker.visible)
	recipe_picker.tiles["gear_cnc"].pressed.emit()
	assert(sim.machines[cnc_card].recipe == "gear_cnc")
	_on_card_input(right, cnc_card)
	machine_menu.id_pressed.emit(MachineMenu.SPEED)
	assert(float(sim.machines[cnc_card].speed) == 40.0)
	machine_menu.id_pressed.emit(MachineMenu.TOGGLE)
	assert(not sim.machines[cnc_card].enabled)
	machine_menu.id_pressed.emit(MachineMenu.TOGGLE)
	assert(sim.machines[cnc_card].enabled)
	machine_menu.hide()
	# Inventory window (I): shares the inventory with the quick-use bar and pins items to it.
	_toggle_inventory()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(inventory_window.visible and inventory_window.items.has("product:steel_plate"))
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("res://artifacts/inventory-window.png")
	inventory_window.quick_slots[9].on_drop.call(9, "product:steel_plate")
	assert(sim.hotbar[9] == "product:steel_plate" and inventory_bar.slots[9].key == "product:steel_plate", "Sürüklenen öğe hızlı erişime sabitlenmeli")
	inventory_window._toggle_pin("product:steel_plate")
	assert(not ("product:steel_plate" in sim.hotbar), "Sağ tık sabitlenmiş öğeyi çıkarmalı")
	inventory_window._toggle_pin("product:steel_plate")
	assert("product:steel_plate" in sim.hotbar, "Sağ tık öğeyi ilk boş yuvaya sabitlemeli")
	_toggle_inventory()
	assert(not inventory_window.visible)
	_toggle_research_panel()
	assert(research_panel.visible)
	_select_research("A-02")
	assert(sim.active_research == "A-02")
	_select_research("A-04")
	assert(sim.active_research == "A-04")
	_toggle_research_panel()
	assert(not research_panel.visible)
	_delete_cards([StringName(cnc_card)])
	assert(cards.size() == 8 and sim.machine_inventory.get("cnc", 0) == 1, "Kaldırılan makine envantere dönmeli")
	# The demo already has the one iron mine allowed, so it cannot be crafted or placed again.
	craft_screen.toggle()
	craft_screen.open_category(0)
	craft_screen.select("machine:iron_mine")
	assert(craft_screen.craft_button.disabled)
	craft_screen.hide()
	_add_at_view("iron_mine")
	assert(cards.size() == 8, "Sınırı dolan maden ikinci kez kurulmamalı")
	# Clicking an output gauge moves what the machine made into the inventory.
	sim.machines["machine_1"].output.iron_ore = 3
	_refresh()
	await get_tree().process_frame
	var ore_gauge: Control = cards["machine_1"].node.output_gauges["iron_ore"]
	await _smoke_click(ore_gauge.get_global_rect().get_center())
	assert(sim.inventory.get("iron_ore", 0) == 3 and sim.machines["machine_1"].output.iron_ore == 0, "Çıkışa tıklayınca ürün envantere geçmeli")
	# Tek tıkla üretici makine kurup bağlama testi (_spawn_supplier)
	# Cut the lab's fastener line, then rebuild it from the "+" on that input.
	sim.links = sim.links.filter(func(link: Dictionary) -> bool: return not (link.to == "machine_8" and link.product == "fastener"))
	_sync_graph_connections()
	_refresh()
	_select_card("machine_8")
	sim.machine_inventory["press"] = 1
	var fastener_add: Button = cards["machine_8"].node.input_gauges["fastener"].add_button
	assert(fastener_add.visible, "Bağlantısız girişte + görünmeli")
	fastener_add.pressed.emit()
	assert(machine_menu.visible and machine_menu.target_product == "fastener")
	machine_menu.id_pressed.emit(0)
	machine_menu.hide()
	assert(cards.size() == 9, "Tek tıkla pres kurulup laboratuvara bağlanmalı")
	var press_id := "machine_10"
	assert(sim.machines[press_id].kind == "press" and sim.is_input_linked("machine_8", "fastener"))
	assert(not sim.machine_inventory.has("press"), "+ ile kurulan pres envanterden düşmeli")
	_delete_cards([StringName(press_id)])
	assert(cards.size() == 8 and sim.machine_inventory.get("press", 0) == 1)
	_select_card("machine_8")
	_refresh()
	for i in range(4):
		await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		var image := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://artifacts")
		image.save_png("res://artifacts/production-workshop.png")
		image.save_png("res://artifacts/production-workshop-%dx%d.png" % [image.get_width(), image.get_height()])
	print("UI_SMOKE_OK: envanter, el üretimi, yerleştirme, çıkıştan alma, A-01 araştırma ve kayıt/yükleme doğrulandı")
	get_tree().quit()

func _smoke_click(position_in_view: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position_in_view
	motion.global_position = position_in_view
	get_viewport().push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position_in_view
	down.global_position = position_in_view
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.position = position_in_view
	up.global_position = position_in_view
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	await get_tree().process_frame
