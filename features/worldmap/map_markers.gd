class_name MapMarkers
extends RefCounted

## Harita noktalarının üstündeki durum işaretlerini simülasyondan günceller:
## fabrika uyarısı, şehir gelir rozeti, stok çubukları ve mal simgeleri
## (görev 06). Yalnızca okur ve MapPoint'e yazar; kural hesaplamaz.


static func refresh(points: Array[MapPoint], sim: MapFlowSim, capacity: int) -> void:
	for point: MapPoint in points:
		var point_id: StringName = point.get_point_id()
		match point.kind:
			MapPoint.Kind.RESOURCE_SITE:
				if point.resource != null:
					# Kilitli bölgedeki yatak üretmez; boş çubuk kalabalık yapmasın.
					var info: MapPoints.Info = MapPoints.find(point_id)
					var unlocked: bool = info != null and sim.regions.is_unlocked(info.region_id)
					point.set_stock(sim.stock(point_id, point.resource) / float(capacity) if unlocked else -1.0)
					point.set_goods([point.resource] as Array[Good])
			MapPoint.Kind.FACTORY_PLOT:
				var interior: FactoryInterior = sim.factories.interior_at(point_id)
				point.set_warning(sim.factory_warning(point_id))
				point.set_stock(interior.fullest_output() if interior != null else -1.0)
				var goods: Array[Good] = []
				if interior != null:
					goods = interior.output_goods()
				point.set_goods(goods)
			MapPoint.Kind.CITY:
				point.set_income(sim.market.revenue_last_minute(point_id),
						sim.market.saturated_last_minute(point_id))
