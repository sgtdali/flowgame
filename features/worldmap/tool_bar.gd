class_name ToolBar
extends PanelContainer

## Haritanın alt ortasındaki araç çubuğu: Route [1], Factory [2], Unlock [3].
## Yalnızca düğmeler: basılınca aleti ister, seçili aleti MapTools'tan alıp
## gösterir. Seçili düğme basılı görünür.

signal tool_pressed(tool: MapTools.Tool)

const BUTTON_SIZE: Vector2 = Vector2(150.0, 48.0)
const FONT_SIZE: int = 17
const BOTTOM_MARGIN: float = 14.0
## [alet, yazı, açıklama]
const TOOLS: Array = [
	[MapTools.Tool.ROUTE, "Route  [1]", "Connect two points with a route. Goods travel along routes."],
	[MapTools.Tool.FACTORY, "Factory  [2]", "Build a factory on an empty plot, then open it to place machines."],
	[MapTools.Tool.UNLOCK, "Unlock  [3]", "Buy access to a region next to one you already have."],
]

var _buttons: Dictionary = {}  # MapTools.Tool -> Button


func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	margin.add_child(row)
	for entry: Array in TOOLS:
		var tool: MapTools.Tool = entry[0]
		var button: Button = Button.new()
		button.text = entry[1]
		button.tooltip_text = entry[2]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = BUTTON_SIZE
		button.add_theme_font_size_override(&"font_size", FONT_SIZE)
		button.pressed.connect(func() -> void: tool_pressed.emit(tool))
		row.add_child(button)
		_buttons[tool] = button
	resized.connect(_place)
	get_viewport().size_changed.connect(_place)
	_place.call_deferred()


## Seçili aleti gösterir (sinyal üretmez).
func show_tool(tool: MapTools.Tool) -> void:
	for key: MapTools.Tool in _buttons:
		(_buttons[key] as Button).set_pressed_no_signal(key == tool)


## Ekranın alt ortasına yerleşir.
func _place() -> void:
	var screen: Vector2 = get_viewport_rect().size
	position = Vector2((screen.x - size.x) * 0.5, screen.y - size.y - BOTTOM_MARGIN)
