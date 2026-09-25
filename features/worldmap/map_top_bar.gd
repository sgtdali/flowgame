class_name MapTopBar
extends PanelContainer

## Haritanın üst çubuğu: para, net gelir (renkli), sonraki hedef, o an gereken
## ipucu, oyun saati, hız düğmeleri ve kontrolleri anlatan "?" (görev 06, adım 5).
## Yalnızca gösterir; sayıları MapFlowSim'den okur.

const POSITIVE_COLOR: Color = Color(0.55, 0.9, 0.45)
const NEGATIVE_COLOR: Color = Color(0.95, 0.4, 0.35)
const ZERO_COLOR: Color = Color(0.7, 0.72, 0.7)
const GOAL_READY_COLOR: Color = Color(0.55, 0.9, 0.45)
const GOAL_WAIT_COLOR: Color = Color(0.8, 0.82, 0.8)
const CLOCK_EPSILON: float = 0.001
## Reddedilen işlemin nedeni bu kadar süre kırmızı görünür (gerçek saniye; görev 07, K3).
const ERROR_SECONDS: float = 3.0
const ERROR_COLOR: Color = Color(1.0, 0.45, 0.4)
const HINT_COLOR: Color = Color(0.75, 0.9, 1.0)
const HELP_TEXT: String = """Click a region or point to select it.
Hover over a point or route to see a summary.
Right/middle drag: pan the map.  Wheel: zoom.
In a factory: drag machines from the left, connect outputs to inputs,
Delete removes, right-click a wire end to disconnect, Esc goes back."""

@onready var money_label: Label = %MoneyLabel
@onready var income_label: Label = %IncomeLabel
@onready var goal_label: Label = %GoalLabel
@onready var hint_label: Label = %HintLabel
@onready var clock_label: Label = %ClockLabel
@onready var help_button: Button = %HelpButton

## Kalıcı ipucu (hata süresi bitince geri gelir) ve kalan hata süresi.
var _hint: String = ""
var _error_left: float = 0.0


func _ready() -> void:
	help_button.tooltip_text = HELP_TEXT
	clock_label.tooltip_text = "Game time (minutes:seconds)"
	hint_label.text = ""


func refresh(sim: MapFlowSim) -> void:
	var regions: RegionState = sim.regions
	money_label.text = "Money: %s" % RegionInfoPanel.format_money(regions.money)

	var income: float = sim.income_last_minute()
	var upkeep: int = sim.upkeep_per_minute()
	var net: float = snappedf(income - upkeep, 0.1)
	income_label.text = "%s%s/min" % ["+" if net >= 0.0 else "", RouteView.format_rate(net)]
	income_label.add_theme_color_override(&"font_color",
			POSITIVE_COLOR if net > 0.0 else (NEGATIVE_COLOR if net < 0.0 else ZERO_COLOR))
	income_label.tooltip_text = "Net per minute\nIncome: +%s/min\nUpkeep: -%d/min" % [
			RouteView.format_rate(income), upkeep]

	var locked_left: bool = false
	for region: RegionData in RegionCatalog.all():
		if not regions.is_unlocked(region.id):
			locked_left = true
			break
	goal_label.visible = locked_left
	if locked_left:
		var cost: int = regions.unlock_cost()
		goal_label.text = "Next region: %s" % RegionInfoPanel.format_money(cost)
		goal_label.add_theme_color_override(&"font_color",
				GOAL_READY_COLOR if regions.wallet.can_afford(cost) else GOAL_WAIT_COLOR)
		goal_label.tooltip_text = "Price of the next region you can unlock"

	# Küçük pay: kayan nokta toplamı 2:05'i 2:04 göstermesin.
	var seconds: int = floori(sim.clock * 60.0 + CLOCK_EPSILON)
	clock_label.text = "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


## O an gereken ipucu (ör. hat kurarken); boşsa ortası boş kalır.
func show_hint(text: String) -> void:
	_hint = text
	if _error_left <= 0.0:
		_show(text, HINT_COLOR)


## Bir işlemin neden yapılamadığını birkaç saniye kırmızı gösterir, sonra ipucuna döner.
func show_error(text: String) -> void:
	_error_left = ERROR_SECONDS
	_show(text, ERROR_COLOR)


func _process(delta: float) -> void:
	if _error_left > 0.0:
		_error_left -= delta
		if _error_left <= 0.0:
			_show(_hint, HINT_COLOR)


func _show(text: String, color: Color) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override(&"font_color", color)
