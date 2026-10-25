extends PanelContainer
## Inventory and crafting window, opened with I or C, laid out as a flow map.
## Left: every machine and product in the game. What you carry shows its count; what you do
## not have is dimmed, and a padlock marks what research has not opened yet. Clicking an
## item puts it in the middle of the map: its inputs on the left (have/need, red when
## short), the item card with recipe, time and the ÜRET button (shift: five), and what it
## goes into on the right, all joined by lines. Every card on the map selects its item.
## Products a machine makes, not the hand, name that machine instead. Double-clicking a
## carried machine places it.
## Below sit the craft queue (× cancels and refunds) and the quick-use bar's ten slots; drag
## an item onto a slot, right click it, or press 1-9, 0 while hovering it to pin it there.
## The window has a fixed size; the queue holds up to five different items. I, C, Esc or the
## × in the corner closes it.

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
	{"name": "Raw materials", "tab": "Raw", "machines": ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]},
	{"name": "Metallurgy", "tab": "Metallurgy", "machines": ["smelter"]},
	{"name": "Forming", "tab": "Forming", "machines": ["rolling_mill", "press", "foundry"]},
	{"name": "Machining", "tab": "Machining", "machines": ["machine_shop"]},
	{"name": "Assembly", "tab": "Assembly", "machines": ["machine_factory", "wire_winder", "mechanical_assembly", "electrical_assembly", "electronics_assembly", "robotics_assembly"]},
	{"name": "Research and goals", "tab": "Research", "machines": ["lab_1", "lab_2", "lab_3", "lab_4", "module_plant", "project_hub", "scrap_disposal"]},
	{"name": "Storage", "tab": "Storage", "machines": ["storage"]},
]
const CRAFT_ICON := 7
const COLUMNS := 5
const SIZE := Vector2(1120, 720)
## The item card keeps one height so the map does not jump between items.
const CENTER_HEIGHT := 360
const SLOT := 48
const USES_SHOWN := 6
const TEAL := Color("4f9a8a")
const CARD := Color("fbf8f2")
## Text on the dark header band and item list, taken from the band art's brass highlights.
const HEADER_INK := Color("d6c4ab")
## Window rim, nine-sliced with 9 px corners; the body texture and header sit inside it.
const WINDOW_FRAME := preload("res://app/art/ui/craft_window_frame.png")
## Flow map sheet, drawn for a 784 x 463 panel; nine-sliced to the panel's actual size.
const FLOW_BACKGROUND := preload("res://app/art/ui/craft_flow_bg.png")
## Crossed hammers shown left of the window title, at its 32 x 32 size.
const TITLE_ICON := preload("res://app/art/ui/craft_title_icon.png")
## Close button art (32 x 32): normal, hover (brighter brass) and pressed (dimmer brass).
const CLOSE_NORMAL := preload("res://app/art/ui/close_normal.png")
const CLOSE_HOVER := preload("res://app/art/ui/close_hover.png")
const CLOSE_PRESSED := preload("res://app/art/ui/close_pressed.png")
## Rim and dark fill of the inventory list, 36 x 36 art nine-sliced with 9 px corners.
const ITEMS_FRAME := preload("res://app/art/ui/craft_items_frame.png")
const TRAY_DIVIDER := Color("9b8d78")
## Scroll bar of the item trays: dark track, brass grabber.
const SCROLL_TRACK := Color("151b1f")
const SCROLL_GRABBER := Color("d4812c")
## Shown left of the Machines title, at its 24 x 24 size.
const MACHINES_ICON := preload("res://app/art/ui/machines_icon.png")
## Shown left of the Products title; scaled from its 25 x 26 art to sit in the same 24 x 24 box.
const PRODUCTS_ICON := preload("res://app/art/ui/products_icon.png")
## Shown left of the Quick Bar title; scaled from its 21 x 28 art to the other icons' 24 px height.
const QUICK_ICON := preload("res://app/art/ui/quick_icon.png")
## Input and "used in" cards on the flow map: 28 x 27 rounded bevel art, nine-sliced at 8 px.
const FLOW_CARD := preload("res://app/art/ui/flow_card_frame.png")
## The selected item's card on the flow map: 291 x 327 art, nine-sliced at 24 px.
const FLOW_CENTER := preload("res://app/art/ui/flow_center_frame.png")
## CRAFT button plates (35 x 40), nine-sliced at 10 px; disabled is a dimmed normal plate.
const CRAFT_PLATE := preload("res://app/art/ui/craft_button.png")
const CRAFT_PLATE_HOVER := preload("res://app/art/ui/craft_button_hover.png")
const CRAFT_PLATE_PRESSED := preload("res://app/art/ui/craft_button_pressed.png")
## PLACE button plates: the CRAFT plates recoloured from teal to amber, same shading.
const PLACE_PLATE := preload("res://app/art/ui/place_button.png")
const PLACE_PLATE_HOVER := preload("res://app/art/ui/place_button_hover.png")
const PLACE_PLATE_PRESSED := preload("res://app/art/ui/place_button_pressed.png")
## Recipe box: a dark title strip over a light body, both nine-sliced at 9 px.
const RECIPE_TOP := preload("res://app/art/ui/recipe_top.png")
const RECIPE_BOTTOM := preload("res://app/art/ui/recipe_bottom.png")
## Title tag over the flow map's columns ("Inputs", "Used in"): 25 x 24 art, nine-sliced at 8 px.
const FLOW_PILL := preload("res://app/art/ui/flow_pill.png")

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
var _recipe_panel: VBoxContainer
var _work: HBoxContainer
var _time: Label
var _reason: Label
var _flow: FlowMap
var _center: PanelContainer
var _inputs: VBoxContainer
var _uses: VBoxContainer
## First use card in view, and the item whose uses are listed.
var _uses_offset := 0
var _details_key := ""
var _uses_for := ""
var _uses_up: Button
var _uses_down: Button
var _uses_range: Label
var _machines_title: Label
var _products_title: Label
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

