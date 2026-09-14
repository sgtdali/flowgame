class_name ResearchPanel
extends PanelContainer

## Araştırma ağacı — sağ tarafta DOCKED bir panel (D28). Tam ekran modal
## DEĞİL: `RightSplit` içinde Canvas'ın yanında yaşar, `visible` ile
## açılıp kapanır (sağ alttaki yüzen düğme ve tuvale tıklama — bkz.
## GameController). Gizliyken HSplitContainer onu dışlar, sütun tekrar
## tam genişlikte tuvale döner.
##
## MİMARİ: Hiçbir şeyi açmaz. "Şunu almak istiyorum" diye YUKARI sinyal
## gönderir; parayı düşme ve kilidi açma işini GameController yapar.

signal unlock_requested(node_id: StringName)
signal locate_requested(item_id: StringName)
signal close_requested

@onready var _list: VBoxContainer = %List
@onready var _balance_label: Label = %BalanceLabel


func _ready() -> void:
	%CloseButton.pressed.connect(close_requested.emit)
	visible = false


## Editörün çağırdığı komut: ağacı bu duruma göre yeniden çiz.
## `tracker`: Ar-Ge Sarayı'na akan ürünlerin hızını ölçen paylaşılan ölçer —
## sahibi GameController, her karede örneklenir (bkz. o dosyadaki not).
func refresh(
	progression: ProgressionState, gross_revenue: int, research_counts: Dictionary,
	tracker: ResearchDeliveryTracker = null
) -> void:
	_balance_label.text = "Treasury  %s gold" % [
		GameConfig.format_money(progression.balance(gross_revenue))
	]

	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	for node: ResearchNode in ResearchCatalog.all():
		var status: ProgressionState.Status = progression.status_of(node, gross_revenue, research_counts)
		_list.add_child(_build_row(node, status, progression, research_counts, tracker))


func _build_row(
	node: ResearchNode,
	status: ProgressionState.Status,
	progression: ProgressionState,
	research_counts: Dictionary,
	tracker: ResearchDeliveryTracker
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

	if status == ProgressionState.Status.PENDING and node.is_item_cost() and tracker != null:
		text_box.add_child(_build_tracker_block(node, research_counts, tracker))

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


## Aktif (PENDING, ürün-maliyetli) bir araştırmanın canlı takip bloğu:
## her eksik ürün için teslim edilen/gereken, laboratuvara ulaşan gerçek
## hız, ve o ürünü bitirmeye kaç dakika kaldığı. Tamamlanmış girdiler
## darboğaz hesabına HİÇ girmez (bkz. `remaining <= 0` erken çıkışı).
##
## Araştırmanın TOPLAM kalan süresi ürün sürelerinin TOPLAMI değil, en uzun
## kalan teslimat süresidir — ürünler PARALEL akar, araştırma hepsi
## tamamlanınca biter, art arda değil.
func _build_tracker_block(
	node: ResearchNode, research_counts: Dictionary, tracker: ResearchDeliveryTracker
) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)

	var pending: Array[RecipeSlot] = []
	for slot: RecipeSlot in node.cost_items:
		var delivered: int = int(research_counts.get(slot.item.id, 0))
		if delivered < slot.count:
			pending.append(slot)
		box.add_child(_build_tracker_row(slot, delivered, tracker))

	if pending.size() > 1:
		var bottleneck: RecipeSlot = null
		var worst_eta: float = -1.0
		for slot: RecipeSlot in pending:
			var remaining: int = slot.count - int(research_counts.get(slot.item.id, 0))
			var eta: float = tracker.eta_minutes(slot.item.id, remaining)
			if eta < 0.0:
				bottleneck = null
				break  # bir urunun ETA'si guvenilmezse toplam icin de guvenilmez
			if eta > worst_eta:
				worst_eta = eta
				bottleneck = slot
		var summary := Label.new()
		summary.add_theme_font_size_override(&"font_size", 10)
		summary.add_theme_color_override(&"font_color", Color(0.85, 0.60, 0.46))
		summary.text = (
			"Slowest: %s (~%s)" % [bottleneck.item.display_name, _format_minutes(worst_eta)]
			if bottleneck != null else "Slowest good: measuring…"
		)
		box.add_child(summary)

	return box


func _build_tracker_row(
	slot: RecipeSlot, delivered: int, tracker: ResearchDeliveryTracker
) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)

	var name_label := Label.new()
	name_label.add_theme_font_size_override(&"font_size", 10)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var done: bool = delivered >= slot.count
	if done:
		name_label.text = "✓ %s" % slot.item.display_name
		name_label.add_theme_color_override(&"font_color", Color(0.69, 0.75, 0.54))
	else:
		name_label.text = "%s  %d / %d" % [slot.item.display_name, delivered, slot.count]
		name_label.add_theme_color_override(&"font_color", Color(0.80, 0.70, 0.55))
	row.add_child(name_label)

	if not done:
		var rate_label := Label.new()
		rate_label.add_theme_font_size_override(&"font_size", 10)
		rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rate_label.custom_minimum_size = Vector2(150.0, 0.0)
		rate_label.text = _rate_and_eta_text(slot, delivered, tracker)
		rate_label.add_theme_color_override(&"font_color", Color(0.75, 0.71, 0.60))
		row.add_child(rate_label)

		var locate := Button.new()
		locate.text = "Locate"
		locate.add_theme_font_size_override(&"font_size", 10)
		locate.pressed.connect(locate_requested.emit.bind(slot.item.id))
		row.add_child(locate)

	return row


## "+3.1/dk  ~5.8 dk left" / "measuring…" / "flow is variable" / "no delivery"
func _rate_and_eta_text(slot: RecipeSlot, delivered: int, tracker: ResearchDeliveryTracker) -> String:
	var item_id: StringName = slot.item.id
	var remaining: int = slot.count - delivered
	match tracker.status(item_id):
		ResearchDeliveryTracker.Status.MEASURING:
			return "measuring…"
		ResearchDeliveryTracker.Status.STOPPED:
			return "no delivery"
		ResearchDeliveryTracker.Status.VARIABLE:
			return "%.1f/min · flow variable" % tracker.per_minute(item_id)
		_:
			var eta: float = tracker.eta_minutes(item_id, remaining)
			return "%.1f/min · ~%s left" % [tracker.per_minute(item_id), _format_minutes(eta)]


func _format_minutes(minutes: float) -> String:
	if minutes < 1.0:
		return "%ds" % roundi(minutes * 60.0)
	return "%.1fmin" % minutes


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
