class_name MapTools
extends RefCounted

## Haritanın araç çubuğu aletleri: hangisi seçili, alet açıkken tıklama,
## Esc / sağ tık ve 1 / 2 / 3 kısayolları (görev 07).
##
## Kural hesaplamaz: bir hedefin kullanılıp kullanılamayacağını ve nedenini
## RouteState / FactorySites / RegionState söyler. Fabrika kurma ve bölge
## açmayı WorldMap yapar (sinyalle istenir); hat kurma akışı RouteBuilder'dadır.

enum Tool { NONE, ROUTE, FACTORY, UNLOCK }

signal tool_changed(tool: Tool)
signal factory_requested(point: MapPoint)
signal unlock_requested(region_id: StringName)
## Hedef kullanılamadı; nedeni.
signal rejected(reason: String)

const SHORTCUTS: Dictionary = {KEY_1: Tool.ROUTE, KEY_2: Tool.FACTORY, KEY_3: Tool.UNLOCK}
## Alet seçiliyken, başka bir şey yapılmıyorsa üst çubukta görünen ipucu.
const IDLE_HINTS: Dictionary = {
	Tool.ROUTE: "Route: click a point to start a route. Esc or right-click to stop.",
	Tool.FACTORY: "Factory: click an empty plot to build. Esc or right-click to stop.",
	Tool.UNLOCK: "Unlock: click a region to buy access. Esc or right-click to stop.",
}

var tool: Tool = Tool.NONE
var _sim: MapFlowSim
var _route_builder: RouteBuilder


func _init(sim: MapFlowSim, route_builder: RouteBuilder) -> void:
	_sim = sim
	_route_builder = route_builder


func is_active() -> bool:
	return tool != Tool.NONE


## Aleti seçer; aynı alet yeniden seçilirse bırakır.
func toggle(value: Tool) -> void:
	set_tool(Tool.NONE if value == tool else value)


func set_tool(value: Tool) -> void:
	if value == tool:
		return
	if _route_builder.is_building():
		_route_builder.cancel()
	tool = value
	tool_changed.emit(tool)


## Seçili aletin boşta ipucu ("" alet yoksa).
func idle_hint() -> String:
	return IDLE_HINTS.get(tool, "")


## Kısayollar ve Esc. İşlendiyse true.
func handle_key(key: InputEventKey) -> bool:
	if not key.pressed or key.echo:
		return false
	if SHORTCUTS.has(key.keycode):
		toggle(SHORTCUTS[key.keycode])
		return true
	if key.keycode == KEY_ESCAPE:
		return step_back()
	return false


## Esc ve sağ tık: önce yarım hattı iptal eder, sonra aleti bırakır (K1). İşlendiyse true.
func step_back() -> bool:
	if _route_builder.is_building():
		_route_builder.cancel()
		return true
	if is_active():
		set_tool(Tool.NONE)
		return true
	return false


## Alet açıkken sol tık. Alet yoksa false döner (WorldMap seçim yapar).
func handle_click(point: MapPoint, region: RegionView) -> bool:
	match tool:
		Tool.ROUTE:
			_click_route(point)
		Tool.FACTORY:
			_click_factory(point)
		Tool.UNLOCK:
			_click_unlock(region)
		_:
			return false
	return true


func _click_route(point: MapPoint) -> void:
	if _route_builder.is_building():
		if point != null:
			_route_builder.try_finish(point)
		else:
			_route_builder.cancel()
		return
	if point == null:
		return
	var reason: String = _sim.routes.start_block_reason(point.get_point_id())
	if reason.is_empty():
		_route_builder.start(point)
	else:
		rejected.emit(reason)


func _click_factory(point: MapPoint) -> void:
	if point == null:
		return
	var reason: String = _sim.factories.build_block_reason(point.get_point_id())
	if reason.is_empty():
		factory_requested.emit(point)
	else:
		rejected.emit(reason)


func _click_unlock(region: RegionView) -> void:
	if region == null or region.data == null:
		return
	var reason: String = _sim.regions.unlock_block_reason(region.data.id)
	if reason.is_empty():
		unlock_requested.emit(region.data.id)
	else:
		rejected.emit(reason)
