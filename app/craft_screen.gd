extends PanelContainer
## Inventory and crafting window (style A: dark frame, amber accents), opened with I or C.
## Left: every machine and product in the game. What you carry shows its count; what you do
## not have is dimmed, and a padlock marks what research has not opened yet. Clicking an
## item shows on the right how it is made: picture, recipe with what you carry (red when
## short), time and the ÜRET button (shift: five). Products a machine makes, not the hand,
## name that machine instead. Double-clicking a carried machine places it.
## Below sit the craft queue (× cancels and refunds) and the quick-use bar's ten slots; drag
## an item onto a slot, right click it, or press 1-9, 0 while hovering it to pin it there.
## I, C or Esc closes it.

signal craft_requested(type: String, id: String, count: int)
signal craft_cancelled(index: int)
signal machine_requested(kind: String)
signal pin_requested(key: String, slot: int)
signal unpin_requested(slot: int)

const Icons = preload("res://app/icons.gd")
const InventorySlot = preload("res://app/inventory_slot.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const ICONS := preload("res://app/art/ui/category_icons.png")
const INK := Color("3d3a33")
const MUTED := Color("7a7466")
const AMBER := Color("b98330")
const RED := Color("b5452f")
const PANEL := Color("f6f2ea")
const EDGE := Color("cfc6b3")
## Order matches the icon strip (art_src/araclar/kategori_ikonlari.py); the hammer after
## the last category is the craft button's symbol. The machine list follows this order.
const CATEGORIES := [
	{"name": "Hammadde", "tab": "Hammadde", "machines": ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]},
	{"name": "Metalürji", "tab": "Metalürji", "machines": ["smelter"]},
	{"name": "Şekillendirme", "tab": "Şekillendirme", "machines": ["rolling_mill", "press", "foundry"]},
	{"name": "Talaşlı imalat", "tab": "Talaşlı", "machines": ["machine_shop"]},
	{"name": "Montaj", "tab": "Montaj", "machines": ["machine_factory", "wire_winder", "mechanical_assembly", "electrical_assembly", "electronics_assembly", "robotics_assembly"]},
	{"name": "Araştırma ve hedefler", "tab": "Araştırma", "machines": ["lab_1", "lab_2", "lab_3", "lab_4", "module_plant", "project_hub", "scrap_disposal"]},
	{"name": "Depo", "tab": "Depo", "machines": ["storage"]},
]
const CRAFT_ICON := 7
const COLUMNS := 10
const SLOT := 48
const USES_SHOWN := 14

## "machine:<kind>" or "product:<id>" -> slot in the left grids
var items: Dictionary = {}
## The window's copy of the quick-use bar, index 0-9.
var quick_slots: Array[InventorySlot] = []
## Inventory key shown on the craft side.
var selected := ""
var craft_button: Button
var place_button: Button
## One per queued job: {bar, time, cancel}
var queue_slots: Array[Dictionary] = []
var _sim: RefCounted
var _hover := ""
var _title: Label
var _count: Label
var _picture: TextureRect
var _description: Label
var _recipe: HBoxContainer
var _time: Label
var _reason: Label
var _uses_title: Label
var _uses: HFlowContainer
var _queue_title: Label
var _queue_row: HBoxContainer
## Starts unequal to any real queue so the first refresh builds the row.
var _queue_keys: Array = [null]

static func icon(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2(index * 16, 0, 16, 16)
	return atlas

## Symbol of the category a machine belongs to (card headers use it too).
static func icon_for(kind: String) -> AtlasTexture:
	for i in range(CATEGORIES.size()):
		if kind in CATEGORIES[i].machines:
			return icon(i)
	return null

func _box(background: Color, border: Color, width: int = 1, pad: int = 12, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

## Window frame and background: a light paper sheet with a darker rim.
func _frame() -> StyleBoxFlat:
	return _box(Color("f0eadf"), Color("b9ae97"), 2, 6, 8)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func build(sim: RefCounted) -> void:
	_sim = sim
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _box(Color(0.24, 0.2, 0.14, 0.22), Color.TRANSPARENT, 0, 0, 0))
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _frame())
	center.add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label("Envanter ve Üretim", 18, INK))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var hint := _label("Tıkla: tarif · Çift tık: makineyi yerleştir · Sürükle, sağ tıkla ya da üstündeyken 1-0: hızlı erişime sabitle", 11, MUTED)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hint)
	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 10)
	box.add_child(middle)
	_build_items(middle)
	_build_details(middle)
	_build_queue(box)
	_build_quick(box)
	select(items.keys()[0])

