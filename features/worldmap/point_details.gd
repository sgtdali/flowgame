class_name PointDetails
extends RefCounted

## Nokta panelinde gösterilecek satırları hazırlar (başlık, değer).
## Yalnızca metin biçimler; sayıları MapFlowSim'den okur, kural hesaplamaz.

const EMPTY_FACTORY_TEXT: String = "Empty - open the factory to place machines"


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
			var interior: FactoryInterior = sim.factories.interior_at(point_id)
			if interior == null:
				rows.append(_row("Status", "Empty plot"))
			else:
				_factory_rows(rows, interior)
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


## Fabrika özeti: her mal için giren/çıkan (geçen dakika) ve iki stok; uyarı.
static func _factory_rows(rows: Array[PackedStringArray], interior: FactoryInterior) -> void:
	var goods: Array[Good] = interior.summary_goods()
	if interior.station_count() == 0:
		rows.append(_row("Status", EMPTY_FACTORY_TEXT))
	for good: Good in goods:
		rows.append(_row(good.display_name, "in %s/min, out %s/min
stock in %d/%d, out %d/%d" % [
				RouteView.format_rate(interior.input_last_minute(good)),
				RouteView.format_rate(interior.output_last_minute(good)),
				floori(interior.input_stock(good)), interior.capacity,
				floori(interior.output_stock(good)), interior.capacity]))
	if interior.output_full():
		rows.append(_row("Warning", "Output full - build a route out"))
	elif interior.starved_last_minute():
		rows.append(_row("Warning", "Machines waiting for input"))


static func _stock_text(sim: MapFlowSim, point_id: StringName, good: Good, capacity: int) -> String:
	return "%s %d/%d" % [good.display_name, floori(sim.stock(point_id, good)), capacity]


static func _row(caption: String, value: String) -> PackedStringArray:
	return PackedStringArray([caption, value])
