extends PanelContainer
## Technology tree: flows left to right by prerequisite depth, one horizontal lane per
## category (research "category" in prototype.json). Researches of a lane at the same depth
## stack in rows, so a lane is as tall as its busiest column. The tree scrolls both ways.
## Click an available node to research it.

signal research_selected(tech_id: String)
signal unlock_all_requested()
signal close_requested()

const INK := Color("dce9ef")
const MUTED := Color("8ca5b6")
const TEAL := Color("61d8bb")
const GOLD := Color("efb65a")
## Lane order, title and accent colour.
const CATEGORIES := [
	{"id": "metalurji", "name": "Demir ve hidrolik", "color": Color("c87d55")},
	{"id": "mekanik", "name": "Çelik ve mekanik", "color": Color("efb65a")},
	{"id": "elektrik", "name": "Bakır ve elektrik", "color": Color("f0a35e")},
	{"id": "elektronik", "name": "Kuvars ve elektronik", "color": Color("52b5d8")},
	{"id": "otomasyon", "name": "Otomasyon ve final", "color": Color("b98eff")},
	{"id": "altyapi", "name": "Altyapı ve laboratuvar", "color": Color("61d8bb")},
	{"id": "maden", "name": "Maden genişletme", "color": Color("a8d5e5")},
	{"id": "verim", "name": "Verim", "color": Color("ff9f6e")},
	{"id": "kapasite", "name": "Kapasite", "color": Color("8c9ba5")},
]
const LANE_W := 140.0
const COL_W := 226.0
const ROW_H := 84.0
const LANE_PAD := 10.0
const NODE := Vector2(200, 72)
## Visible part of the tree; the rest scrolls.
const VIEW := Vector2(1300, 660)

## Draws lane bands and step connectors behind the research nodes.
class TreeCanvas extends Control:
	## {color, top, height} per lane
	var lanes: Array = []
	var edges: Array = []

	func _draw() -> void:
		for i in range(lanes.size()):
			var band := Rect2(0, lanes[i].top, size.x, lanes[i].height)
			draw_rect(band, Color("12222e") if i % 2 == 0 else Color("0f1d28"))
			draw_rect(Rect2(0, lanes[i].top, 4, lanes[i].height), lanes[i].color)
		for edge in edges:
			var a: Vector2 = edge.from
			var b: Vector2 = edge.to
			var mid: float = edge.bend_x
			draw_polyline(PackedVector2Array([a, Vector2(mid, a.y), Vector2(mid, b.y), b]), edge.color, 2.0)

var cards: Dictionary = {}
var status_label: Label
var unlock_all_button: Button
var tree: TreeCanvas
## tier -> chip showing points waiting in the store
var store_chips: Dictionary = {}
var _edges: Array = []