## Machines in category order, then products by tier, each tier in catalog order.
func _build_items(middle: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, Color("cfc6b3"), 1, 8))
	middle.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * SLOT + (COLUMNS - 1) * 4 + 14, 410)
	panel.add_child(scroll)
	var lists := VBoxContainer.new()
	lists.add_theme_constant_override("separation", 6)
	scroll.add_child(lists)
	lists.add_child(_label("Makineler", 12, MUTED))
	var machines := _grid()
	lists.add_child(machines)
	var kinds: Array = []
	for category in CATEGORIES:
		for kind in category.machines:
			if _sim.catalog.machines.has(kind):
				kinds.append(str(kind))
	for kind in _sim.catalog.machines:
		if not (str(kind) in kinds):
			kinds.append(str(kind))
	for kind in kinds:
		_item(machines, "machine:" + kind)
	lists.add_child(_label("Ürünler", 12, MUTED))
	var products := _grid()
	lists.add_child(products)
	var tiers: Dictionary = {}
	for product in _sim.catalog.products:
		if _sim.machine_of_item(str(product)).is_empty():
			var tier := int(_sim.catalog.products[product].get("tier", 0))
			if not tiers.has(tier):
				tiers[tier] = []
			tiers[tier].append(str(product))
	var order: Array = tiers.keys()
	order.sort()
	for tier in order:
		for product in tiers[tier]:
			_item(products, "product:" + str(product))

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	return grid

func _item(grid: GridContainer, key: String) -> void:
	var slot := InventorySlot.new(SLOT)
	slot.set_item(_sim, key)
	slot.pressed.connect(select.bind(key))
	slot.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click == null or not click.pressed:
			return
		if click.button_index == MOUSE_BUTTON_RIGHT:
			_toggle_pin(key)
			accept_event()
		elif click.button_index == MOUSE_BUTTON_LEFT and click.double_click:
			_place(key)
			accept_event())
	slot.mouse_entered.connect(func() -> void: _hover = key)
	slot.mouse_exited.connect(func() -> void: _hover = "")
	grid.add_child(slot)
	items[key] = slot

func _build_details(middle: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 320
	panel.add_theme_stylebox_override("panel", _box(PANEL, Color("cfc6b3"), 1, 12))
	middle.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title_row := HBoxContainer.new()
	box.add_child(title_row)
	_title = _label("", 18, INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(_title)
	_count = _label("", 13, AMBER)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_count)
	_picture = TextureRect.new()
	_picture.custom_minimum_size = Vector2(0, 88)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_picture)
	_description = _label("", 12, MUTED)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(296, 32)
	box.add_child(_description)
	var recipe_panel := PanelContainer.new()
	recipe_panel.add_theme_stylebox_override("panel", _box(Color("ece6da"), Color("cfc6b3"), 1, 8))
	box.add_child(recipe_panel)
	var recipe_box := VBoxContainer.new()
	recipe_box.add_theme_constant_override("separation", 4)
	recipe_panel.add_child(recipe_box)
	_recipe = HBoxContainer.new()
	_recipe.alignment = BoxContainer.ALIGNMENT_CENTER
	_recipe.add_theme_constant_override("separation", 8)
	recipe_box.add_child(_recipe)
	_time = _label("", 12, INK)
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_box.add_child(_time)
	_uses_title = _label("Kullanıldığı yerler", 12, MUTED)
	box.add_child(_uses_title)
	_uses = HFlowContainer.new()
	_uses.add_theme_constant_override("h_separation", 4)
	_uses.add_theme_constant_override("v_separation", 4)
	box.add_child(_uses)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	craft_button = _action_button("ÜRET", AMBER, Color("d9a659"), Color("c99442"), Color("a3722a"))
	craft_button.tooltip_text = "Tıkla: 1 adet · Shift+tık: 5 adet"
	craft_button.pressed.connect(func() -> void:
		var craft := _craft_target()
		if not craft.is_empty():
			craft_requested.emit(craft[0], craft[1], 5 if Input.is_key_pressed(KEY_SHIFT) else 1))
	box.add_child(craft_button)
	place_button = _action_button("YERLEŞTİR", Color("4f9a8a"), Color("7bb8ab"), Color("67a99c"), Color("43867a"))
	place_button.pressed.connect(func() -> void: _place(selected))
	box.add_child(place_button)
	_reason = _label("", 11, RED)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_reason)

