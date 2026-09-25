class_name PointInfoPanel
extends PanelContainer

## Sağdaki nokta bilgi paneli. Seçili noktanın türünü, bölgesini ve
## içeriğini (stok, fabrika, talep) gösterir; hat başlatma ve boş arsaya
## fabrika kurma butonları buradadır. Kural hesaplamaz: satırlar
## PointDetails'ten, engel nedenleri MapPanels'ten (RouteState/FactorySites) gelir.

signal build_route_requested(point: MapPoint)
signal build_factory_requested(point: MapPoint)
signal open_factory_requested(point: MapPoint)

## Arsa panelindeki fabrika düğmesi: yok / "Build factory" / "Open factory".
enum FactoryAction { NONE, BUILD, OPEN }

const KIND_TEXT: Dictionary = {
	MapPoint.Kind.RESOURCE_SITE: "Resource site",
	MapPoint.Kind.FACTORY_PLOT: "Factory plot",
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
## `factory_action`: arsadaki fabrika düğmesi; `factory_reason`: kurulamıyorsa nedeni.
func show_point(point: MapPoint, region_status: RegionState.Status,
		rows: Array[Dictionary], route_reason: String, factory_action: FactoryAction,
		factory_reason: String, factory_cost: int) -> void:
	_point = point
	title_label.text = point.get_title()
	kind_label.text = KIND_TEXT[point.kind]
	region_value.text = "%s (%s)" % [_region_name(point), REGION_STATUS_TEXT[region_status]]
	InfoRows.fill(grid, FIXED_GRID_CELLS, rows)
	_show_factory_button(factory_action, factory_reason, factory_cost)
	build_button.disabled = not route_reason.is_empty()
	var reasons: PackedStringArray = []
	if not route_reason.is_empty():
		reasons.append(route_reason)
	if factory_action == FactoryAction.BUILD and not factory_reason.is_empty() and not reasons.has(factory_reason):
		reasons.append(factory_reason)
	build_reason_label.text = "\n".join(reasons)
	build_reason_label.visible = not reasons.is_empty()
	show()
	reset_size()


## Arsadaki tek fabrika düğmesi; bir kez kurulur, sonra yalnızca güncellenir.
func _show_factory_button(action: FactoryAction, reason: String, cost: int) -> void:
	factory_box.visible = action != FactoryAction.NONE
	if action == FactoryAction.NONE:
		return
	var button: Button = factory_box.get_child(0) as Button if factory_box.get_child_count() > 0 else null
	if button == null:
		button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 36.0)
		button.pressed.connect(_on_factory_button_pressed)
		factory_box.add_child(button)
	if action == FactoryAction.BUILD:
		button.text = "Build factory (%d)" % cost
		button.tooltip_text = "An empty factory. Open it to place machines inside."
		button.disabled = not reason.is_empty()
	else:
		button.text = "Open factory"
		button.tooltip_text = "Place machines and connect them inside the factory."
		button.disabled = false
	button.set_meta(&"action", action)


func _on_factory_button_pressed() -> void:
	var button: Button = factory_box.get_child(0) as Button
	if button.get_meta(&"action") == FactoryAction.BUILD:
		build_factory_requested.emit(_point)
	else:
		open_factory_requested.emit(_point)


static func _region_name(point: MapPoint) -> String:
	var view: RegionView = point.get_region_view()
	return view.data.display_name if view != null and view.data != null else "?"