## Window frame and background: a light workshop panel with a heavier rim (rivets and the
## header band are drawn by WorkshopFrame).
func _frame() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = WINDOW_FRAME
	style.set_texture_margin_all(9)
	style.set_content_margin_all(6)
	style.content_margin_right = 5
	return style

## A label in the heading font (Pixelify Sans, set up in main's theme).
func _heading(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.theme_type_variation = "Heading"
	return label

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
	# Fixed size, so the window stays put whatever is selected or queued.
	var frame := WorkshopFrame.new()
	frame.custom_minimum_size = SIZE
	frame.add_theme_stylebox_override("panel", _frame())
	center.add_child(frame)
	# No right margin: the flow map runs up to the window rim; the header keeps its inset below.
	# No top margin either: the header fills the band art and centres its contents in it.
	# Left: 3 px plus the frame's 6 px content margin leaves 4 px between the rim and the trays.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3)
	# Bottom: 3 px plus the frame's 6 px content margin leaves 4 px between the quick bar and the rim.
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)  # between the trays above and the quick bar
	margin.add_child(box)
	# Header and the trays below it sit closer (4 px) than the rest of the window's rows.
	var top := VBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 4)
	box.add_child(top)
	var header := HBoxContainer.new()
	# Spans the band from just inside the frame's content margin down to its bottom edge.
	header.custom_minimum_size.y = WorkshopFrame.HEADER - 6
	top.add_child(header)
	# Keeps the title where it was before the trays moved up to the rim (14 px window margin).
	var lead := Control.new()
	lead.custom_minimum_size.x = 7  # plus the row's 4 px separation
	header.add_child(lead)
	var icon := TextureRect.new()
	icon.texture = TITLE_ICON
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(icon)
	var title := _heading("Inventory and Crafting", 20, HEADER_INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := TextureButton.new()
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.texture_normal = CLOSE_NORMAL
	close.texture_hover = CLOSE_HOVER
	close.texture_pressed = CLOSE_PRESSED
	close.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = "Close (Esc)"
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.pressed.connect(hide)
	header.add_child(close)
	var inset := Control.new()
	inset.custom_minimum_size.x = 7
	header.add_child(inset)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 4)
	top.add_child(middle)
	_build_items(middle)
	# The flow map with the crafting queue tray 2 px under it.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 2)
	middle.add_child(right)
	_build_flow(right)
	_build_queue(right)
	_build_quick(box)
	select(items.keys()[0])