func _action_button(text: String, fill: Color, border: Color, hover: Color, pressed: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 15)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color("1d1a14"))
	button.add_theme_color_override("font_disabled_color", Color("a89d88"))
	button.add_theme_stylebox_override("normal", _box(fill, border, 1, 6))
	button.add_theme_stylebox_override("hover", _box(hover, border.lightened(0.3), 1, 6))
	button.add_theme_stylebox_override("pressed", _box(pressed, border, 1, 6))
	button.add_theme_stylebox_override("disabled", _box(Color("e4ddd0"), EDGE, 1, 6))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _build_queue(box: VBoxContainer) -> void:
	_queue_title = _label("", 13, INK)
	box.add_child(_queue_title)
	_queue_row = HBoxContainer.new()
	_queue_row.add_theme_constant_override("separation", 6)
	_queue_row.custom_minimum_size.y = 52
	box.add_child(_queue_row)

func _build_quick(box: VBoxContainer) -> void:
	box.add_child(_label("Hızlı erişim (alt çubuk)", 13, INK))
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	box.add_child(quick)
	for i in range(10):
		var slot := InventorySlot.new(SLOT)
		slot.show_number(i)
		slot.on_drop = func(index: int, key: String) -> void: pin_requested.emit(key, index)
		slot.pressed.connect(func() -> void:
			if not slot.key.is_empty():
				select(slot.key))
		slot.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not slot.key.is_empty():
				unpin_requested.emit(i)
				accept_event())
		slot.mouse_entered.connect(func() -> void: _hover = slot.key)
		slot.mouse_exited.connect(func() -> void: _hover = "")
		quick.add_child(slot)
		quick_slots.append(slot)

## While an item is dragged, the dimmed backdrop lets it through so it can be dropped on a
## machine card's input behind the window; the window itself still takes drops.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif what == NOTIFICATION_DRAG_END:
		mouse_filter = Control.MOUSE_FILTER_STOP

func select(key: String) -> void:
	if not items.has(key):
		return
	if items.has(selected):
		items[selected].selected = false
		items[selected].queue_redraw()
	selected = key
	items[key].selected = true
	items[key].queue_redraw()
	_show_details()

func toggle() -> void:
	visible = not visible
	_hover = ""
	if visible:
		refresh(_sim)

func refresh(sim: RefCounted) -> void:
	_sim = sim
	if not visible:
		return
	for key in items:
		var slot: InventorySlot = items[key]
		slot.pinned = key in sim.hotbar
		slot.locked = not _is_open(str(key))
		slot.set_item(sim, str(key))
	for i in range(quick_slots.size()):
		quick_slots[i].set_item(sim, sim.hotbar[i])
	_show_details()
	_refresh_queue(sim)

## A machine is open once researched; a product once some machine may make it.
func _is_open(key: String) -> bool:
	var parts := key.split(":")
	if parts[0] == "machine":
		return _sim.is_machine_unlocked(parts[1])
	for producer in _producers(parts[1]):
		if producer.unlocked:
			return true
	return false

## Recipes that make `product`, hand-craftable ones first; machine items are left out.
func _producers(product: String) -> Array:
	var hand: Array = []
	var other: Array = []
	for producer in _sim.producers_for(product):
		if not _sim.catalog.recipes[producer.recipe].has("builds"):
			(hand if _sim.catalog.machines[producer.kind].get("handcraft", false) else other).append(producer)
	return hand + other

## [type, id] the ÜRET button crafts for the selection, or [] when the hand cannot make it.
func _craft_target() -> Array:
	var parts := selected.split(":")
	if parts[0] == "machine":
		return ["machine", parts[1]]
	var producers := _producers(parts[1])
	if not producers.is_empty() and _sim.catalog.machines[producers[0].kind].get("handcraft", false):
		return ["recipe", str(producers[0].recipe)]
	return []

func _name(key: String) -> String:
	var parts := key.split(":")
	return str(_sim.catalog.machines[parts[1]].name) if parts[0] == "machine" else _sim.product_name(parts[1])

func _picture_for(key: String) -> Texture2D:
	var parts := key.split(":")
	if parts[0] == "machine":
		return Icons.machine(SpriteMachineCard.art_path(parts[1]))
	return Icons.product(_sim, parts[1])

