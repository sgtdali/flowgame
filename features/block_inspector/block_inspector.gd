class_name BlockInspector
extends PanelContainer

## Sağ panel: seçili istasyonun parametreleri.
##
## MİMARİ: Bloğu DEĞİŞTİRMEZ. Kullanıcı bir alanı düzenleyince YUKARI sinyal
## gönderir; değeri bloğa yazma işini editör tuvale söyler. Veri sahibi
## daima bloğun kendisidir.

signal param_changed(key: StringName, value: Variant)

@onready var _empty: Label = %Empty
@onready var _form: VBoxContainer = %Form
@onready var _type_name: Label = %TypeName
@onready var _category: Label = %Category
@onready var _desc: Label = %Desc
@onready var _name_edit: LineEdit = %NameEdit
@onready var _cycle_edit: SpinBox = %CycleEdit
@onready var _capacity_edit: SpinBox = %CapacityEdit
@onready var _operators_edit: SpinBox = %OperatorsEdit
@onready var _scrap_edit: SpinBox = %ScrapEdit

## Formu koddan doldururken alan sinyallerinin geri tetiklenmesini engeller.
var _syncing: bool = false


func _ready() -> void:
	_name_edit.text_changed.connect(_on_name_changed)
	_cycle_edit.value_changed.connect(_on_value_changed.bind(&"cycle_time_s"))
	_capacity_edit.value_changed.connect(_on_value_changed.bind(&"capacity"))
	_operators_edit.value_changed.connect(_on_value_changed.bind(&"operators"))
	_scrap_edit.value_changed.connect(_on_scrap_changed)
	clear()


## Editörün çağırdığı komut: bu bloğun değerlerini göster.
func show_block(block: FlowBlock) -> void:
	_syncing = true
	_type_name.text = block.block_type.display_name
	_category.text = block.block_type.category_label()
	_desc.text = block.block_type.description
	_name_edit.text = block.block_label
	_cycle_edit.value = block.cycle_time_s
	_capacity_edit.value = float(block.capacity)
	_operators_edit.value = float(block.operators)
	_scrap_edit.value = block.scrap_rate * 100.0
	_syncing = false

	_empty.visible = false
	_form.visible = true


func clear() -> void:
	_form.visible = false
	_empty.visible = true


func _on_name_changed(text: String) -> void:
	if _syncing:
		return
	param_changed.emit(&"label", text)


func _on_value_changed(value: float, key: StringName) -> void:
	if _syncing:
		return
	param_changed.emit(key, value)


## Kullanıcı yüzde girer, blok 0.0-1.0 oran tutar.
func _on_scrap_changed(value: float) -> void:
	if _syncing:
		return
	param_changed.emit(&"scrap_rate", value / 100.0)
