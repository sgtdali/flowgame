class_name RouteInfoPanel
extends PanelContainer

## Sağdaki hat paneli: uçlar, mesafe, tür, araç, kapasite, bakım ve
## araç ekleme/çıkarma, hat silme butonları.
##
## Kural hesaplamaz: fiyat, iade ve engel nedenleri WorldMap'ten (RouteState)
## gelir; butonlar yalnızca istek gönderir.

signal add_vehicle_requested(route: MapRoute)
signal remove_vehicle_requested(route: MapRoute)
signal remove_route_requested(route: MapRoute)

@onready var from_value: Label = %RouteFromValue
@onready var to_value: Label = %RouteToValue
@onready var distance_value: Label = %RouteDistanceValue
@onready var transport_value: Label = %RouteTransportValue
@onready var vehicles_value: Label = %RouteVehiclesValue
@onready var capacity_value: Label = %RouteCapacityValue
@onready var upkeep_value: Label = %RouteUpkeepValue
@onready var forward_caption: Label = %RouteForwardCaption
@onready var forward_value: GoodBar = %RouteForwardValue
@onready var backward_caption: Label = %RouteBackwardCaption
@onready var backward_value: GoodBar = %RouteBackwardValue
@onready var add_button: Button = %AddVehicleButton
@onready var remove_button: Button = %RemoveVehicleButton
@onready var delete_button: Button = %RemoveRouteButton
@onready var reason_label: Label = %RouteReasonLabel

var _route: MapRoute = null


func _ready() -> void:
	hide()
	add_button.pressed.connect(func() -> void: add_vehicle_requested.emit(_route))
	remove_button.pressed.connect(func() -> void: remove_vehicle_requested.emit(_route))
	delete_button.pressed.connect(func() -> void: remove_route_requested.emit(_route))


## `add_reason` / `remove_reason`: işlem yapılamıyorsa nedeni, yoksa "".
## `refund`: bir aracın iadesi. `flows`: iki yön için {caption, goods, text}
## (ör. "Forest -> Factory", [Logs], "10/min"; taşınamıyorsa goods boş, text nedeni).
func show_route(view: RouteView, add_reason: String, remove_reason: String, refund: int,
		flows: Array[Dictionary]) -> void:
	_route = view.route
	var transport: TransportType = _route.transport
	from_value.text = view.from_point.describe()
	to_value.text = view.to_point.describe()
	distance_value.text = MapUnits.km_text(_route.distance)
	transport_value.text = transport.display_name
	vehicles_value.text = str(_route.vehicles)
	capacity_value.text = "%s/min" % RouteView.format_rate(_route.capacity_per_minute())
	upkeep_value.text = "%d/min" % _route.upkeep_per_minute()
	forward_caption.text = flows[0]["caption"]
	forward_value.set_data(flows[0]["goods"], -1.0, flows[0]["text"])
	backward_caption.text = flows[1]["caption"]
	backward_value.set_data(flows[1]["goods"], -1.0, flows[1]["text"])
	add_button.text = "+ Vehicle (%d)" % transport.vehicle_price
	remove_button.text = "- Vehicle (+%d)" % refund
	delete_button.text = "Remove route (+%d)" % (refund * _route.vehicles)
	add_button.disabled = not add_reason.is_empty()
	remove_button.disabled = not remove_reason.is_empty()
	var reasons: PackedStringArray = []
	for reason: String in [add_reason, remove_reason]:
		if not reason.is_empty():
			reasons.append(reason)
	reason_label.text = "\n".join(reasons)
	reason_label.visible = not reasons.is_empty()
	show()
	reset_size()
