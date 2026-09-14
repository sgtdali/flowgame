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
@onready var _worker_button: Button = %WorkerButton
@onready var _info: VBoxContainer = %Info

## Formu koddan doldururken alan sinyallerinin geri tetiklenmesini engeller.
var _syncing: bool = false


func _ready() -> void:
	_name_edit.text_changed.connect(_on_name_changed)
	_worker_button.toggled.connect(_on_worker_toggled)
	clear()


## Editörün çağırdığı komut: bu bloğun bilgilerini göster.
func show_block(block: FlowBlock) -> void:
	var type: BlockType = block.block_type

	_syncing = true
	_type_name.text = type.display_name
	_category.text = type.category_label()
	_desc.text = type.description
	_name_edit.text = block.block_label
	_worker_button.visible = type.requires_worker()
	_worker_button.button_pressed = block.worker_assigned
	_worker_button.text = "Worker assigned" if block.worker_assigned else "Assign worker"
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
		_info.add_child(_make_caption("Crafting"))
		_info.add_child(_make_recipe_line(type))
		_info.add_child(_make_row("Time", recipe.duration_text(GameConfig.TICKS_PER_SECOND)))
	else:
		_info.add_child(_make_caption("Crafting"))
		_info.add_child(_make_recipe_line(type))

	if type.category != BlockType.Category.SOURCE:
		_info.add_child(_make_row("Input storage", "%d" % type.input_capacity))
	if type.category != BlockType.Category.SINK and type.category != BlockType.Category.FOOD:
		_info.add_child(_make_row("Output storage", "%d" % type.output_capacity))
	if type.scrap_every_n > 0:
		_info.add_child(_make_row("Scrap", "1 in every %d" % type.scrap_every_n))
	_info.add_child(_make_row("Build cost", "%s gold" % GameConfig.format_money(type.build_cost)))


func _make_caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 11)
	label.add_theme_color_override(&"font_color", Color(0.78, 0.68, 0.51))
	return label


func _make_recipe_line(type: BlockType) -> Label:
	var label := Label.new()
	if type.category == BlockType.Category.FOOD:
		label.text = "Deposits bread as food for the workforce."
	elif type.category == BlockType.Category.SINK:
		label.text = "Sells incoming goods for gold."
	elif type.category == BlockType.Category.RESEARCH:
		label.text = "Accepts goods toward knowledge discoveries."
	elif type.recipe == null:
		label.text = "Stores or routes goods between workshops."
	else:
		label.text = "%s  →  %s" % [type.recipe.input_text(), type.recipe.output_text()]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", 12)
	label.add_theme_color_override(&"font_color", Color(0.94, 0.85, 0.68))
	return label


func _make_row(name_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override(&"font_size", 11)
	name_label.add_theme_color_override(&"font_color", Color(0.73, 0.62, 0.47))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override(&"font_size", 11)
	value_label.add_theme_color_override(&"font_color", Color(0.91, 0.82, 0.64))
	row.add_child(value_label)

	return row


func _on_worker_toggled(assigned: bool) -> void:
	if not _syncing:
		param_changed.emit(&"worker", assigned)


func _on_name_changed(text: String) -> void:
	if _syncing:
		return
	param_changed.emit(&"label", text)