func _box(background: Color, border: Color, width: int = 1, radius: int = 8, pad: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _depth(catalog: Dictionary, tech_id: String) -> int:
	var depth := 0
	for prereq in catalog.researches[tech_id].get("prerequisites", []):
		depth = maxi(depth, _depth(catalog, str(prereq)) + 1)
	return depth

func build(catalog: Dictionary) -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _box(Color(0.02, 0.05, 0.08, 0.72), Color.TRANSPARENT, 0, 0))
	var center := CenterContainer.new()
	add_child(center)
	var dialog := PanelContainer.new()
	var dialog_style := _box(Color("0f1d28"), Color("30495b"), 2, 10)
	dialog_style.set_content_margin_all(18)
	dialog.add_theme_stylebox_override("panel", dialog_style)
	center.add_child(dialog)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_label("Teknoloji ağacı", 20, INK))
	status_label = _label("", 13, MUTED)
	title_box.add_child(status_label)
	# Point store: what the labs have produced and no research has spent yet.
	var store := HBoxContainer.new()
	store.add_theme_constant_override("separation", 12)
	store.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(store)
	for t in catalog.get("research_tiers", []):
		var chip := _chip(catalog, str(t.id), 0)
		chip.get_node("Amount").add_theme_font_size_override("font_size", 15)
		chip.get_child(0).custom_minimum_size = Vector2(12, 12)
		chip.tooltip_text = "%s puan deposu" % t.name
		store.add_child(chip)
		store_chips[str(t.id)] = chip
	unlock_all_button = Button.new()
	unlock_all_button.custom_minimum_size.y = 34
	unlock_all_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	unlock_all_button.pressed.connect(func() -> void: unlock_all_requested.emit())
	header.add_child(unlock_all_button)
	var close_btn := Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(84, 34)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_btn)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = VIEW
	vbox.add_child(scroll)
	tree = TreeCanvas.new()
	scroll.add_child(tree)
	var lane_of := {}
	for i in range(CATEGORIES.size()):
		lane_of[CATEGORIES[i].id] = i
	# Place each research: lane by category, column by depth, row by order within the cell.
	var cell_rows := {}
	var lane_rows: Array = []
	lane_rows.resize(CATEGORIES.size())
	lane_rows.fill(1)
	var place := {}
	var max_depth := 0
	for tech_id in catalog.researches:
		var depth := _depth(catalog, str(tech_id))
		max_depth = maxi(max_depth, depth)
		var lane: int = lane_of.get(str(catalog.researches[tech_id].get("category", "")), CATEGORIES.size() - 1)
		var cell := "%d:%d" % [lane, depth]
		var row: int = cell_rows.get(cell, 0)
		cell_rows[cell] = row + 1
		lane_rows[lane] = maxi(lane_rows[lane], row + 1)
		place[str(tech_id)] = [lane, depth, row]
	var top := 0.0
	for i in range(CATEGORIES.size()):
		var height: float = lane_rows[i] * ROW_H + LANE_PAD * 2.0
		tree.lanes.append({"color": CATEGORIES[i].color, "top": top, "height": height})
		var lane_title := _label(str(CATEGORIES[i].name), 13, CATEGORIES[i].color)
		lane_title.position = Vector2(14, top + 10)
		lane_title.size = Vector2(LANE_W - 22, 40)
		lane_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tree.add_child(lane_title)
		top += height
	for tech_id in place:
		var at: Array = place[tech_id]
		var pos := Vector2(LANE_W + at[1] * COL_W, tree.lanes[at[0]].top + LANE_PAD + at[2] * ROW_H + (ROW_H - NODE.y) * 0.5)
		cards[tech_id] = _node(catalog, tech_id, pos)
	tree.custom_minimum_size = Vector2(LANE_W + (max_depth + 1) * COL_W - (COL_W - NODE.x) + 40, top)
	for tech_id in catalog.researches:
		for prereq in catalog.researches[tech_id].get("prerequisites", []):
			_edges.append({"from_id": str(prereq), "to_id": str(tech_id)})

func _node(catalog: Dictionary, tech_id: String, pos: Vector2) -> Dictionary:
	var spec: Dictionary = catalog.researches[tech_id]
	var button := Button.new()
	button.position = pos
	button.size = NODE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: research_selected.emit(tech_id))
	tree.add_child(button)
	var box := VBoxContainer.new()
	box.position = Vector2(10, 8)
	box.size = NODE - Vector2(20, 16)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var name := str(spec.name)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var name_lbl := _label(name.get_slice(": ", 1) if ": " in name else name, 13, INK)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	head.add_child(name_lbl)
	head.add_child(_label(tech_id, 11, MUTED))
	# What it unlocks, in machine names; recipes only as a count.
	var machines: PackedStringArray = []
	for kind in spec.get("unlock_machines", []):
		machines.append(str(catalog.machines[kind].name))
	var recipes: int = spec.get("unlock_recipes", []).size()
	if recipes > 0:
		machines.append("+%d reçete" % recipes)
	var unlocks := " · ".join(machines)
	# Upgrades (more mines, speed, capacity) open nothing; show what they do instead.
	if unlocks.is_empty():
		unlocks = str(spec.get("description", ""))
	var unlock_lbl := _label(unlocks, 12, MUTED)
	unlock_lbl.clip_text = true
	box.add_child(unlock_lbl)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _box(Color("09131c"), Color.TRANSPARENT, 0, 3, 0))
	row.add_child(bar)
	# Price as tier chips: a coloured square and the points still missing.
	var chips := {}
	for tier in spec.cost:
		var chip := _chip(catalog, str(tier), int(spec.cost[tier]))
		row.add_child(chip)
		chips[str(tier)] = chip
	button.tooltip_text = "%s\n%s" % [name, str(spec.get("description", ""))]
	return {"button": button, "name_lbl": name_lbl, "bar": bar, "chips": chips, "cost": spec.cost}

