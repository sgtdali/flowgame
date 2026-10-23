extends PanelContainer
## Hand crafting screen (style A: dark frame, amber accents). Category tabs along
## the top; the selected category lists its machines and the products its hand-craftable
## machines make. Clicking a tile shows it on the right: picture, description, recipe with
## what you carry (red when short), time and the ÜRET button (shift: five). Below sit the
## craft queue (× cancels and refunds) and what you carry.
## C opens and closes it, 1-7 switch category, Esc closes.

signal craft_requested(type: String, id: String, count: int)
signal craft_cancelled(index: int)

const Icons = preload("res://app/icons.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const ICONS := preload("res://app/art/ui/category_icons.png")
const FRAME := preload("res://app/art/ui/panel_frame.png")
const INK := Color("e8e4dc")
const MUTED := Color("8d949b")
const AMBER := Color("f2a33a")
const RED := Color("e0634b")
const PANEL := Color("16191c")
const TILE := Color("23272c")
const EDGE := Color("363d45")
## Order matches the icon strip (art_src/araclar/kategori_ikonlari.py); the hammer after
## the last category is the craft button's symbol.
const CATEGORIES := [
	{"name": "Hammadde", "tab": "Hammadde", "machines": ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]},
	{"name": "Metalürji", "tab": "Metalürji", "machines": ["smelter", "steel_furnace"]},
	{"name": "Şekillendirme", "tab": "Şekillendirme", "machines": ["rolling_mill", "press", "foundry"]},
	{"name": "Talaşlı imalat", "tab": "Talaşlı", "machines": ["lathe", "cnc"]},
	{"name": "Montaj", "tab": "Montaj", "machines": ["assembler", "wire_winder"]},
	{"name": "Araştırma ve hedefler", "tab": "Araştırma", "machines": ["lab_1", "lab_2", "lab_3", "project_hub", "scrap_disposal"]},
	{"name": "Depo", "tab": "Depo", "machines": ["storage"]},
]
const CRAFT_ICON := 7
const TAB_SIZE := Vector2(100, 62)
const TILE_SIZE := Vector2(96, 104)
const COLUMNS := 4

var category_buttons: Array[Button] = []
## "machine:<kind>" or "recipe:<id>" -> tile button
var tiles: Dictionary = {}
var open_index := 0
var selected := ""
var craft_button: Button
## One per queued job: {bar, time, cancel}
var queue_slots: Array[Dictionary] = []
var _sim: RefCounted
var _pages: Array[GridContainer] = []
var _scroll: ScrollContainer
var _title: Label
var _picture: TextureRect
var _description: Label
var _recipe: HBoxContainer
var _time: Label
var _reason: Label
var _queue_title: Label
var _queue_row: HBoxContainer
## Starts unequal to any real queue so the first refresh builds the row.
var _queue_keys: Array = [null]
var _carried: HFlowContainer
var _carried_keys: Array = []
var _carried_slots: Array[Icons.Slot] = []

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

## Window frame and background: 9-slice of art_src/ui/menu_cerceve/zemin_ve_kenarlik.png,
## drawn in LibreSprite at the window's real size. The top corners' bevel reaches 16 px in.
func _frame() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = FRAME
	style.set_texture_margin_all(16)
	style.set_content_margin_all(6)
	return style

func _style(button: Button, active: bool) -> void:
	for state in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, _box(Color("2a2722") if active else TILE, AMBER if active else EDGE, 2 if active else 1, 4))
	button.add_theme_stylebox_override("hover", _box(Color("2c3036"), AMBER if active else AMBER.darkened(0.35), 2 if active else 1, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("332e26"), AMBER, 2, 4))

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
	add_theme_stylebox_override("panel", _box(Color(0.02, 0.03, 0.04, 0.55), Color.TRANSPARENT, 0, 0, 0))
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _frame())
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	_build_tabs(box)
	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 10)
	box.add_child(middle)
	_build_tiles(middle)
	_build_details(middle)
	_build_queue(box)
	_build_carried(box)
	open_category(0)