## Why the selection cannot be hand crafted right now, or "" when it can.
func _blocker(type: String, id: String) -> String:
	if not _sim.is_craft_unlocked(type, id):
		var tech: String = _sim.unlock_tech_for_machine(id) if type == "machine" else _sim.unlock_tech_for_recipe(id)
		return "Kilitli: %s" % (_sim.catalog.researches[tech].name if _sim.catalog.researches.has(tech) else "?")
	if type == "machine" and _sim.build_limit(id) >= 0 and _sim.machine_total(id) >= _sim.build_limit(id):
		return "Sınıra ulaşıldı: en fazla %d" % _sim.build_limit(id)
	if not _sim.can_craft(type, id):
		return "Malzeme eksik"
	return ""

## Selected item: picture, description, recipe with what you carry (red when short), time,
## and what it goes into.
func _show_details() -> void:
	for row in [_recipe, _uses]:
		for child in row.get_children():
			child.queue_free()
	if selected.is_empty():
		return
	var parts := selected.split(":")
	var is_machine := parts[0] == "machine"
	var id := parts[1]
	_title.text = _name(selected)
	_count.text = "Envanterde: %d" % _sim.carried_count(selected)
	_picture.texture = _picture_for(selected)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if is_machine else CanvasItem.TEXTURE_FILTER_NEAREST
	place_button.visible = is_machine and _sim.carried_count(selected) > 0
	place_button.disabled = is_machine and not _sim.can_place(id)
	var craft := _craft_target()
	var producers: Array = [] if is_machine else _producers(id)
	if is_machine:
		_description.text = str(_sim.catalog.machines[id].get("description", ""))
	elif producers.is_empty():
		_description.text = "Hiçbir makine üretmiyor."
	else:
		var makers: PackedStringArray = []
		for producer in producers:
			if not (producer.machine_name in makers):
				makers.append(producer.machine_name)
		_description.text = "%s: %s" % ["Elde ya da makinede üretilir" if not craft.is_empty() else "Makinede üretilir", ", ".join(makers)]
	var recipe_id := ""
	var inputs: Dictionary = {}
	if is_machine:
		inputs = _sim.craft_inputs("machine", id)
	elif not producers.is_empty():
		recipe_id = str(producers[0].recipe)
		inputs = _sim.catalog.recipes[recipe_id].inputs
	_recipe.get_parent().get_parent().visible = is_machine or not producers.is_empty()
	for product in inputs:
		var have := int(_sim.inventory.get(product, 0))
		var need := int(inputs[product])
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.tooltip_text = "%s: %d / %d" % [_sim.product_name(str(product)), have, need]
		var slot := Icons.Slot.new(Icons.product(_sim, str(product)), 1)
		column.add_child(slot)
		var amount := _label("%d/%d" % [have, need], 11, RED if have < need else INK)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(amount)
		_recipe.add_child(column)
	if inputs.is_empty() and not is_machine:
		var raw := _label("Hammadde", 12, MUTED)
		raw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_recipe.add_child(raw)
	var arrow := _label("→", 20, MUTED)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_recipe.add_child(arrow)
	var result: Icons.Slot
	if is_machine:
		result = Icons.Slot.new(_picture_for(selected), 1)
		result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		result = Icons.Slot.new(_picture_for(selected), int(producers[0].output_amount) if not producers.is_empty() else 1)
	result.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_recipe.add_child(result)
	if not craft.is_empty():
		_time.text = "Elle üretim: %.1f sn" %(_sim.craft_work(craft[0], craft[1]) / _sim.hand_speed)
	elif not recipe_id.is_empty():
		_time.text = "%s · %s" % [producers[0].machine_name, producers[0].recipe_name]
	else:
		_time.text = ""
	_show_uses(id if not is_machine else "")
	craft_button.visible = not craft.is_empty()
	var blocker := _blocker(craft[0], craft[1]) if not craft.is_empty() else ""
	if craft.is_empty() and not producers.is_empty():
		blocker = "Elde yapılamaz: makinede üretilir." if producers[0].unlocked else "Kilitli: %s" % _tech_name(str(producers[0].unlock_tech))
	craft_button.disabled = not blocker.is_empty()
	craft_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if craft_button.disabled else Control.CURSOR_POINTING_HAND
	_reason.text = blocker

func _tech_name(tech: String) -> String:
	return str(_sim.catalog.researches[tech].name) if _sim.catalog.researches.has(tech) else "?"

