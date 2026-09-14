class_name ResearchPanel
extends Control

## Araştırma ağacı ekranı. Üst bardaki düğmeyle açılır.
##
## MİMARİ: Hiçbir şeyi açmaz. "Şunu almak istiyorum" diye YUKARI sinyal
## gönderir; parayı düşme ve kilidi açma işini GameController yapar.

signal unlock_requested(node_id: StringName)
signal close_requested

@onready var _list: VBoxContainer = %List
@onready var _balance_label: Label = %BalanceLabel


func _ready() -> void:
	%CloseButton.pressed.connect(close_requested.emit)
	visible = false


## Editörün çağırdığı komut: ağacı bu duruma göre yeniden çiz.
func refresh(progression: ProgressionState, gross_revenue: int, research_counts: Dictionary) -> void:
	_balance_label.text = "Treasury  %s gold" % [
		GameConfig.format_money(progression.balance(gross_revenue))
	]

	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	for node: ResearchNode in ResearchCatalog.all():
		var status: ProgressionState.Status = progression.status_of(node, gross_revenue, research_counts)
		_list.add_child(_build_row(node, status, progression, research_counts))


func _build_row(
	node: ResearchNode,
	status: ProgressionState.Status,
	progression: ProgressionState,
	research_counts: Dictionary
) -> Control:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.27, 0.20, 0.13)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	style.border_color = _status_color(status)
	style.border_width_left = 3
	frame.add_theme_stylebox_override(&"panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	frame.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override(&"separation", 2)
	row.add_child(text_box)

	var title := Label.new()
	title.text = node.display_name
	title.add_theme_font_size_override(&"font_size", 14)
	title.add_theme_color_override(&"font_color",
		Color(0.55, 0.46, 0.35) if status == ProgressionState.Status.LOCKED
		else Color(0.96, 0.87, 0.68))
	text_box.add_child(title)

	var desc := Label.new()
	desc.text = node.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override(&"font_size", 11)
	desc.add_theme_color_override(&"font_color", Color(0.76, 0.66, 0.51))
	text_box.add_child(desc)

	text_box.add_child(_build_reward_line(node))

	var action := VBoxContainer.new()
	action.custom_minimum_size = Vector2(148.0, 0.0)
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override(&"separation", 4)
	row.add_child(action)

	var cost := Label.new()
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override(&"font_size", 12)
	if node.is_item_cost():
		var progress: Array = progression.item_progress(node, research_counts)
		cost.text = "%s\n%d / %d" % [_item_cost_text(node), progress[0], progress[1]]
		cost.add_theme_color_override(&"font_color", Color(0.69, 0.75, 0.54))
	else:
		cost.text = "%s gold" % GameConfig.format_money(node.cost_money)
		cost.add_theme_color_override(&"font_color", Color(0.90, 0.72, 0.39))
	action.add_child(cost)

	if status == ProgressionState.Status.UNLOCKED:
		var done := Label.new()
		done.text = "DISCOVERED"
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done.add_theme_font_size_override(&"font_size", 11)
		done.add_theme_color_override(&"font_color", Color(0.90, 0.72, 0.39))
		action.add_child(done)
	else:
		var button := Button.new()
		button.text = "Discover"
		button.disabled = status != ProgressionState.Status.AFFORDABLE
		button.tooltip_text = progression.unlock_problem(node, 0, research_counts)
		button.pressed.connect(unlock_requested.emit.bind(node.id))
		action.add_child(button)

	return frame


## Araştırmanın ne kazandırdığı: açtığı istasyonlar ve slot artışı.
func _build_reward_line(node: ResearchNode) -> Label:
	var parts: PackedStringArray = PackedStringArray()
	for block: BlockType in node.unlocks_blocks:
		parts.append(block.display_name)

	var label := Label.new()
	label.text = "→  " + ("  ·  ".join(parts) if not parts.is_empty() else "—")
	label.add_theme_font_size_override(&"font_size", 11)
	label.add_theme_color_override(&"font_color", Color(0.78, 0.69, 0.48))
	return label


static func _item_cost_text(node: ResearchNode) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for slot: RecipeSlot in node.cost_items:
		parts.append("%d × %s" % [slot.count, slot.item.display_name])
	return " + ".join(parts)


static func _status_color(status: ProgressionState.Status) -> Color:
	match status:
		ProgressionState.Status.UNLOCKED: return Color(0.90, 0.72, 0.39)
		ProgressionState.Status.AFFORDABLE: return Color(0.69, 0.75, 0.54)
		ProgressionState.Status.PENDING: return Color(0.79, 0.55, 0.29)
	return Color(0.43, 0.36, 0.28)
