class_name MapPanels
extends RefCounted

## Sağdaki üç paneli (bölge, nokta, hat) seçime göre doldurur.
## Yalnızca gösterir: sayıları ve engel nedenlerini MapFlowSim'den okur.

var _sim: MapFlowSim
var _config: MapConfig
var _region_panel: RegionInfoPanel
var _point_panel: PointInfoPanel
var _route_panel: RouteInfoPanel


func _init(sim: MapFlowSim, config: MapConfig, region_panel: RegionInfoPanel,
		point_panel: PointInfoPanel, route_panel: RouteInfoPanel) -> void:
	_sim = sim
	_config = config
	_region_panel = region_panel
	_point_panel = point_panel
	_route_panel = route_panel


## Aynı anda en fazla biri seçilidir; hiçbiri seçili değilse paneller kapanır.
func show_selection(region: RegionView, point: MapPoint, route_view: RouteView) -> void:
	if route_view == null:
		_route_panel.hide()
	if point == null:
		_point_panel.hide()
	if region == null or region.data == null:
		_region_panel.hide()
	if route_view != null:
		_show_route(route_view)
	elif point != null:
		_show_point(point)
	elif region != null and region.data != null:
		var regions: RegionState = _sim.regions
		_region_panel.show_region(region.data, regions.status(region.data.id),
				regions.unlock_cost(), regions.unlock_block_reason(region.data.id))


func _show_route(view: RouteView) -> void:
	var route: MapRoute = view.route
	var routes: RouteState = _sim.routes
	var flows: Array[PackedStringArray] = []
	for direction: MapRoute.Direction in [MapRoute.Direction.FORWARD, MapRoute.Direction.BACKWARD]:
		var start: MapPoint = view.from_point if direction == MapRoute.Direction.FORWARD else view.to_point
		var end: MapPoint = view.to_point if direction == MapRoute.Direction.FORWARD else view.from_point
		flows.append(PackedStringArray(["%s -> %s" % [start.get_title(), end.get_title()],
				_direction_text(route, direction)]))
	_route_panel.show_route(view, routes.add_vehicle_block_reason(route),
			routes.remove_vehicle_block_reason(route), routes.vehicle_refund(route.transport), flows)


## "Logs 10/min" ya da taşınamıyorsa nedeni.
func _direction_text(route: MapRoute, direction: MapRoute.Direction) -> String:
	var reason: String = _sim.direction_block_reason(route, direction)
	if not reason.is_empty():
		return reason
	var names: PackedStringArray = []
	for good: Good in _sim.cargo_options(route, direction):
		names.append(good.display_name)
	return "%s  %s/min" % [", ".join(names),
			RouteView.format_rate(_sim.route_flow(route, direction))]


func _show_point(point: MapPoint) -> void:
	var point_id: StringName = point.get_point_id()
	var view: RegionView = point.get_region_view()
	var offers: Array[Dictionary] = []
	if point.kind == MapPoint.Kind.FACTORY_PLOT and _sim.factories.recipe_at(point_id) == null:
		for recipe: ProcessRecipe in _config.factory_recipes:
			offers.append({"recipe": recipe,
					"reason": _sim.factories.build_block_reason(point_id, recipe)})
	_point_panel.show_point(point, _sim.regions.status(view.data.id),
			PointDetails.rows_for(point_id, _sim, _config),
			_sim.routes.start_block_reason(point_id), offers, _config.factory_cost)
