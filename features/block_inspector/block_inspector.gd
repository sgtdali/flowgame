class_name BlockInspector
extends PanelContainer

## Sağ panel: seçili istasyonun bilgileri.
##
## MİMARİ: Bloğu DEĞİŞTİRMEZ. Ad düzenlenince YUKARI sinyal gönderir; değeri
## bloğa yazma işini editör tuvale söyler.
##
## Süre, kapasite ve fire artık SALT OKUNUR — bunlar istasyon TÜRÜNÜN
## özellikleri, tek bir kopyanın değil. Oyuncu bunları araştırmayla
## iyileştirir, elle değil.

signal param_changed(key: StringName, value: Variant)

@onready var _empty: Label = %Empty
@onready var _form: VBoxContainer = %Form
@onready var _type_name: Label = %TypeName
@onready var _category: Label = %Category
@onready var _desc: Label = %Desc
@onready var _name_edit: LineEdit = %NameEdit
@onready var _info: VBoxContainer = %Info

## Formu koddan doldururken alan sinyallerinin geri tetiklenmesini engeller.
var _syncing: bool = false


func _ready() -> void:
	_name_edit.text_changed.connect(_on_name_changed)
	clear()


## Editörün çağırdığı komut: bu bloğun bilgilerini göster.
func show_block(block: FlowBlock) -> void:
	var type: BlockType = block.block_type

	_syncing = true
	_type_name.text = type.display_name
	_category.text = type.category_label()
	_desc.text = type.description
	_name_edit.text = block.block_label
	_syncing = false

	_rebuild_info(type)
	_empty.visible = false
	_form.visible = true


func clear() -> void:
	_form.visible = false
	_empty.visible = true


## --- Salt okunur bilgi bloğu ------------------------------------------------

func _rebuild_info(type: BlockType) -> void:
	for child in _info.get_children():
		# Ağaçtan hemen çıkar: queue_free ertelenir, aksi hâlde eski satırlar
		# yeni satırların yanında bir kare daha görünür.
		_info.remove_child(child)
		child.queue_free()

	var recipe: Recipe = type.recipe
	if recipe != null:
		_info.add_child(_make_caption("Reçete"))
		_info.add_child(_make_recipe_line(recipe))
		_info.add_child(_make_row("Süre", recipe.duration_text(GameConfig.TICKS_PER_SECOND)))
	else:
		_info.add_child(_make_caption("Reçete"))
		_info.add_child(_make_recipe_line(null))

	if type.category != BlockType.Category.SOURCE:
		_info.add_child(_make_row("Giriş kuyruğu", "%d" % type.input_capacity))
	if type.category != BlockType.Category.SINK:
		_info.add_child(_make_row("Çıkış kuyruğu", "%d" % type.output_capacity))
	if type.scrap_every_n > 0:
		_info.add_child(_make_row("Fire", "her %d üründe 1" % type.scrap_every_n))
	_info.add_child(_make_row("Kurulum", "%s ₺" % _money(type.build_cost)))


func _make_caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 11)
	label.add_theme_color_override(&"font_color", Color(0.62, 0.68, 0.75))
	return label


func _make_recipe_line(recipe: Recipe) -> Label:
	var label := Label.new()
	if recipe == null:
		label.text = "Üretim yapmaz — yalnızca taşır."
	else:
		label.text = "%s  →  %s" % [recipe.input_text(), recipe.output_text()]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", 12)
	label.add_theme_color_override(&"font_color", Color(0.82, 0.87, 0.92))
	return label


func _make_row(name_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override(&"font_size", 11)
	name_label.add_theme_color_override(&"font_color", Color(0.55, 0.61, 0.68))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override(&"font_size", 11)
	value_label.add_theme_color_override(&"font_color", Color(0.80, 0.85, 0.90))
	row.add_child(value_label)

	return row


## Binlik ayracı. Para int tutulduğu için biçimlendirme sunumda yapılır.
static func _money(amount: int) -> String:
	var text: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if amount < 0 else "") + out


func _on_name_changed(text: String) -> void:
	if _syncing:
		return
	param_changed.emit(&"label", text)
