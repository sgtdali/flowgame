class_name RouteState
extends RefCounted

## Hat kuralları (arayüzsüz): hat kurma, araç ekleme/çıkarma, hat silme.
##
## Kurallar (tasarım belgesi + görev 03):
##   - Hat yalnızca açık bölgelerdeki iki farklı nokta arasında kurulur.
##   - İki nokta arasında tek hat; kapasite araç ekleyerek artar.
##   - Yeni hat 1 araçla kurulur (hat kurulumu + 1 araç fiyatı); son araç çıkarılamaz.
##   - Araç satılınca / hat silinince araç fiyatının `vehicle_refund_percent`'i
##     geri verilir; kurulum ücreti geri verilmez.
##   - Bakım bu görevde yalnızca hesaplanır, paradan düşülmez (zaman akışı görev 04).

var _regions: RegionState
var _wallet: Wallet
var _config: MapConfig
var _routes: Array[MapRoute] = []


func _init(regions: RegionState, config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_regions = regions
	_wallet = regions.wallet
	_config = config


## "area1/City" -> &"area1"
static func region_of(point_id: StringName) -> StringName:
	return StringName(String(point_id).get_slice("/", 0))


func routes() -> Array[MapRoute]:
	return _routes.duplicate()


func find(point_a: StringName, point_b: StringName) -> MapRoute:
	for route: MapRoute in _routes:
		if route.connects(point_a, point_b):
			return route
	return null


## Yeni hat maliyeti: kurulum + ilk araç.
func build_cost(transport: TransportType) -> int:
	return transport.route_cost + transport.vehicle_price


## Bu noktadan hat başlatılamıyorsa nedeni; başlatılabiliyorsa "".
func start_block_reason(point_id: StringName) -> String:
	var region_id: StringName = region_of(point_id)
	if not _regions.is_unlocked(region_id):
		var region: RegionData = RegionCatalog.find_by_id(region_id)
		var region_name: String = region.display_name if region != null else String(region_id)
		return "%s is locked" % region_name
	return ""


## Hat kurulamıyorsa nedeni (arayüzde gösterilir); kurulabiliyorsa "".
func build_block_reason(point_a: StringName, point_b: StringName,
		transport: TransportType) -> String:
	if point_a == point_b:
		return "Pick a different point"
	for point_id: StringName in [point_a, point_b]:
		var locked: String = start_block_reason(point_id)
		if not locked.is_empty():
			return locked
	if find(point_a, point_b) != null:
		return "A route already connects these points"
	if not transport.available_at_start:
		return "%s is not researched yet" % transport.display_name
	if not _wallet.can_afford(build_cost(transport)):
		return "Not enough money"
	return ""


## Hattı 1 araçla kurar ve parayı düşer. Kurulamıyorsa null.
func build(point_a: StringName, point_b: StringName, distance: float,
		transport: TransportType) -> MapRoute:
	if not build_block_reason(point_a, point_b, transport).is_empty():
		return null
	_wallet.spend(build_cost(transport))
	var route: MapRoute = MapRoute.new(point_a, point_b, distance, transport)
	route.vehicles = 1
	_routes.append(route)
	return route


func add_vehicle_block_reason(route: MapRoute) -> String:
	if not _wallet.can_afford(route.transport.vehicle_price):
		return "Not enough money"
	return ""


func add_vehicle(route: MapRoute) -> bool:
	if not add_vehicle_block_reason(route).is_empty():
		return false
	_wallet.spend(route.transport.vehicle_price)
	route.vehicles += 1
	return true


func remove_vehicle_block_reason(route: MapRoute) -> String:
	if route.vehicles <= 1:
		return "A route needs at least one vehicle"
	return ""


func remove_vehicle(route: MapRoute) -> bool:
	if not remove_vehicle_block_reason(route).is_empty():
		return false
	route.vehicles -= 1
	_wallet.refund(vehicle_refund(route.transport))
	return true


## Hattı siler; araçlarının iadesini verir.
func remove_route(route: MapRoute) -> void:
	if not _routes.has(route):
		return
	_wallet.refund(vehicle_refund(route.transport) * route.vehicles)
	_routes.erase(route)


func vehicle_refund(transport: TransportType) -> int:
	return floori(transport.vehicle_price * _config.vehicle_refund_percent / 100.0)


func total_upkeep_per_minute() -> int:
	var total: int = 0
	for route: MapRoute in _routes:
		total += route.upkeep_per_minute()
	return total
