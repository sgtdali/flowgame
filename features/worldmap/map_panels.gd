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
	_route_panel.show_route(view, routes.add_vehicle_block_reason(route),
			routes.remove_vehicle_block_reason(route), routes.vehicle_refund(route.transport),
			route_rows(view))


## Hattın iki yönü: {caption "A -> B", goods, text} (panel ve özet kutusu).
func route_rows(view: RouteView) -> Array[Dictionary]:
	var flows: Array[Dictionary] = []
	for direction: MapRoute.Direction in [MapRoute.Direction.FORWARD, MapRoute.Direction.BACKWARD]:
		var start: MapPoint = view.from_point if direction == MapRoute.Direction.FORWARD else view.to_point
		var end: MapPoint = view.to_point if direction == MapRoute.Direction.FORWARD else view.from_point
		var flow: Dictionary = _direction_flow(view.route, direction)
		flow["caption"] = "%s -> %s" % [start.get_title(), end.get_title()]
		flow["fill"] = -1.0
		flows.append(flow)
	return flows


## Noktanın özet satırları (panelle aynı).
func point_rows(point: MapPoint) -> Array[Dictionary]:
	return PointDetails.rows_for(point.get_point_id(), _sim, _config)


## Bu yönde taşınabilecek mallar ve hız; taşınamıyorsa mal yok, metin nedeni.
func _direction_flow(route: MapRoute, direction: MapRoute.Direction) -> Dictionary:
	var reason: String = _sim.direction_block_reason(route, direction)
	if not reason.is_empty():
		return {"goods": [] as Array[Good], "text": reason}
	return {"goods": _sim.cargo_options(route, direction),
			"text": "%s/min" % RouteView.format_rate(_sim.route_flow(route, direction))}


func _show_point(point: MapPoint) -> void:
	var point_id: StringName = point.get_point_id()
	var view: RegionView = point.get_region_view()
	var action: PointInfoPanel.FactoryAction = PointInfoPanel.FactoryAction.NONE
	if point.kind == MapPoint.Kind.FACTORY_PLOT:
		action = (PointInfoPanel.FactoryAction.OPEN if _sim.factories.has_factory(point_id)
				else PointInfoPanel.FactoryAction.BUILD)
	_point_panel.show_point(point, _sim.regions.status(view.data.id),
			PointDetails.rows_for(point_id, _sim, _config),
			_sim.routes.start_block_reason(point_id), action,
			_sim.factories.build_block_reason(point_id)
					if action == PointInfoPanel.FactoryAction.BUILD else "",
			_config.factory_cost)
