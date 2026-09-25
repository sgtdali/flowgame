class_name ToolHighlights
extends RefCounted

## Seçili alete göre haritayı işaretler (görev 07): Factory'de kurulabilir boş
## arsalara fiyat etiketi, diğer noktalar soluk; Unlock'ta açılabilir bölgelere
## fiyat. Para yetmiyorsa etiket kırmızı (K2). Kural hesaplamaz: neyin
## kullanılabildiğini FactorySites / RegionState söyler.

const FACTORY_TAG: String = "Build %d"
const UNLOCK_TAG: String = "Unlock %d"


static func refresh(tool: MapTools.Tool, points: Array[MapPoint], views: Array[RegionView],
		sim: MapFlowSim, config: MapConfig) -> void:
	for point: MapPoint in points:
		match tool:
			MapTools.Tool.FACTORY:
				_mark_factory_plot(point, sim, config)
			_:
				point.set_tool_mark("", true, false)
	for view: RegionView in views:
		if view.data == null:
			continue
		var usable: bool = (tool == MapTools.Tool.UNLOCK
				and sim.regions.unlock_block_reason(view.data.id, true).is_empty())
		var cost: int = sim.regions.unlock_cost()
		view.set_tool_tag(UNLOCK_TAG % cost if usable else "", sim.regions.wallet.can_afford(cost))


static func _mark_factory_plot(point: MapPoint, sim: MapFlowSim, config: MapConfig) -> void:
	var usable: bool = (point.kind == MapPoint.Kind.FACTORY_PLOT
			and sim.factories.build_block_reason(point.get_point_id(), true).is_empty())
	if usable:
		point.set_tool_mark(FACTORY_TAG % config.factory_cost,
				sim.regions.wallet.can_afford(config.factory_cost), false)
	else:
		point.set_tool_mark("", true, true)
