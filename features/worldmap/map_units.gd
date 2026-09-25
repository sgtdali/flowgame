class_name MapUnits
extends RefCounted

## Harita birimini oyuncuya gösterilecek uzunluğa çevirir (1 birim = MapConfig.meters_per_unit m).

const METERS_PER_KM: float = 1000.0


## 120 birim → "1.2 km"
static func km_text(distance: float, config: MapConfig = RegionState.DEFAULT_CONFIG) -> String:
	return "%.1f km" % (distance * config.meters_per_unit / METERS_PER_KM)