## Machines in category order, then products by tier, each tier in catalog order; each list
## sits in its own framed tray and scrolls on its own.
func _build_items(middle: HBoxContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	middle.add_child(column)
	_machines_title = _heading("Machines", 14, HEADER_INK)
	var machines := _tray(column, _machines_title, MACHINES_ICON)
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
	_products_title = _heading("Products", 14, HEADER_INK)
	var products := _tray(column, _products_title, PRODUCTS_ICON)
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

## A framed tray: a fixed title (with an optional icon) and divider above a scrolling item grid; returns the grid.
func _tray(column: VBoxContainer, title: Label, icon: Texture2D = null) -> GridContainer:
	var box := _tray_box(column)
	box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Two trays, stacked edge to edge, share the height the single list used to have (440), less one frame.
	box.custom_minimum_size = Vector2(3 + COLUMNS * SLOT + (COLUMNS - 1) * 4 + 14, 211)
	_tray_heading(box, title, icon)
	# A divider under the title, inset so it stops short of the frame on both sides.
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 2)
	inset.add_theme_constant_override("margin_right", 2)
	box.add_child(inset)
	var divider := ColorRect.new()
	divider.color = TRAY_DIVIDER
	divider.custom_minimum_size.y = 2
	inset.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Content margins give the bar its width (6 px); hover and drag light the grabber up a little.
	var bar := scroll.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", _box(SCROLL_TRACK, Color.TRANSPARENT, 0, 3, 2))
	bar.add_theme_stylebox_override("scroll_focus", _box(SCROLL_TRACK, Color.TRANSPARENT, 0, 3, 2))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(state, _box(SCROLL_GRABBER.lightened(0.0 if state == "grabber" else 0.15), Color.TRANSPARENT, 0, 3, 2))
	box.add_child(scroll)
	# 3 px between the frame's inner edge and the first column of slots.
	var inset_left := MarginContainer.new()
	inset_left.add_theme_constant_override("margin_left", 3)
	scroll.add_child(inset_left)
	var grid := _grid()
	inset_left.add_child(grid)
	return grid

## The dark framed panel the item lists and the crafting queue sit in; returns its content box.
func _tray_box(parent: Container) -> VBoxContainer:
	var panel := PanelContainer.new()
	var frame := StyleBoxTexture.new()
	frame.texture = ITEMS_FRAME
	frame.set_texture_margin_all(9)
	frame.set_content_margin_all(9)
	panel.add_theme_stylebox_override("panel", frame)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	return box

## A tray's title row, padded so it sits as far from the frame's top and left as it does above the divider.
func _tray_heading(box: VBoxContainer, title: Label, icon: Texture2D) -> void:
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_left", 6)
	box.add_child(pad)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	pad.add_child(heading)
	if icon != null:
		var picture := TextureRect.new()
		picture.texture = icon
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heading.add_child(picture)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(title)

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	return grid

func _item(grid: GridContainer, key: String) -> void:
	var slot := InventorySlot.new(SLOT)
	if key.begins_with("machine:"):
		slot.locked_icon = icon_for(key.trim_prefix("machine:"))
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


