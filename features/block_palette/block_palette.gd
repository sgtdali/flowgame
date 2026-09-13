class_name BlockPalette
extends PanelContainer

## Sol panel: eklenebilir istasyonların kataloğu.
##
## MİMARİ: Tuvali TANIMAZ. Kullanıcı bir istasyon isteyince YUKARI sinyal
## gönderir; bloğu tuvale ekleme kararını editör verir.

signal block_requested(type: BlockType)

## Kategorilerin paletteki gösterim sırası — akışın doğal sırası.
const _CATEGORY_ORDER: Array[BlockType.Category] = [
	BlockType.Category.SOURCE,
	BlockType.Category.PROCESS,
	BlockType.Category.INSPECT,
	BlockType.Category.BUFFER,
	BlockType.Category.SINK,
]

@onready var _list: VBoxContainer = %List


func _ready() -> void:
	_populate()


func _populate() -> void:
	var types: Array[BlockType] = BlockCatalog.all()
	for category: BlockType.Category in _CATEGORY_ORDER:
		var in_category: Array[BlockType] = types.filter(
			func(type: BlockType) -> bool: return type.category == category
		)
		if in_category.is_empty():
			continue
		_list.add_child(_build_header(in_category[0].category_label()))
		for type: BlockType in in_category:
			_list.add_child(_build_row(type))


func _build_header(text: String) -> Control:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override(&"font_size", 10)
	label.add_theme_color_override(&"font_color", Color(0.45, 0.52, 0.60))
	label.custom_minimum_size = Vector2(0.0, 22.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _build_row(type: BlockType) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)

	var swatch := ColorRect.new()
	swatch.color = type.accent_color
	swatch.custom_minimum_size = Vector2(4.0, 0.0)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)

	var item := PaletteItem.new()
	item.setup(type)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.pressed.connect(_on_item_pressed.bind(type))
	row.add_child(item)

	return row


func _on_item_pressed(type: BlockType) -> void:
	block_requested.emit(type)
