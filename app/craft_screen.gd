extends PanelContainer
## Hand crafting screen. Category symbols along the top; each category lists its machines
## and the products its hand-craftable machines make. Hovering a slot shows the recipe as
## icons (inputs with what you carry → output, time); clicking queues one, shift-click five.
## C opens and closes it, 1-7 switch category, Esc closes.

signal craft_requested(type: String, id: String, count: int)

const Icons = preload("res://app/icons.gd")
const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const ICONS := preload("res://app/art/ui/category_icons.png")
const INK := Color("dce9ef")
const MUTED := Color("8ca5b6")
const TEAL := Color("61d8bb")
## Order matches the icon strip (art_src/araclar/kategori_ikonlari.py); the hammer after
## the last category is the craft button's symbol.
const CATEGORIES := [
	{"name": "Hammadde", "machines": ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]},
	{"name": "Metalürji", "machines": ["smelter", "steel_furnace"]},
	{"name": "Şekillendirme", "machines": ["rolling_mill", "press", "foundry"]},
	{"name": "Talaşlı imalat", "machines": ["lathe", "cnc"]},
	{"name": "Montaj", "machines": ["assembler", "wire_winder"]},
	{"name": "Araştırma ve hedefler", "machines": ["lab_1", "lab_2", "lab_3", "project_hub", "scrap_disposal"]},
	{"name": "Depo", "machines": ["storage"]},
]
const CRAFT_ICON := 7

var category_buttons: Array[Button] = []
## "machine:<kind>" or "recipe:<id>" -> slot button
var tiles: Dictionary = {}
var open_index := 0
var _sim: RefCounted
var _hover := ""
var _pages: Array[GridContainer] = []
var _title: Label
var _preview: HBoxContainer

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

func _box(background: Color, border: Color, width: int = 1, pad: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(pad)
	return style

func _style(button: Button, active: bool) -> void:
	for state in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, _box(Color("1b3140") if active else Color("162938"), TEAL if active else Color("2b475c"), 2 if active else 1, 4))
	button.add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL, 2, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("295258"), TEAL, 2, 4))

func build(sim: RefCounted) -> void:
	_sim = sim
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _box(Color(0.02, 0.05, 0.08, 0.5), Color.TRANSPARENT, 0, 0))
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var dialog := PanelContainer.new()
	dialog.add_theme_stylebox_override("panel", _box(Color("0f1d28"), Color("30495b"), 2, 14))
	center.add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	dialog.add_child(box)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	for i in range(CATEGORIES.size()):
		var button := Button.new()
		button.icon = icon(i)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(40, 40)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = str(CATEGORIES[i].name)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(open_category.bind(i))
		tabs.add_child(button)
		category_buttons.append(button)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", INK)
	box.add_child(_title)
	var grid_panel := PanelContainer.new()
	grid_panel.add_theme_stylebox_override("panel", _box(Color("09131c"), Color("1c3142"), 1, 6))
	grid_panel.custom_minimum_size = Vector2(8 * 52 + 12, 2 * 52 + 12)
	box.add_child(grid_panel)
	var handmade: Array = sim.handcraft_recipes()
	for category in CATEGORIES:
		var page := GridContainer.new()
		page.columns = 8
		page.add_theme_constant_override("h_separation", 4)
		page.add_theme_constant_override("v_separation", 4)
		grid_panel.add_child(page)
		_pages.append(page)
		for kind in category.machines:
			_tile(page, "machine", str(kind))
		for kind in category.machines:
			var spec: Dictionary = sim.catalog.machines[kind]
			for r_id in spec.get("recipes", [spec.recipe]):
				if str(r_id) in handmade and not tiles.has("recipe:" + str(r_id)):
					_tile(page, "recipe", str(r_id))
	_preview = HBoxContainer.new()
	_preview.add_theme_constant_override("separation", 6)
	_preview.custom_minimum_size.y = 40
	box.add_child(_preview)
	open_category(0)

func _tile(page: GridContainer, type: String, id: String) -> void:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(48, 48)
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style(tile, false)
	var slot: Icons.Slot
	if type == "machine":
		slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), 1)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		var recipe: Dictionary = _sim.catalog.recipes[id]
		var product := str(recipe.outputs.keys()[0])
		slot = Icons.Slot.new(Icons.product(_sim, product), int(recipe.outputs[product]))
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tile.add_child(slot)
	var key := "%s:%s" % [type, id]
	tile.mouse_entered.connect(func() -> void:
		_hover = key
		_show_recipe(type, id))
	tile.pressed.connect(func() -> void:
		craft_requested.emit(type, id, 5 if Input.is_key_pressed(KEY_SHIFT) else 1)
		_show_recipe(type, id))
	page.add_child(tile)
	tiles[key] = tile

func open_category(index: int) -> void:
	open_index = index
	for i in range(_pages.size()):
		_pages[i].visible = i == index
		_style(category_buttons[i], i == index)
	_title.text = str(CATEGORIES[index].name)
	for child in _preview.get_children():
		child.queue_free()

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
		tile.disabled = not ready
		tile.modulate.a = 1.0 if ready else (0.6 if unlocked else 0.3)
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ready else Control.CURSOR_FORBIDDEN
		tile.tooltip_text = _name(parts[0], parts[1])
		if not unlocked:
			var tech: String = sim.unlock_tech_for_machine(parts[1]) if parts[0] == "machine" else sim.unlock_tech_for_recipe(parts[1])
			tile.tooltip_text += "\nKilitli: %s" % (sim.catalog.researches[tech].name if sim.catalog.researches.has(tech) else "?")
		elif parts[0] == "machine" and sim.build_limit(parts[1]) >= 0 and sim.machine_total(parts[1]) >= sim.build_limit(parts[1]):
			tile.tooltip_text += "\nSınıra ulaşıldı: en fazla %d" % sim.build_limit(parts[1])
	if not _hover.is_empty():
		var parts: PackedStringArray = _hover.split(":")
		_show_recipe(parts[0], parts[1])

func _name(type: String, id: String) -> String:
	return str(_sim.catalog.machines[id].name) if type == "machine" else str(_sim.catalog.recipes[id].get("name", id))

## Recipe as icons: each input with how many you carry (red when short), the output, time.
func _show_recipe(type: String, id: String) -> void:
	for child in _preview.get_children():
		child.queue_free()
	var inputs: Dictionary = _sim.craft_inputs(type, id)
	for product in inputs:
		var slot := Icons.Slot.new(Icons.product(_sim, str(product)), int(inputs[product]))
		slot.show_one = true
		slot.short = int(_sim.inventory.get(product, 0)) < int(inputs[product])
		slot.tooltip_text = "%s: %d / %d" % [_sim.product_name(str(product)), int(_sim.inventory.get(product, 0)), int(inputs[product])]
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		_preview.add_child(slot)
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", MUTED)
	_preview.add_child(arrow)
	if type == "machine":
		var machine_slot := Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), 1)
		machine_slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_preview.add_child(machine_slot)
	else:
		var outputs: Dictionary = _sim.catalog.recipes[id].outputs
		for product in outputs:
			_preview.add_child(Icons.Slot.new(Icons.product(_sim, str(product)), int(outputs[product])))
	var info := Label.new()
	info.text = "  %s · %.1f sn" % [_name(type, id), _sim.craft_work(type, id) / _sim.hand_speed]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", MUTED)
	_preview.add_child(info)
	for child in _preview.get_children():
		if child is Label:
			child.size_flags_vertical = Control.SIZE_SHRINK_CENTER

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