## Flow map: inputs | item card | uses, with room between the columns for the links.
func _build_flow(right: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sheet := StyleBoxTexture.new()
	sheet.texture = FLOW_BACKGROUND
	# Nine-sliced so its metal rim stays crisp now that the panel is a little wider than the art.
	sheet.set_texture_margin_all(12)
	sheet.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sheet)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right.add_child(panel)
	_flow = FlowMap.new()
	_flow.alignment = BoxContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("separation", 40)
	panel.add_child(_flow)
	_inputs = _column(_flow, "Inputs")
	_center = PanelContainer.new()
	_center.custom_minimum_size = Vector2(300, CENTER_HEIGHT)
	_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_sheet := StyleBoxTexture.new()
	card_sheet.texture = FLOW_CENTER
	card_sheet.set_texture_margin_all(24)
	# The art's rim is about 12 px wide; contents keep the inset they had inside the old border.
	card_sheet.set_content_margin_all(14)
	_center.add_theme_stylebox_override("panel", card_sheet)
	_center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_center.item_rect_changed.connect(_flow.queue_redraw)
	_flow.add_child(_center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_center.add_child(box)
	var title_row := HBoxContainer.new()
	box.add_child(title_row)
	_title = _heading("", 20, INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(_title)
	_count = _label("", 13, AMBER)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_count)
	_picture = TextureRect.new()
	_picture.custom_minimum_size = Vector2(0, 64)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_picture)
	_description = _label("", 12, MUTED)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(272, 32)
	_description.max_lines_visible = 3
	box.add_child(_description)
	_recipe_panel = VBoxContainer.new()
	_recipe_panel.add_theme_constant_override("separation", 0)
	box.add_child(_recipe_panel)
	var recipe_title := PanelContainer.new()
	recipe_title.add_theme_stylebox_override("panel", _recipe_sheet(RECIPE_TOP))
	recipe_title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_recipe_panel.add_child(recipe_title)
	recipe_title.add_child(_label("Recipe", 12, HEADER_INK))
	var recipe_body := PanelContainer.new()
	recipe_body.add_theme_stylebox_override("panel", _recipe_sheet(RECIPE_BOTTOM))
	recipe_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_recipe_panel.add_child(recipe_body)
	var recipe_box := VBoxContainer.new()
	recipe_box.add_theme_constant_override("separation", 4)
	recipe_body.add_child(recipe_box)
	_recipe = HBoxContainer.new()
	_recipe.alignment = BoxContainer.ALIGNMENT_CENTER
	_recipe.add_theme_constant_override("separation", 4)
	recipe_box.add_child(_recipe)
	# Work the recipe needs: the craft hammer and a number, the same by hand or in a machine.
	_work = HBoxContainer.new()
	_work.alignment = BoxContainer.ALIGNMENT_CENTER
	_work.add_theme_constant_override("separation", 4)
	_work.mouse_filter = Control.MOUSE_FILTER_STOP
	recipe_box.add_child(_work)
	var hammer := TextureRect.new()
	hammer.texture = icon(CRAFT_ICON)
	hammer.custom_minimum_size = Vector2(24, 24)
	hammer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hammer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hammer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hammer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_work.add_child(hammer)
	_time = _label("", 14, INK)
	_time.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_work.add_child(_time)
	craft_button = _action_button("CRAFT", TEAL, Color("7bb8ab"), Color("67a99c"), Color("43867a"))
	craft_button.tooltip_text = "Click: 1 · Shift+click: 5"
	_plate_button(craft_button, CRAFT_PLATE, CRAFT_PLATE_HOVER, CRAFT_PLATE_PRESSED)
	craft_button.pressed.connect(func() -> void:
		var craft := _craft_target()
		if not craft.is_empty():
			craft_requested.emit(craft[0], craft[1], 5 if Input.is_key_pressed(KEY_SHIFT) else 1))
	# CRAFT and PLACE share a row; each fills it alone when the other is hidden.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	craft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(craft_button)
	place_button = _action_button("PLACE", AMBER, Color("d9a659"), Color("c99442"), Color("a3722a"))
	place_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plate_button(place_button, PLACE_PLATE, PLACE_PLATE_HOVER, PLACE_PLATE_PRESSED)
	place_button.pressed.connect(func() -> void: _place(selected))
	actions.add_child(place_button)
	_reason = _label("", 11, RED)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.max_lines_visible = 2
	box.add_child(_reason)
	_uses = _column(_flow, "Used in")
	var uses_column: VBoxContainer = _uses.get_parent()
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 2)
	_uses_up = _arrow_button("▲", -1)
	steps.add_child(_uses_up)
	_uses_down = _arrow_button("▼", 1)
	steps.add_child(_uses_down)
	_uses_range = _label("", 11, MUTED)
	_uses_range.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	steps.add_child(_uses_range)
	uses_column.add_child(steps)
	uses_column.gui_input.connect(func(event: InputEvent) -> void:
		var wheel := event as InputEventMouseButton
		if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_step_uses(-1 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			uses_column.accept_event())
	_flow.inputs = _inputs
	_flow.center = _center
	_flow.uses = _uses

## One side column of the flow map: a pill heading over a list of cards.
func _column(parent: Control, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 180
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tag := StyleBoxTexture.new()
	tag.texture = FLOW_PILL
	tag.set_texture_margin_all(8)
	tag.set_content_margin_all(4)
	pill.add_theme_stylebox_override("panel", tag)
	pill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pill_label := _heading(title, 13, Color("f6f2ea"))
	pill_label.add_theme_constant_override("line_spacing", 0)
	var pill_margin := MarginContainer.new()
	for side in ["left", "right"]:
		pill_margin.add_theme_constant_override("margin_" + side, 8)
	for side in ["top", "bottom"]:
		pill_margin.add_theme_constant_override("margin_" + side, 2)
	pill_margin.add_child(pill_label)
	pill.add_child(pill_margin)
	column.add_child(pill)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	column.add_child(list)
	return list

## A card on the flow map: picture, name and a second line; clicking selects the item.
func _card(key: String, line: String, line_color: Color) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(180, 50)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = _name(key)
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_theme_stylebox_override("normal", _flow_card(Color.WHITE))
	card.add_theme_stylebox_override("hover", _flow_card(Color(1.08, 1.08, 1.08)))
	card.add_theme_stylebox_override("pressed", _flow_card(Color(0.9, 0.9, 0.9)))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var picture := Icons.Slot.new(_picture_for(key), 1)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if key.begins_with("machine:") else CanvasItem.TEXTURE_FILTER_NEAREST
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_label := _label(_name(key), 12, INK)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	text.add_child(name_label)
	if not line.is_empty():
		text.add_child(_label(line, 11, line_color))
	card.pressed.connect(select.bind(key))
	card.item_rect_changed.connect(_flow.queue_redraw)
	return card

func _flow_card(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = FLOW_CARD
	style.set_texture_margin_all(8)
	style.modulate_color = tint
	return style

## Dresses an action button in its hand-drawn plates; disabled is the normal plate dimmed.
func _plate_button(button: Button, normal: Texture2D, hover: Texture2D, pressed: Texture2D) -> void:
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_stylebox_override("normal", _craft_plate(normal))
	button.add_theme_stylebox_override("hover", _craft_plate(hover))
	button.add_theme_stylebox_override("pressed", _craft_plate(pressed))
	button.add_theme_stylebox_override("disabled", _craft_plate(normal, Color(0.6, 0.6, 0.6, 0.7)))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, HEADER_INK)
	button.add_theme_color_override("font_disabled_color", Color(HEADER_INK, 0.45))

func _recipe_sheet(art: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = art
	style.set_texture_margin_all(9)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _craft_plate(plate: Texture2D, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = plate
	style.set_texture_margin_all(10)
	# Thin content margins so the label fits the button's 36 px height.
	style.set_content_margin_all(4)
	style.modulate_color = tint
	return style

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

func _build_queue(right: VBoxContainer) -> void:
	var box := _tray_box(right)
	_queue_title = _heading("", 14, HEADER_INK)
	_tray_heading(box, _queue_title, MACHINES_ICON)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 6)
	box.add_child(pad)
	_queue_row = HBoxContainer.new()
	_queue_row.add_theme_constant_override("separation", 6)
	_queue_row.custom_minimum_size.y = 52
	pad.add_child(_queue_row)

## The quick bar in a framed tray like the queue's: its title on the left, the ten slots after it.
func _build_quick(box: VBoxContainer) -> void:
	var tray := _tray_box(box)
	# 3 px between the slots and the frame's inner edge, above and below.
	var gap := MarginContainer.new()
	gap.add_theme_constant_override("margin_top", 3)
	gap.add_theme_constant_override("margin_bottom", 3)
	tray.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	gap.add_child(row)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 6)
	pad.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pad)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	pad.add_child(heading)
	var icon := TextureRect.new()
	icon.texture = QUICK_ICON
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(icon)
	var title := _heading("Quick Bar", 14, HEADER_INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(title)
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	row.add_child(quick)
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
	var owned := {"machine": 0, "product": 0}
	var total := {"machine": 0, "product": 0}
	for key in items:
		var kind := str(key).get_slice(":", 0)
		total[kind] += 1
		if sim.carried_count(str(key)) > 0:
			owned[kind] += 1
	_machines_title.text = "Machines  %d/%d" % [owned.machine, total.machine]
	_products_title.text = "Products  %d/%d" % [owned.product, total.product]
	for key in items:
		var slot: InventorySlot = items[key]
		slot.pinned = key in sim.hotbar
		slot.locked = not _is_open(str(key))
		slot.set_item(sim, str(key))
	for i in range(quick_slots.size()):
		quick_slots[i].set_item(sim, sim.hotbar[i])
	# Rebuilt only when what it shows changed: rebuilding every update would reset the hover
	# state of the card under the mouse, making it flicker.
	if _details_state() != _details_key:
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
		return "Locked: %s" % (_sim.catalog.researches[tech].name if _sim.catalog.researches.has(tech) else "?")
	if type == "machine" and _sim.build_limit(id) >= 0 and _sim.machine_total(id) >= _sim.build_limit(id):
		return "Limit reached: at most %d" % _sim.build_limit(id)
	if not _sim.queue_has_room(type, id):
		return "Queue full: at most %d different items" % _sim.CRAFT_QUEUE_KINDS
	if not _sim.can_craft(type, id):
		return "Missing materials"
	return ""


## Selected item in the middle of the map: picture, description, recipe with what you carry
## (red when short), time; its inputs on the left and what it goes into on the right.
## Everything the selected item's map depends on, to tell when it needs rebuilding.
func _details_state() -> String:
	return str([selected, _sim.inventory, _sim.machine_inventory, _sim.machines.size(), _sim.craft_queue_groups().size(),
		_sim.completed_researches.size(), _sim.unlocked_machines.size(), _sim.unlocked_recipes.size(), _sim.sandbox_mode])

func _show_details() -> void:
	_details_key = _details_state()
	for list in [_recipe, _inputs, _uses]:
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
	if selected.is_empty():
		return
	var parts := selected.split(":")
	var is_machine := parts[0] == "machine"
	var id := parts[1]
	_title.text = _name(selected)
	_count.text = "In inventory: %d" % _sim.carried_count(selected)
	_picture.texture = _picture_for(selected)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if is_machine else CanvasItem.TEXTURE_FILTER_NEAREST
	place_button.visible = is_machine and _sim.carried_count(selected) > 0
	place_button.disabled = is_machine and not _sim.can_place(id)
	var craft := _craft_target()
	var producers: Array = [] if is_machine else _producers(id)
	if is_machine:
		_description.text = str(_sim.catalog.machines[id].get("description", ""))
	elif producers.is_empty():
		_description.text = "No machine makes this."
	else:
		var makers: PackedStringArray = []
		for producer in producers:
			if not (producer.machine_name in makers):
				makers.append(producer.machine_name)
		_description.text = "Made in: %s" % ", ".join(makers)
	var recipe_id := ""
	var inputs: Dictionary = {}
	if is_machine:
		inputs = _sim.craft_inputs("machine", id)
	elif not producers.is_empty():
		recipe_id = str(producers[0].recipe)
		inputs = _sim.catalog.recipes[recipe_id].inputs
	_recipe_panel.visible = is_machine or not producers.is_empty()
	for product in inputs:
		var have := int(_sim.inventory.get(product, 0))
		var need := int(inputs[product])
		_inputs.add_child(_card("product:" + str(product), "%d / %d" % [have, need], RED if have < need else TEAL))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.tooltip_text = "%s: %d / %d" % [_sim.product_name(str(product)), have, need]
		var slot := Icons.Slot.new(Icons.product(_sim, str(product)), need)
		slot.short = have < need
		column.add_child(slot)
		_recipe.add_child(column)
	# Raw materials have no inputs: the machine that digs them stands in their place.
	if inputs.is_empty() and not producers.is_empty():
		_inputs.add_child(_card("machine:" + str(producers[0].kind), "Extracted by", MUTED))
	if _inputs.get_child_count() == 0:
		_inputs.add_child(_label("—", 12, MUTED))
	if inputs.is_empty() and not is_machine:
		var raw := _label("Raw material", 12, MUTED)
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
	# Every recipe needs the same amount of work wherever it is made; the hand and each machine
	# only differ in how much work they do per second.
	var work := 0.0
	if is_machine:
		work = _sim.craft_work("machine", id)
	elif not recipe_id.is_empty():
		work = _sim.craft_work("recipe", recipe_id)
	_time.text = str(int(work))
	_work.visible = work > 0.0
	_work.tooltip_text = "Work needed: %d\nHands do %d work/s; machines work at their own speed." % [int(work), int(_sim.hand_speed)]
	if _uses_for != selected:
		_uses_for = selected
		_uses_offset = 0
	_show_uses(id if not is_machine else "")
	craft_button.visible = not craft.is_empty()
	var blocker := _blocker(craft[0], craft[1]) if not craft.is_empty() else ""
	if craft.is_empty() and not producers.is_empty():
		blocker = "Can't be crafted by hand: made in a machine." if producers[0].unlocked else "Locked: %s" % _tech_name(str(producers[0].unlock_tech))
	craft_button.disabled = not blocker.is_empty()
	craft_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if craft_button.disabled else Control.CURSOR_POINTING_HAND
	_reason.text = blocker
	_flow.queue_redraw()

func _tech_name(tech: String) -> String:
	return str(_sim.catalog.researches[tech].name) if _sim.catalog.researches.has(tech) else "?"


## What takes `product`, as cards on the right of the map: products it goes into, then
## machines whose build cost needs it. Six fit; with more, the wheel or the arrows step the
## column one card at a time and the links follow the cards in view.
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
	for key in uses:
		_uses.add_child(_card(key, "Machine" if key.begins_with("machine:") else "", MUTED))
	if uses.is_empty():
		_uses.add_child(_label("Placed on the canvas." if product.is_empty() else "Not used anywhere.", 12, MUTED))
	_uses_offset = clampi(_uses_offset, 0, maxi(uses.size() - USES_SHOWN, 0))
	_show_uses_window()

## Shows the USES_SHOWN cards from _uses_offset on, and where the column stands.
func _show_uses_window() -> void:
	var count := _uses.get_child_count()
	for i in range(count):
		_uses.get_child(i).visible = i >= _uses_offset and i < _uses_offset + USES_SHOWN
	var scrolling := count > USES_SHOWN
	_uses_up.visible = scrolling
	_uses_down.visible = scrolling
	_uses_up.disabled = _uses_offset <= 0
	_uses_down.disabled = _uses_offset + USES_SHOWN >= count
	_uses_range.visible = scrolling
	_uses_range.text = "%d-%d / %d" % [_uses_offset + 1, mini(_uses_offset + USES_SHOWN, count), count]
	_flow.queue_redraw()

func _step_uses(step: int) -> void:
	var last := maxi(_uses.get_child_count() - USES_SHOWN, 0)
	var offset := clampi(_uses_offset + step, 0, last)
	if offset != _uses_offset:
		_uses_offset = offset
		_show_uses_window()

func _arrow_button(text: String, step: int) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(28, 20)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	# Brass like the item lists' scroll bars; lighter on hover, faded at the end of the list.
	button.add_theme_color_override("font_color", SCROLL_GRABBER)
	button.add_theme_color_override("font_hover_color", SCROLL_GRABBER.lightened(0.15))
	button.add_theme_color_override("font_pressed_color", SCROLL_GRABBER.darkened(0.15))
	button.add_theme_color_override("font_disabled_color", Color(SCROLL_GRABBER, 0.3))
	button.pressed.connect(_step_uses.bind(step))
	return button

func _refresh_queue(sim: RefCounted) -> void:
	var groups: Array = sim.craft_queue_groups()
	_queue_title.text = "Crafting Queue (%d/%d)" % [groups.size(), sim.CRAFT_QUEUE_KINDS]
	var keys: Array = []
	for group in groups:
		keys.append("%s:%s:%d" % [group.type, group.id, group.count])
	if keys != _queue_keys:
		_queue_keys = keys
		queue_slots.clear()
		for child in _queue_row.get_children():
			child.queue_free()
		for group in groups:
			_queue_row.add_child(_queue_card(sim, group))
		# Free places stay as dim outlines, so cards keep one width however many are queued
		# and an empty queue shows its five places.
		for i in range(sim.CRAFT_QUEUE_KINDS - groups.size()):
			var free := Panel.new()
			free.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			free.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.18), Color(TRAY_DIVIDER, 0.35), 1, 0, 4))
			_queue_row.add_child(free)
	# Each card: progress of the job it is on, and time until its last job is done.
	var waited := 0.0
	for i in range(mini(queue_slots.size(), groups.size())):
		var group: Dictionary = groups[i]
		for j in range(group.first, group.first + group.count):
			waited += float(sim.craft_queue[j].remaining)
		var job: Dictionary = sim.craft_queue[group.first]
		queue_slots[i].bar.value = 1.0 - float(job.remaining) / sim.craft_work(str(job.type), str(job.id))
		queue_slots[i].time.text = "%.1f s" % (waited / sim.hand_speed)

