class_name MapMarkers
extends RefCounted

## Harita noktalarının üstündeki durum işaretlerini simülasyondan günceller:
## fabrika uyarısı, şehir gelir rozeti (ve stok çubukları). Yalnızca okur ve
## MapPoint'e yazar; kural hesaplamaz.


static func refresh(points: Array[MapPoint], sim: MapFlowSim) -> void:
	for point: MapPoint in points:
		var point_id: StringName = point.get_point_id()
		match point.kind:
			MapPoint.Kind.FACTORY_PLOT:
				point.set_warning(sim.factory_warning(point_id))
			MapPoint.Kind.CITY:
				point.set_income(sim.market.revenue_last_minute(point_id),
						sim.market.saturated_last_minute(point_id))