## Products and machines that take `product`, as clickable icons.
func _show_uses(product: String) -> void:
	var uses: Array = []
	if not product.is_empty():
		for r_id in _sim.catalog.recipes:
			var spec: Dictionary = _sim.catalog.recipes[r_id]
			if spec.has("builds") or not spec.inputs.has(product):
				continue
			for output in spec.outputs:
				var key := "product:" + str(output)
				if output != "metal_scrap" and items.has(key) and not (key in uses):
					uses.append(key)
				break
		for kind in _sim.catalog.machines:
			if _sim.catalog.machines[kind].get("build_cost", {}).has(product):
				uses.append("machine:" + str(kind))
	_uses_title.visible = not uses.is_empty()
	_uses.visible = not uses.is_empty()
	for i in range(mini(uses.size(), USES_SHOWN)):
		var key: String = uses[i]
		var button := Button.new()
		button.flat = true
		button.custom_minimum_size = Vector2(30, 30)
		button.icon = _picture_for(key)
		button.expand_icon = true
		button.tooltip_text = _name(key)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if key.begins_with("machine:") else CanvasItem.TEXTURE_FILTER_NEAREST
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(select.bind(key))
		_uses.add_child(button)
	if uses.size() > USES_SHOWN:
		_uses.add_child(_label("+%d" % (uses.size() - USES_SHOWN), 12, MUTED))

func _refresh_queue(sim: RefCounted) -> void:
	_queue_title.text = "Üretim sırası (%d)" % sim.craft_queue.size()
	var keys: Array = []
	for job in sim.craft_queue:
		keys.append("%s:%s" % [job.type, job.id])
	if keys != _queue_keys:
		_queue_keys = keys
		queue_slots.clear()
		for child in _queue_row.get_children():
			child.queue_free()
		if keys.is_empty():
			var empty := _label("Sıra boş: bir öğe seçip ÜRET'e bas.", 12, MUTED)
			empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_queue_row.add_child(empty)
		for i in range(sim.craft_queue.size()):
			_queue_row.add_child(_queue_card(sim, i))
	var waited := 0.0
	for i in range(queue_slots.size()):
		var job: Dictionary = sim.craft_queue[i]
		waited += float(job.remaining)
		queue_slots[i].bar.value = 1.0 - float(job.remaining) / sim.craft_work(str(job.type), str(job.id))
		queue_slots[i].time.text = "%.1f sn" % (waited / sim.hand_speed)

func _queue_card(sim: RefCounted, index: int) -> Control:
	var job: Dictionary = sim.craft_queue[index]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 50)
	card.add_theme_stylebox_override("panel", _box(PANEL, Color("cfc6b3"), 1, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var type := str(job.type)
	var id := str(job.id)
	var slot: Icons.Slot
	if type == "machine":
		slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), 1)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		slot.tooltip_text = str(sim.catalog.machines[id].name)
	else:
		var output := str(sim.catalog.recipes[id].outputs.keys()[0])
		slot = Icons.Slot.new(Icons.product(sim, output), int(sim.catalog.recipes[id].outputs[output]))
		slot.tooltip_text = str(sim.catalog.recipes[id].get("name", id))
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(slot)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(middle)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.0
	bar.custom_minimum_size = Vector2(70, 6)
	bar.add_theme_stylebox_override("background", _box(Color("e4ddd0"), Color.TRANSPARENT, 0, 0, 2))
	bar.add_theme_stylebox_override("fill", _box(Color("4f9a8a"), Color.TRANSPARENT, 0, 0, 2))
	middle.add_child(bar)
	var time := _label("", 12, INK)
	middle.add_child(time)
	var cancel := Button.new()
	cancel.text = "×"
	cancel.flat = true
	cancel.tooltip_text = "İptal et (malzeme geri döner)"
	cancel.add_theme_font_size_override("font_size", 16)
	cancel.add_theme_color_override("font_color", MUTED)
	cancel.add_theme_color_override("font_hover_color", RED)
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(func() -> void: craft_cancelled.emit(index))
	row.add_child(cancel)
	queue_slots.append({"bar": bar, "time": time, "cancel": cancel})
	return card

func _toggle_pin(key: String) -> void:
	var index: int = _sim.hotbar.find(key)
	if index >= 0:
		unpin_requested.emit(index)
	else:
		pin_requested.emit(key, -1)

func _place(key: String) -> void:
	if key.begins_with("machine:") and _sim.can_place(key.trim_prefix("machine:")):
		hide()
		machine_requested.emit(key.trim_prefix("machine:"))

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_C or key.keycode == KEY_I:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if key.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
		return
	var index := -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9:
		index = key.keycode - KEY_1
	elif key.keycode == KEY_0:
		index = 9
	if index >= 0:
		if not _hover.is_empty():
			pin_requested.emit(_hover, index)
		get_viewport().set_input_as_handled()