## One queued item: picture with how many are coming, progress, time and × (cancels one).
func _queue_card(sim: RefCounted, group: Dictionary) -> Control:
	var card := PanelContainer.new()
	# Cards share the tray's width, narrow enough for a full queue (CRAFT_QUEUE_KINDS) to fit.
	card.custom_minimum_size = Vector2(0, 50)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Same plate as the flow map's input and "used in" cards.
	var plate := _flow_card(Color.WHITE)
	plate.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", plate)
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var type := str(group.type)
	var id := str(group.id)
	var slot: Icons.Slot
	if type == "machine":
		slot = Icons.Slot.new(Icons.machine(SpriteMachineCard.art_path(id)), int(group.count))
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		slot.tooltip_text = str(sim.catalog.machines[id].name)
	else:
		var output := str(sim.catalog.recipes[id].outputs.keys()[0])
		slot = Icons.Slot.new(Icons.product(sim, output), int(sim.catalog.recipes[id].outputs[output]) * int(group.count))
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
	bar.custom_minimum_size = Vector2(40, 6)
	bar.add_theme_stylebox_override("background", _box(Color("e4ddd0"), Color.TRANSPARENT, 0, 0, 2))
	bar.add_theme_stylebox_override("fill", _box(SCROLL_GRABBER, Color.TRANSPARENT, 0, 0, 2))  # same brass as the item lists' scroll bars
	middle.add_child(bar)
	var time := _label("", 12, INK)
	middle.add_child(time)
	var cancel := Button.new()
	cancel.text = "×"
	cancel.flat = true
	cancel.tooltip_text = "Cancel one (materials are returned)"
	cancel.add_theme_font_size_override("font_size", 16)
	cancel.add_theme_color_override("font_color", MUTED)
	cancel.add_theme_color_override("font_hover_color", RED)
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var last := int(group.first) + int(group.count) - 1
	cancel.pressed.connect(func() -> void: craft_cancelled.emit(last))
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