func _build_tabs(box: VBoxContainer) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	for i in range(CATEGORIES.size()):
		var button := Button.new()
		button.custom_minimum_size = TAB_SIZE
		button.tooltip_text = "%s (%d)" % [CATEGORIES[i].name, i + 1]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(open_category.bind(i))
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(content)
		var picture := TextureRect.new()
		picture.texture = icon(i)
		picture.custom_minimum_size = Vector2(32, 32)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(picture)
		var name_label := _label(str(CATEGORIES[i].tab), 12, INK)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.name = "Name"
		content.add_child(name_label)
		tabs.add_child(button)
		category_buttons.append(button)

func _build_tiles(middle: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, Color("2c3238"), 1, 8))
	middle.add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(COLUMNS * TILE_SIZE.x + (COLUMNS - 1) * 6 + 2, 2 * TILE_SIZE.y + 6)
	panel.add_child(_scroll)
	var handmade: Array = _sim.handcraft_recipes()
	var pages := VBoxContainer.new()
	_scroll.add_child(pages)
	for category in CATEGORIES:
		var page := GridContainer.new()
		page.columns = COLUMNS
		page.add_theme_constant_override("h_separation", 6)
		page.add_theme_constant_override("v_separation", 6)
		pages.add_child(page)
		_pages.append(page)
		for kind in category.machines:
			_tile(page, "machine", str(kind))
		for kind in category.machines:
			var spec: Dictionary = _sim.catalog.machines[kind]
			for r_id in spec.get("recipes", [spec.recipe]):
				if str(r_id) in handmade and not tiles.has("recipe:" + str(r_id)):
					_tile(page, "recipe", str(r_id))

func _picture_for(type: String, id: String) -> Texture2D:
	if type == "machine":
		return Icons.machine(SpriteMachineCard.art_path(id))
	return Icons.product(_sim, _output_of(id))

func _output_of(recipe_id: String) -> String:
	return str(_sim.catalog.recipes[recipe_id].outputs.keys()[0])

func _tile(page: GridContainer, type: String, id: String) -> void:
	var tile := Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style(tile, false)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_right = -4
	tile.add_child(content)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = _picture_for(type, id)
	picture.custom_minimum_size = Vector2(64, 64)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if type == "machine" else CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	var name_label := _label(_name(type, id), 11, INK)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size.x = TILE_SIZE.x - 8
	content.add_child(name_label)
	if type == "recipe":
		var amount := int(_sim.catalog.recipes[id].outputs[_output_of(id)])
		if amount > 1:
			var badge := _label("×%d" % amount, 11, AMBER)
			badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			badge.offset_left = -30
			badge.offset_right = -6
			badge.offset_top = 4
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			tile.add_child(badge)
	var lock := Padlock.new()
	lock.name = "Lock"
	lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock.offset_bottom = -22
	lock.visible = false
	tile.add_child(lock)
	var key := "%s:%s" % [type, id]
	tile.pressed.connect(select.bind(key))
	page.add_child(tile)
	tiles[key] = tile

func _build_details(middle: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = 290
	panel.add_theme_stylebox_override("panel", _box(PANEL, Color("2c3238"), 1, 12))
	middle.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_title = _label("", 18, INK)
	box.add_child(_title)
	_picture = TextureRect.new()
	_picture.custom_minimum_size = Vector2(0, 96)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_picture)
	_description = _label("", 12, MUTED)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(266, 32)
	box.add_child(_description)
	var recipe_panel := PanelContainer.new()
	recipe_panel.add_theme_stylebox_override("panel", _box(Color("1f2327"), Color("2c3238"), 1, 8))
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
	recipe_box.add_child(_time)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	craft_button = Button.new()
	craft_button.text = "ÜRET"
	craft_button.custom_minimum_size.y = 40
	craft_button.tooltip_text = "Tıkla: 1 adet · Shift+tık: 5 adet"
	craft_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	craft_button.add_theme_font_size_override("font_size", 16)
	craft_button.add_theme_color_override("font_color", Color("1d1a14"))
	craft_button.add_theme_color_override("font_hover_color", Color("1d1a14"))
	craft_button.add_theme_color_override("font_pressed_color", Color("1d1a14"))
	craft_button.add_theme_color_override("font_disabled_color", Color("6d747b"))
	craft_button.add_theme_stylebox_override("normal", _box(AMBER, Color("ffc46e"), 1, 6))
	craft_button.add_theme_stylebox_override("hover", _box(Color("ffb550"), Color("ffd99a"), 1, 6))
	craft_button.add_theme_stylebox_override("pressed", _box(Color("d98a24"), Color("ffc46e"), 1, 6))
	craft_button.add_theme_stylebox_override("disabled", _box(Color("2b2f34"), EDGE, 1, 6))
	craft_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	craft_button.pressed.connect(func() -> void:
		var parts := selected.split(":")
		craft_requested.emit(parts[0], parts[1], 5 if Input.is_key_pressed(KEY_SHIFT) else 1))
	box.add_child(craft_button)
	_reason = _label("", 11, RED)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_reason)

