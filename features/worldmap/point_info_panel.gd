class_name PointInfoPanel
extends PanelContainer

## Sağdaki nokta bilgi paneli. Seçili noktanın türünü, bölgesini ve
## içeriğini (stok, fabrika, talep) gösterir; hat başlatma ve fabrikaya girme
## düğmeleri buradadır. Fabrika kurmak araç çubuğundaki Factory aletiyle olur.
## Kural hesaplamaz: satırlar PointDetails'ten, engel nedeni MapPanels'ten gelir.

signal build_route_requested(point: MapPoint)
signal open_factory_requested(point: MapPoint)

const KIND_TEXT: Dictionary = {
	MapPoint.Kind.RESOURCE_SITE: "Resource site",
	MapPoint.Kind.FACTORY: "Factory",
	MapPoint.Kind.CITY: "City",
}
const REGION_STATUS_TEXT: Dictionary = {
	RegionState.Status.UNLOCKED: "unlocked",
	RegionState.Status.AVAILABLE: "locked, available",
	RegionState.Status.LOCKED: "locked",
}
## Grid'in başındaki sabit "Region" satırı (2 hücre) dinamik satırlardan önce durur.
const FIXED_GRID_CELLS: int = 2

@onready var title_label: Label = %PointTitleLabel
@onready var kind_label: Label = %PointKindLabel
@onready var region_value: Label = %PointRegionValue
@onready var grid: GridContainer = %PointGrid
@onready var factory_box: VBoxContainer = %FactoryBox
@onready var build_button: Button = %BuildRouteButton
@onready var build_reason_label: Label = %BuildReasonLabel

var _point: MapPoint = null


func _ready() -> void:
	hide()
	build_button.pressed.connect(func() -> void: build_route_requested.emit(_point))


## `rows`: PointDetails satırları. `route_reason`: hat başlatılamıyorsa nedeni.
## `can_open_factory`: nokta bir fabrikaysa "Open factory" düğmesi görünür.
func show_point(point: MapPoint, region_status: RegionState.Status,
		rows: Array[Dictionary], route_reason: String, can_open_factory: bool) -> void:
	_point = point
	title_label.text = point.get_title()
	kind_label.text = KIND_TEXT[point.kind]
	region_value.text = "%s (%s)" % [_region_name(point), REGION_STATUS_TEXT[region_status]]
	InfoRows.fill(grid, FIXED_GRID_CELLS, rows)
	_show_open_button(can_open_factory)
	build_button.disabled = not route_reason.is_empty()
	build_reason_label.text = route_reason
	build_reason_label.visible = not route_reason.is_empty()
	show()
	reset_size()


## Fabrikaya girme düğmesi; bir kez kurulur.
func _show_open_button(shown: bool) -> void:
	factory_box.visible = shown
	if not shown or factory_box.get_child_count() > 0:
		return
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0.0, 36.0)
	button.text = "Open factory"
	button.tooltip_text = "Place machines and connect them inside the factory."
	button.pressed.connect(func() -> void: open_factory_requested.emit(_point))
	factory_box.add_child(button)


static func _region_name(point: MapPoint) -> String:
	var view: RegionView = point.get_region_view()
	return view.data.display_name if view != null and view.data != null else "?"
