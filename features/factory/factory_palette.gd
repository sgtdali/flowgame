class_name FactoryPalette
extends PanelContainer

## Fabrika editörünün sol paneli: yerleştirilebilir bloklar.
##
## Eski oyunun BlockPalette'i kendi kataloğunu (Iron & Ember blokları) okuduğu
## için burada ayrı, küçük bir palet var; satırlar aynı PaletteItem'dır, yani
## tıklama ve tuvale sürükleyip bırakma aynen çalışır. Listeyi MapConfig verir:
## makineler + her mal için bir "Output: <mal>" kapısı. Bloklar bedava (K4).

signal block_requested(type: BlockType)

const TITLE_TEXT: String = "MACHINES"
const HINT_TEXT: String = "Click or drag onto the canvas. Input gates appear by themselves when a route brings goods."
const GATES_TEXT: String = "OUTPUT GATES"
const HEADER_COLOR: Color = Color(0.71, 0.59, 0.43)
const HINT_COLOR: Color = Color(0.69, 0.58, 0.43)

var _list: VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 0.0)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 6)
	margin.add_child(_list)


## Paleti MapConfig'ten kurar (bir kez).
func build(config: MapConfig) -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	_list.add_child(_header(TITLE_TEXT))
	var hint: Label = Label.new()
	hint.text = HINT_TEXT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override(&"font_size", 11)
	hint.add_theme_color_override(&"font_color", HINT_COLOR)
	_list.add_child(hint)
	for type: BlockType in config.factory_blocks:
		_list.add_child(_row(type))
	_list.add_child(_header(GATES_TEXT))
	for good: Good in config.factory_goods:
		_list.add_child(_row(config.gate_out.for_good(good)))


func _header(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 10)
	label.add_theme_color_override(&"font_color", HEADER_COLOR)
	label.custom_minimum_size = Vector2(0.0, 22.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _row(type: BlockType) -> Control:
	var root: HBoxContainer = HBoxContainer.new()
	root.add_theme_constant_override(&"separation", 6)
	var swatch: ColorRect = ColorRect.new()
	swatch.color = type.accent_color
	swatch.custom_minimum_size = Vector2(4.0, 0.0)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(swatch)
	var item: PaletteItem = PaletteItem.new()
	item.setup(type)
	item.tooltip_text = type.description
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.pressed.connect(func() -> void: block_requested.emit(type))
	root.add_child(item)
	return root
