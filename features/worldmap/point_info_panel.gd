class_name PointInfoPanel
extends PanelContainer

## Sağdaki nokta bilgi paneli. Seçili noktanın türünü, bölgesini ve
## içeriğini (stok, fabrika, talep) gösterir; hat başlatma ve boş arsaya
## fabrika kurma butonları buradadır. Kural hesaplamaz: satırlar
## PointDetails'ten, engel nedenleri WorldMap'ten (RouteState/FactorySites) gelir.

signal build_route_requested(point: MapPoint)
signal build_factory_requested(point: MapPoint, recipe: ProcessRecipe)

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
const CAPTION_COLOR: Color = Color(0.7, 0.72, 0.7, 1)
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
## `factory_offers`: boş arsada [{recipe, reason}] (değilse boş).
func show_point(point: MapPoint, region_status: RegionState.Status,
		rows: Array[PackedStringArray], route_reason: String, factory_offers: Array[Dictionary],
		factory_cost: int) -> void:
	var same_point: bool = point == _point and visible
	_point = point
	title_label.text = point.get_title()
	kind_label.text = KIND_TEXT[point.kind]
	region_value.text = "%s (%s)" % [_region_name(point), REGION_STATUS_TEXT[region_status]]
	_fill_rows(rows)
	if same_point and factory_box.get_child_count() == factory_offers.size():
		_update_factory_offers(factory_offers)
	else:
		_fill_factory_offers(factory_offers, factory_cost)
	build_button.disabled = not route_reason.is_empty()
	var reasons: PackedStringArray = []
	if not route_reason.is_empty():
		reasons.append(route_reason)
	for offer: Dictionary in factory_offers:
		if not (offer["reason"] as String).is_empty() and not reasons.has(offer["reason"]):
			reasons.append(offer["reason"])
	build_reason_label.text = "\n".join(reasons)
	build_reason_label.visible = not reasons.is_empty()
	show()
	reset_size()


func _fill_rows(rows: Array[PackedStringArray]) -> void:
	var cells: Array[Node] = grid.get_children()
	var needed: int = FIXED_GRID_CELLS + rows.size() * 2
	# Hücre sayısı değişmediyse yalnızca metinleri güncelle (her adımda yeniden kurma).
	if cells.size() != needed:
		for i: int in range(FIXED_GRID_CELLS, cells.size()):
			grid.remove_child(cells[i])
			cells[i].queue_free()
		for i: int in rows.size():
			grid.add_child(_make_label(true))
			grid.add_child(_make_label(false))
		cells = grid.get_children()
	for r: int in rows.size():
		(cells[FIXED_GRID_CELLS + r * 2] as Label).text = rows[r][0]
		(cells[FIXED_GRID_CELLS + r * 2 + 1] as Label).text = rows[r][1]


func _fill_factory_offers(offers: Array[Dictionary], cost: int) -> void:
	for child: Node in factory_box.get_children():
		factory_box.remove_child(child)
		child.queue_free()
	for offer: Dictionary in offers:
		var recipe: ProcessRecipe = offer["recipe"]
		var button: Button = Button.new()
		button.text = "Build %s (%d)" % [recipe.display_name, cost]
		button.tooltip_text = PointDetails.recipe_text(recipe)
		button.custom_minimum_size = Vector2(0.0, 36.0)
		button.disabled = not (offer["reason"] as String).is_empty()
		button.pressed.connect(func() -> void: build_factory_requested.emit(_point, recipe))
		factory_box.add_child(button)
	factory_box.visible = not offers.is_empty()


func _update_factory_offers(offers: Array[Dictionary]) -> void:
	var buttons: Array[Node] = factory_box.get_children()
	for i: int in offers.size():
		(buttons[i] as Button).disabled = not (offers[i]["reason"] as String).is_empty()


func _make_label(caption: bool) -> Label:
	var label: Label = Label.new()
	if caption:
		label.add_theme_color_override("font_color", CAPTION_COLOR)
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	else:
		label.custom_minimum_size = Vector2(210.0, 0.0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func _region_name(point: MapPoint) -> String:
	var view: RegionView = point.get_region_view()
	return view.data.display_name if view != null and view.data != null else "?"
