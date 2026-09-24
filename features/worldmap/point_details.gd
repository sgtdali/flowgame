class_name PointDetails
extends RefCounted

## Nokta panelinde gösterilecek satırları hazırlar (başlık, değer).
## Yalnızca metin biçimler; sayıları MapFlowSim'den okur, kural hesaplamaz.

const FACTORY_STATUS_TEXT: Dictionary = {
	MapFlowSim.FactoryStatus.WORKING: "Working",
	MapFlowSim.FactoryStatus.NO_INPUT: "Waiting for input",
	MapFlowSim.FactoryStatus.OUTPUT_FULL: "Output full - build a route out",
}


## Dönüş: [[başlık, değer], ...]
static func rows_for(point_id: StringName, sim: MapFlowSim, config: MapConfig) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var info: MapPoints.Info = MapPoints.find(point_id)
	if info == null:
		return rows
	var capacity: int = config.point_stock_capacity
	match info.kind:
		MapPoints.Kind.RESOURCE_SITE:
			rows.append(_row("Produces", "%s  %d/min" % [info.resource.display_name,
					info.resource.extraction_per_minute]))
			rows.append(_row("Stock", _stock_text(sim, point_id, info.resource, capacity)))
		MapPoints.Kind.FACTORY_PLOT:
			var recipe: ProcessRecipe = sim.factories.recipe_at(point_id)
			if recipe == null:
				rows.append(_row("Status", "Empty plot"))
			else:
				rows.append(_row("Recipe", recipe_text(recipe)))
				for good: Good in recipe.inputs:
					rows.append(_row("Input", _stock_text(sim, point_id, good, capacity)))
				rows.append(_row("Output", _stock_text(sim, point_id, recipe.output, capacity)))
				rows.append(_row("Status", FACTORY_STATUS_TEXT[sim.factory_status(point_id)]))
		MapPoints.Kind.CITY:
			var level: CityLevel = sim.market.level(point_id)
			rows.append(_row("Level", level.display_name))
			for good: Good in level.demand_goods:
				rows.append(_row(good.display_name, "wants %d/min, got %s last min (price %d)" % [
						level.demand_for(good),
						RouteView.format_rate(sim.market.sold_last_minute(point_id, good)),
						good.city_price]))
			rows.append(_row("Income", "%s last min" % RouteView.format_rate(
					sim.market.revenue_last_minute(point_id))))
	return rows


## "Sawmill: 1 Logs -> 1 Lumber, 10/min"
static func recipe_text(recipe: ProcessRecipe) -> String:
	var parts: PackedStringArray = []
	for i: int in recipe.inputs.size():
		parts.append("%d %s" % [recipe.input_amounts[i], recipe.inputs[i].display_name])
	return "%s: %s -> %d %s, %s/min" % [recipe.display_name, " + ".join(parts),
			recipe.output_amount, recipe.output.display_name,
			RouteView.format_rate(recipe.outputs_per_minute)]


static func _stock_text(sim: MapFlowSim, point_id: StringName, good: Good, capacity: int) -> String:
	return "%s %d/%d" % [good.display_name, floori(sim.stock(point_id, good)), capacity]


static func _row(caption: String, value: String) -> PackedStringArray:
	return PackedStringArray([caption, value])
