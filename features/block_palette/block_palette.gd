class_name BlockPalette
extends PanelContainer

## Sol panel: kurulabilir istasyonların kataloğu.
##
## MİMARİ: Tuvali ve parayı TANIMAZ. Neyin açık, neyin karşılanabilir olduğu
## dışarıdan `set_availability()` ile söylenir. Kullanıcı bir istasyon
## isteyince YUKARI sinyal gönderir; kurma kararını GameController verir.

signal block_requested(type: BlockType)

## Kategorilerin paletteki gösterim sırası — akışın doğal sırası.
const _CATEGORY_ORDER: Array[BlockType.Category] = [
	BlockType.Category.SOURCE,
	BlockType.Category.PROCESS,
	BlockType.Category.INSPECT,
	BlockType.Category.BUFFER,
	BlockType.Category.SPLITTER,
	BlockType.Category.RESEARCH,
	BlockType.Category.SINK,
	BlockType.Category.FOOD,
]

@onready var _list: VBoxContainer = %List

## Kategori başlığı -> o başlığın altındaki satırlar. Kategorinin tamamı
## kilitliyse başlığı da gizleriz, yoksa boş başlıklar kalır.
var _sections: Array = []
var _rows: Array = []      # { type, root, item, cost_label }


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
		var header: Control = _build_header(in_category[0].category_label())
		_list.add_child(header)

		var section_rows: Array = []
		for type: BlockType in in_category:
			var row: Dictionary = _build_row(type)
			_list.add_child(row["root"])
			_rows.append(row)
			section_rows.append(row)
		_sections.append({"header": header, "rows": section_rows})


## Hangi istasyonlar açık, hangileri şu an karşılanabilir.
##
## Kilitli olan GİZLENİR (oyuncu daha varlığını bilmemeli), açık ama parası
## yetmeyen SOLUK gösterilir (hedef görünür olmalı).
func set_availability(available_ids: Dictionary, balance: int) -> void:
	for row: Dictionary in _rows:
		var type: BlockType = row["type"]
		var unlocked: bool = available_ids.has(type.id)
		var affordable: bool = balance >= type.build_cost

		(row["root"] as Control).visible = unlocked
		(row["item"] as PaletteItem).disabled = not affordable
		var cost_label: Label = row["cost_label"]
		cost_label.text = "%s gold" % GameConfig.format_money(type.build_cost)
		cost_label.add_theme_color_override(&"font_color",
			Color(0.90, 0.72, 0.39) if affordable else Color(0.61, 0.43, 0.36))

	# Tamamı kilitli kategorinin başlığını da gizle.
	for section: Dictionary in _sections:
		var any_visible: bool = false
		for row: Dictionary in section["rows"]:
			if (row["root"] as Control).visible:
				any_visible = true
				break
		(section["header"] as Control).visible = any_visible


func _build_header(text: String) -> Control:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override(&"font_size", 10)
	label.add_theme_color_override(&"font_color", Color(0.71, 0.59, 0.43))
	label.custom_minimum_size = Vector2(0.0, 22.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _build_row(type: BlockType) -> Dictionary:
	var root := HBoxContainer.new()
	root.add_theme_constant_override(&"separation", 6)

	var swatch := ColorRect.new()
	swatch.color = type.accent_color
	swatch.custom_minimum_size = Vector2(4.0, 0.0)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(swatch)

	var item := PaletteItem.new()
	item.setup(type)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.pressed.connect(_on_item_pressed.bind(type))
	root.add_child(item)

	var cost := Label.new()
	cost.custom_minimum_size = Vector2(58.0, 0.0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override(&"font_size", 11)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cost)

	return {"type": type, "root": root, "item": item, "cost_label": cost}


func _on_item_pressed(type: BlockType) -> void:
	block_requested.emit(type)