## Lays out the map's three columns and draws the links: each input card to the item card,
## the item card to each use card.
class FlowMap extends HBoxContainer:
	## Links are 5 px wide: a 1 px core, then a 1 px blend (the average of core and edge), then a
	## 1 px edge on each side.
	const LINK := Color("399195")
	const LINK_BLEND := Color("3b6669")
	const LINK_EDGE := Color("3d3b3d")
	var inputs: Control
	var center: Control
	var uses: Control

	# Cards move whenever the columns re-sort; redrawing each frame keeps the links on them.
	func _process(_delta: float) -> void:
		if is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		if center == null:
			return
		var hub := center.get_rect()
		var links: Array = []
		for card in inputs.get_children():
			if card is Button and card.visible:
				var rect := _local(card)
				links.append(_route(Vector2(rect.end.x, rect.get_center().y), Vector2(hub.position.x, hub.get_center().y)))
		for card in uses.get_children():
			if card is Button and card.visible:
				var rect := _local(card)
				links.append(_route(Vector2(hub.end.x, hub.get_center().y), Vector2(rect.position.x, rect.get_center().y)))
		# Every link's edges first, then every core over them, so links that share a trunk
		# join cleanly instead of one link's edge cutting across another's core.
		for edge in [2.0, 1.0, 0.0]:
			for points in links:
				_link(points, edge)

	func _local(control: Control) -> Rect2:
		return Rect2(control.global_position - global_position, control.size)

	## Elbow route between two points, on whole pixels.
	func _route(from: Vector2, to: Vector2) -> Array[Vector2]:
		var a := from.floor()
		var b := to.floor()
		var mid := floorf((a.x + b.x) * 0.5)
		return [a, Vector2(mid, a.y), Vector2(mid, b.y), b]

	## One pass of a link as whole-pixel rectangles (crisp edges): edge 2 draws the 5 px
	## outline colour, edge 1 the 3 px blend, edge 0 the 1 px core.
	func _link(points: Array[Vector2], edge: float) -> void:
		var color: Color = [LINK, LINK_BLEND, LINK_EDGE][int(edge)]
		for i in range(points.size() - 1):
			var span := Rect2(points[i], Vector2.ZERO).expand(points[i + 1])
			draw_rect(Rect2(span.position - Vector2.ONE * edge, span.size + Vector2.ONE * (1.0 + 2.0 * edge)), color)
		# A small square where the link meets its card.
		var end: Vector2 = points[-1]
		draw_rect(Rect2(end - Vector2.ONE * (1.0 + edge), Vector2.ONE * (3.0 + 2.0 * edge)), color)

## The window's sheet: the body texture with a header band under the title.
class WorkshopFrame extends PanelContainer:
	const HEADER := 50.0
	## Width of the rim drawn by the frame style box around the body.
	const RIM := 5.0
	## Hand-made texture for the body, drawn at exactly its size (1114 x 714).
	const BODY_TEXTURE := preload("res://app/art/ui/craft_body_bg.png")
	## Header band art (24 x 28), nine-sliced with 5 px corners across the top of the body.
	const HEADER_TEXTURE := preload("res://app/art/ui/craft_header_bg.png")
	var _header_style: StyleBoxTexture

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_header_style = StyleBoxTexture.new()
		_header_style.texture = HEADER_TEXTURE
		_header_style.set_texture_margin_all(5)

	func _draw() -> void:
		var body := Rect2(RIM, RIM, size.x - 2 * RIM, size.y - 2 * RIM)
		draw_texture_rect_region(BODY_TEXTURE, body, Rect2(Vector2.ZERO, body.size))
		draw_style_box(_header_style, Rect2(RIM, RIM, size.x - 2 * RIM, HEADER - RIM))