func _build_queue(box: VBoxContainer) -> void:
	_queue_title = _label("", 13, INK)
	box.add_child(_queue_title)
	_queue_row = HBoxContainer.new()
	_queue_row.add_theme_constant_override("separation", 6)
	_queue_row.custom_minimum_size.y = 52
	box.add_child(_queue_row)

func _build_carried(box: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var title := _label("Envanter", 13, INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	_carried = HFlowContainer.new()
	_carried.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carried.add_theme_constant_override("h_separation", 4)
	_carried.add_theme_constant_override("v_separation", 4)
	row.add_child(_carried)

func open_category(index: int) -> void:
	open_index = index
	for i in range(_pages.size()):
		_pages[i].visible = i == index
		_style(category_buttons[i], i == index)
		var name_label: Label = category_buttons[i].find_child("Name", true, false)
		name_label.add_theme_color_override("font_color", AMBER if i == index else INK)
	_scroll.scroll_vertical = 0
	if _pages[index].get_child_count() > 0:
		for key in tiles:
			if tiles[key] == _pages[index].get_child(0):
				select(str(key))
				break

func select(key: String) -> void:
	selected = key
	for tile_key in tiles:
		_style(tiles[tile_key], tile_key == key)
	_show_details()

func toggle() -> void:
	visible = not visible
	if visible:
		refresh(_sim)

func refresh(sim: RefCounted) -> void:
	_sim = sim
	if not visible:
		return
	for key in tiles:
		var parts: PackedStringArray = str(key).split(":")
		var tile: Button = tiles[key]
		var unlocked: bool = sim.is_craft_unlocked(parts[0], parts[1])
		var ready: bool = sim.can_craft(parts[0], parts[1])
		tile.get_node("Lock").visible = not unlocked
		tile.find_child("Picture", true, false).modulate.a = 1.0 if ready else (0.5 if unlocked else 0.18)
		var name_label: Label = tile.find_child("Name", true, false)
		name_label.add_theme_color_override("font_color", INK if unlocked else MUTED)
		tile.tooltip_text = _name(parts[0], parts[1])
		var blocker := _blocker(parts[0], parts[1])
		if not blocker.is_empty():
			tile.tooltip_text += "\n" + blocker
	_show_details()
	_refresh_queue(sim)
	_refresh_carried(sim)

func _name(type: String, id: String) -> String:
	return str(_sim.catalog.machines[id].name) if type == "machine" else str(_sim.catalog.recipes[id].get("name", id))

## Why a tile cannot be crafted right now, or "" when it can.
func _blocker(type: String, id: String) -> String:
	if not _sim.is_craft_unlocked(type, id):
		var tech: String = _sim.unlock_tech_for_machine(id) if type == "machine" else _sim.unlock_tech_for_recipe(id)
		return "Kilitli: %s" % (_sim.catalog.researches[tech].name if _sim.catalog.researches.has(tech) else "?")
	if type == "machine" and _sim.build_limit(id) >= 0 and _sim.machine_total(id) >= _sim.build_limit(id):
		return "Sınıra ulaşıldı: en fazla %d" % _sim.build_limit(id)
	if not _sim.can_craft(type, id):
		return "Malzeme eksik"
	return ""

## Selected tile: picture, description, recipe with what you carry (red when short), time.
func _show_details() -> void:
	for child in _recipe.get_children():
		child.queue_free()
	if selected.is_empty():
		return
	var parts := selected.split(":")
	var type := parts[0]
	var id := parts[1]
	_title.text = _name(type, id)
	_picture.texture = _picture_for(type, id)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if type == "machine" else CanvasItem.TEXTURE_FILTER_NEAREST
	if type == "machine":
		_description.text = str(_sim.catalog.machines[id].get("description", ""))
	else:
		var product := _output_of(id)
		_description.text = "Elde %d× %s üretir." % [int(_sim.catalog.recipes[id].outputs[product]), _sim.product_name(product)]
	var inputs: Dictionary = _sim.craft_inputs(type, id)
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
	var arrow := _label("→", 20, MUTED)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_recipe.add_child(arrow)
	var result: Icons.Slot
	if type == "machine":
		result = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), 1)
		result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		result = Icons.Slot.new(Icons.product(_sim, _output_of(id)), int(_sim.catalog.recipes[id].outputs[_output_of(id)]))
	result.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_recipe.add_child(result)
	_time.text = "Süre: %.1f sn" % (_sim.craft_work(type, id) / _sim.hand_speed)
	var blocker := _blocker(type, id)
	craft_button.disabled = not blocker.is_empty()
	craft_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if craft_button.disabled else Control.CURSOR_POINTING_HAND
	_reason.text = blocker

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
	card.add_theme_stylebox_override("panel", _box(PANEL, Color("2c3238"), 1, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var type := str(job.type)
	var id := str(job.id)
	var slot: Icons.Slot
	if type == "machine":
		slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), 1)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		slot = Icons.Slot.new(Icons.product(sim, _output_of(id)), int(sim.catalog.recipes[id].outputs[_output_of(id)]))
	slot.tooltip_text = _name(type, id)
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
	bar.add_theme_stylebox_override("background", _box(Color("2b2f34"), Color.TRANSPARENT, 0, 0, 2))
	bar.add_theme_stylebox_override("fill", _box(Color("4fc39a"), Color.TRANSPARENT, 0, 0, 2))
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

