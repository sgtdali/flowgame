class_name PointDetails
extends RefCounted

## Nokta panelinde gösterilecek satırları hazırlar. Yalnızca biçimler;
## sayıları MapFlowSim'den okur, kural hesaplamaz.
##
## Satır: {"caption": String, "text": String} ve çubuklu/simgeli satırlarda
## ayrıca {"goods": Array[Good], "fill": float, "zones", "zone_colors"}
## (bkz. GoodBar). "goods" anahtarı olmayan satır düz yazıdır.

const EMPTY_FACTORY_TEXT: String = "Empty - open the factory to place machines"
## Şehir talebi çubuğu: talebin kaç katına kadar çizilir ve bölge renkleri
## (tam fiyat / yarı fiyat / onda bir). Bölge sınırları şehir seviyesinin
## doygunluk eşiklerinden gelir.
const DEMAND_BAR_EXTRA: float = 0.5
const DEMAND_ZONE_COLORS: Array[Color] = [
	Color(0.55, 0.85, 0.45), Color(1.0, 0.7, 0.25), Color(0.95, 0.35, 0.3)]


static func rows_for(point_id: StringName, sim: MapFlowSim, config: MapConfig) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var info: MapPoints.Info = MapPoints.find(point_id)
	var capacity: int = config.point_stock_capacity
	match sim.point_kind(point_id):
		MapPoints.Kind.RESOURCE_SITE:
			var goods: Array[Good] = [info.resource]
			rows.append(_icons("Produces", goods, "%d/min" % info.resource.extraction_per_minute))
			var stock: float = sim.stock(point_id, info.resource)
			rows.append(_bar("Stock", goods, stock / capacity, "%d/%d" % [roundi(stock), capacity]))
		MapPoints.Kind.FACTORY:
			_factory_rows(rows, sim.factories.interior_at(point_id))
		MapPoints.Kind.CITY:
			var level: CityLevel = sim.market.level(point_id)
			rows.append(_text("Level", level.display_name))
			for good: Good in level.demand_goods:
				rows.append(_demand_row(level, good, sim.market.sold_last_minute(point_id, good)))
			rows.append(_text("Income", "+%s/min" % RouteView.format_rate(
					sim.market.revenue_last_minute(point_id))))
	return rows


## Fabrika: her mal için giriş ve çıkış stoğu çubuğu + geçen dakikanın hızı; uyarı.
static func _factory_rows(rows: Array[Dictionary], interior: FactoryInterior) -> void:
	if interior.station_count() == 0:
		rows.append(_text("Status", EMPTY_FACTORY_TEXT))
	var capacity: float = float(interior.capacity)
	for good: Good in interior.summary_goods():
		var goods: Array[Good] = [good]
		var stock_in: float = interior.input_stock(good)
		var stock_out: float = interior.output_stock(good)
		if interior.input_gate_id(good) != -1:
			rows.append(_bar("In", goods, stock_in / capacity, "%d  %s/min" % [
					roundi(stock_in), RouteView.format_rate(interior.input_last_minute(good))]))
		if stock_out > 0.0 or interior.output_last_minute(good) > 0.0 or interior.output_goods().has(good):
			rows.append(_bar("Out", goods, stock_out / capacity, "%d  %s/min" % [
					roundi(stock_out), RouteView.format_rate(interior.output_last_minute(good))]))
	if interior.output_full():
		rows.append(_text("Warning", "Output full - build a route out"))
	elif interior.starved_last_minute():
		rows.append(_text("Warning", "Machines waiting for input"))


## Şehir talebi: çubuk talebin (son eşik + DEMAND_BAR_EXTRA) katına kadar;
## bölgeler doygunluk eşiklerinde biter.
static func _demand_row(level: CityLevel, good: Good, sold: float) -> Dictionary:
	var demand: float = level.demand_for(good)
	var thresholds: Array[float] = []
	thresholds.assign(level.saturation_thresholds)
	var top: float = (thresholds.back() if not thresholds.is_empty() else 1.0) + DEMAND_BAR_EXTRA
	var zones: PackedFloat32Array = PackedFloat32Array()
	for threshold: float in thresholds:
		zones.append(threshold / top)
	zones.append(1.0)
	var goods: Array[Good] = [good]
	var row: Dictionary = _bar("Wants", goods, sold / (demand * top) if demand > 0.0 else 0.0,
			"%s/%d per min" % [RouteView.format_rate(sold), roundi(demand)])
	row["zones"] = zones
	row["zone_colors"] = DEMAND_ZONE_COLORS
	return row


static func _text(caption: String, text: String) -> Dictionary:
	return {"caption": caption, "text": text}


static func _icons(caption: String, goods: Array[Good], text: String) -> Dictionary:
	return {"caption": caption, "text": text, "goods": goods, "fill": -1.0}


static func _bar(caption: String, goods: Array[Good], fill: float, text: String) -> Dictionary:
	return {"caption": caption, "text": text, "goods": goods, "fill": fill}
