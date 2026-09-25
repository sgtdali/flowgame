class_name ToolHighlights
extends RefCounted

## Seçili alete göre haritayı işaretler (görev 07): Factory'de noktalar soluk
## (fabrika boş yere kurulur); Unlock'ta açılabilir bölgelere
## fiyat. Para yetmiyorsa etiket kırmızı (K2). Hat kurulurken (Route aleti ya da
## panelden) önce hat başlatılabilen, ilk nokta seçilince ona bağlanabilen
## noktalar normal, diğerleri soluk (K5). Kural hesaplamaz: neyin
## kullanılabildiğini FactorySites / RegionState söyler.

const UNLOCK_TAG: String = "Unlock %d"


## `route_start`: yarım hattın ilk noktası (yoksa null).
static func refresh(tool: MapTools.Tool, route_start: MapPoint, points: Array[MapPoint],
		views: Array[RegionView], sim: MapFlowSim, _config: MapConfig) -> void:
	for point: MapPoint in points:
		if route_start != null:
			var usable: bool = point == route_start or sim.routes.build_block_reason(
					route_start.get_point_id(), point.get_point_id(), RouteBuilder.DEFAULT_TRANSPORT,
					true).is_empty()
			point.set_tool_mark("", true, not usable)
		elif tool == MapTools.Tool.ROUTE:
			point.set_tool_mark("", true,
					not sim.routes.start_block_reason(point.get_point_id()).is_empty())
		elif tool == MapTools.Tool.FACTORY:
			# Fabrika noktanın üstüne değil boş yere kurulur; noktalar hedef değil.
			point.set_tool_mark("", true, true)
		else:
			point.set_tool_mark("", true, false)
	for view: RegionView in views:
		if view.data == null:
			continue
		var usable: bool = (tool == MapTools.Tool.UNLOCK
				and sim.regions.unlock_block_reason(view.data.id, true).is_empty())
		var cost: int = sim.regions.unlock_cost()
		view.set_tool_tag(UNLOCK_TAG % cost if usable else "", sim.regions.wallet.can_afford(cost))