func _refresh_carried(sim: RefCounted) -> void:
	var keys: Array = []
	for product in sim.catalog.products:
		if int(sim.inventory.get(product, 0)) > 0:
			keys.append(str(product))
	if keys != _carried_keys:
		_carried_keys = keys
		_carried_slots.clear()
		for child in _carried.get_children():
			child.queue_free()
		for product in keys:
			var cell := PanelContainer.new()
			cell.add_theme_stylebox_override("panel", _box(TILE, EDGE, 1, 2))
			var slot := Icons.Slot.new(Icons.product(sim, product), 1)
			slot.name = "Slot"
			slot.show_one = true
			slot.custom_minimum_size = Vector2(40, 36)
			slot.tooltip_text = sim.product_name(product)
			slot.mouse_filter = Control.MOUSE_FILTER_PASS
			cell.add_child(slot)
			_carried.add_child(cell)
			_carried_slots.append(slot)
	for i in range(_carried_slots.size()):
		var slot: Icons.Slot = _carried_slots[i]
		slot.count = int(sim.inventory.get(keys[i], 0))
		slot.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_C:
		toggle()
		get_viewport().set_input_as_handled()
	elif not visible:
		return
	elif key.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
	elif key.keycode >= KEY_1 and key.keycode < KEY_1 + CATEGORIES.size():
		open_category(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()

## Padlock drawn over a locked tile.
class Padlock extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_arc(c + Vector2(0, -4), 7, PI, TAU, 16, Color("9aa1a8"), 3)
		draw_rect(Rect2(c + Vector2(-11, -4), Vector2(22, 17)), Color("9aa1a8"))
		draw_rect(Rect2(c + Vector2(-2, 1), Vector2(4, 7)), Color("23272c"))
