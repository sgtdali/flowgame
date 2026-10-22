extends VBoxContainer
## Bottom build bar: a row of category symbols; opening one shows that category's machines
## as picture tiles above it. Keys 1-6 open categories, Esc closes the tray.

signal machine_requested(kind: String)

const SpriteMachineCard = preload("res://app/sprite_machine_card.gd")
const ICONS := preload("res://app/art/ui/category_icons.png")
const INK := Color("dce9ef")
const MUTED := Color("7f99aa")
const TEAL := Color("61d8bb")
## Order matches the icon strip (art_src/araclar/kategori_ikonlari.py).
const CATEGORIES := [
	{"name": "Hammadde", "machines": ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]},
	{"name": "Metalürji", "machines": ["smelter", "steel_furnace"]},
	{"name": "Şekillendirme", "machines": ["rolling_mill", "press", "foundry"]},
	{"name": "Talaşlı imalat", "machines": ["lathe", "cnc"]},
	{"name": "Montaj", "machines": ["assembler", "wire_winder"]},
	{"name": "Araştırma ve hedefler", "machines": ["lab_1", "lab_2", "lab_3", "project_hub", "scrap_disposal"]},
]

var category_buttons: Array[Button] = []
var trays: Array[HBoxContainer] = []
var tiles: Dictionary = {}
var open_index := -1
var _tray_panel: PanelContainer
var _unlock_tech: Dictionary = {}

func _box(background: Color, border: Color, pad: int, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

func _icon(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2(index * 16, 0, 16, 16)
	return atlas

## Symbol of the category a machine belongs to (used on card headers too).
func icon_for(kind: String) -> AtlasTexture:
	for i in range(CATEGORIES.size()):
		if kind in CATEGORIES[i].machines:
			return _icon(i)
	return null

func _style_button(button: Button, active: bool) -> void:
	var border := TEAL if active else Color("294356")
	button.add_theme_stylebox_override("normal", _box(Color("1b3140") if active else Color("12222e"), border, 6))
	button.add_theme_stylebox_override("hover", _box(Color("213b4d"), TEAL, 6))
	button.add_theme_stylebox_override("pressed", _box(Color("295258"), TEAL, 6))
	button.add_theme_stylebox_override("disabled", _box(Color("0d1a24"), Color("1c3142"), 6))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func build(catalog: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 6)
	for tech_id in catalog.get("researches", {}):
		for kind in catalog.researches[tech_id].get("unlock_machines", []):
			if not _unlock_tech.has(kind):
				_unlock_tech[kind] = str(catalog.researches[tech_id].name)
	_tray_panel = PanelContainer.new()
	_tray_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tray_panel.add_theme_stylebox_override("panel", _box(Color("0d1a24e6"), Color("1c3142"), 6))
	_tray_panel.visible = false
	add_child(_tray_panel)
	var tray_stack := VBoxContainer.new()
	_tray_panel.add_child(tray_stack)
	var bar := PanelContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("panel", _box(Color("0d1a24e6"), Color("1c3142"), 6))
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	for i in range(CATEGORIES.size()):
		var category: Dictionary = CATEGORIES[i]
		var button := Button.new()
		button.icon = _icon(i)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = Vector2(44, 44)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = str(category.name)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(toggle_category.bind(i))
		_style_button(button, false)
		row.add_child(button)
		category_buttons.append(button)
		var tray := HBoxContainer.new()
		tray.add_theme_constant_override("separation", 6)
		tray.visible = false
		tray_stack.add_child(tray)
		trays.append(tray)
		for kind in category.machines:
			if catalog.machines.has(kind):
				tiles[kind] = _tile(catalog, str(kind), tray)

func _tile(catalog: Dictionary, kind: String, tray: HBoxContainer) -> Button:
	var spec: Dictionary = catalog.machines[kind]
	var tile := Button.new()
	var art := AtlasTexture.new()
	art.atlas = load(SpriteMachineCard.art_path(kind))
	art.region = Rect2(0, 0, 128, 128)
	tile.icon = art
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.text = str(spec.name)
	tile.clip_text = true
	tile.custom_minimum_size = Vector2(104, 96)
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile.add_theme_font_size_override("font_size", 11)
	tile.add_theme_color_override("font_color", INK)
	tile.add_theme_color_override("font_disabled_color", MUTED)
	tile.add_theme_constant_override("icon_max_width", 64)
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.pressed.connect(func() -> void: machine_requested.emit(kind))
	_style_button(tile, false)
	tray.add_child(tile)
	return tile

func toggle_category(index: int) -> void:
	open_category(-1 if index == open_index else index)

func open_category(index: int) -> void:
	open_index = index
	for i in range(trays.size()):
		trays[i].visible = i == index
		_style_button(category_buttons[i], i == index)
	_tray_panel.visible = index >= 0

func refresh_locks(sim: RefCounted) -> void:
	for kind in tiles:
		var tile: Button = tiles[kind]
		var unlocked: bool = sim.is_machine_unlocked(str(kind))
		tile.disabled = not unlocked
		tile.modulate.a = 1.0 if unlocked else 0.45
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
		var name := str(sim.catalog.machines[kind].name)
		tile.tooltip_text = name if unlocked else "%s\nKilitli: %s" % [name, _unlock_tech.get(kind, "?")]

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode >= KEY_1 and key.keycode < KEY_1 + CATEGORIES.size():
		toggle_category(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and open_index >= 0:
		open_category(-1)
		get_viewport().set_input_as_handled()
