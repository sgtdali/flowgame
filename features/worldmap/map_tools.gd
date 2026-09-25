class_name MapTools
extends RefCounted

## Haritanın araç çubuğu aletleri: hangisi seçili, alet açıkken tıklama,
## Esc / sağ tık ve 1 / 2 / 3 kısayolları (görev 07).
##
## Kural hesaplamaz: bir hedefin kullanılıp kullanılamayacağını ve nedenini
## RouteState / FactorySites / RegionState söyler. Fabrika kurma ve bölge
## açmayı WorldMap yapar (sinyalle istenir); hat kurma akışı RouteBuilder'dadır.

enum Tool { NONE, ROUTE, FACTORY, UNLOCK }
## İmleç yazısının durumu: kurulabilir / para yetmiyor / kurulamaz.
enum TagState { OK, EXPENSIVE, BLOCKED }

const FACTORY_TAG: String = "Build %d"

signal tool_changed(tool: Tool)
## Fabrika kurulacak bölge ve dünya konumu.
signal factory_requested(region: RegionView, world_position: Vector2)
signal unlock_requested(region_id: StringName)
## Hedef kullanılamadı; nedeni.
signal rejected(reason: String)

const SHORTCUTS: Dictionary = {KEY_1: Tool.ROUTE, KEY_2: Tool.FACTORY, KEY_3: Tool.UNLOCK}
## Alet seçiliyken, başka bir şey yapılmıyorsa üst çubukta görünen ipucu.
const IDLE_HINTS: Dictionary = {
	Tool.ROUTE: "Route: click a point to start a route. Esc or right-click to stop.",
	Tool.FACTORY: "Factory: click an empty spot in an unlocked region. Esc or right-click to stop.",
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


## İmlecin yanındaki yazı ({text, state}); gösterilecek bir şey yoksa text "".
## Yalnızca Factory aletinde: boş yerde fiyat, kurulamayan yerde nedeni.
func cursor_tag(point: MapPoint, region: RegionView) -> Dictionary:
	if tool != Tool.FACTORY or point != null or region == null or region.data == null:
		return {"text": ""}
	var reason: String = _sim.factories.build_block_reason(region.data.id, true)
	if not reason.is_empty():
		return {"text": reason, "state": TagState.BLOCKED}
	var cost: int = RegionState.DEFAULT_CONFIG.factory_cost
	return {"text": FACTORY_TAG % cost,
			"state": TagState.OK if _sim.regions.wallet.can_afford(cost) else TagState.EXPENSIVE}


## Alet açıkken sol tık. Alet yoksa false döner (WorldMap seçim yapar).
func handle_click(point: MapPoint, region: RegionView, world_position: Vector2) -> bool:
	match tool:
		Tool.ROUTE:
			_click_route(point)
		Tool.FACTORY:
			_click_factory(point, region, world_position)
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


## Boş bir yere tıklanmalı: bir noktanın üstüne fabrika kurulmaz (görev 08, K2).
func _click_factory(point: MapPoint, region: RegionView, world_position: Vector2) -> void:
	if point != null:
		rejected.emit("Pick an empty spot, not %s" % point.get_title())
		return
	if region == null or region.data == null:
		rejected.emit("Factories can only be built inside a region")
		return
	var reason: String = _sim.factories.build_block_reason(region.data.id)
	if reason.is_empty():
		factory_requested.emit(region, world_position)
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