## Coloured square for a research tier followed by a number.
func _chip(catalog: Dictionary, tier: String, amount: int) -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(8, 8)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in catalog.get("research_tiers", []):
		if str(t.id) == tier:
			swatch.color = Color(t.color)
			chip.tooltip_text = str(t.name)
	chip.add_child(swatch)
	var label := _label(str(amount), 11, INK)
	label.name = "Amount"
	chip.add_child(label)
	return chip

func _style(view: Dictionary, background: Color, border: Color, width: int) -> void:
	var button: Button = view.button
	for state in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, _box(background, border, width))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.06), TEAL if not button.disabled else border, width))
	button.add_theme_stylebox_override("pressed", _box(background.lightened(0.1), TEAL, width))
	view.bar.add_theme_stylebox_override("fill", _box(border, Color.TRANSPARENT, 0, 3, 0))

func refresh(sim: RefCounted) -> void:
	if not visible:
		return
	status_label.text = "%d / %d tamamlandı  ·  Aktif: %s" % [sim.completed_researches.size(), sim.catalog.researches.size(),
		sim.active_research if sim.can_research(sim.active_research) else "seçilmedi"]
	for tier in store_chips:
		store_chips[tier].get_node("Amount").text = str(int(sim.research_points.get(tier, 0)))
	unlock_all_button.text = "Serbest mod açık" if sim.sandbox_mode else "Serbest mod"
	unlock_all_button.disabled = sim.sandbox_mode
	for tech_id in cards:
		var view: Dictionary = cards[tech_id]
		view.bar.value = sim.research_fraction(tech_id)
		for tier in view.chips:
			var missing := int(view.cost[tier]) - int(sim.research_progress[tech_id].get(tier, 0))
			view.chips[tier].get_node("Amount").text = str(maxi(missing, 0))
		var button: Button = view.button
		if tech_id in sim.completed_researches:
			button.disabled = true
			view.name_lbl.add_theme_color_override("font_color", TEAL)
			_style(view, Color("16302f"), TEAL, 1)
		elif sim.active_research == tech_id:
			button.disabled = true
			view.name_lbl.add_theme_color_override("font_color", GOLD)
			_style(view, Color("2a2a1f"), GOLD, 2)
		elif sim.can_research(tech_id):
			button.disabled = false
			view.name_lbl.add_theme_color_override("font_color", INK)
			_style(view, Color("162938"), Color("3d6178"), 1)
		else:
			button.disabled = true
			view.name_lbl.add_theme_color_override("font_color", MUTED)
			_style(view, Color("101c26"), Color("22394a"), 1)
		# Locked cards stay opaque so the connectors behind them do not show through.
		button.self_modulate.a = 1.0
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	tree.edges.clear()
	# Each line leaving the same column bends on its own track so lines never merge.
	var tracks := {}
	for edge in _edges:
		var from: Button = cards[edge.from_id].button
		var to: Button = cards[edge.to_id].button
		var track: int = tracks.get(from.position.x, 0)
		tracks[from.position.x] = track + 1
		tree.edges.append({
			"from": from.position + Vector2(NODE.x, NODE.y * 0.5),
			"to": to.position + Vector2(0, NODE.y * 0.5),
			"bend_x": from.position.x + NODE.x + 6.0 + (track % 4) * 3.0,
			"color": Color(TEAL, 0.55) if edge.from_id in sim.completed_researches else Color("3d6178", 0.35),
		})
	tree.queue_redraw()
