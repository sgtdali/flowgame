class_name RegionCatalog
extends RefCounted

## Harita bölgelerinin tek kayıt noktası (bkz. ItemCatalog aynı desen).
##
## Harita katmanı kuralları (RegionState) sahneye bakmadan bölgeleri buradan
## bulur. Yeni bölge: .tres ekle, buraya ekle, çizimde düğümüne bağla.

const AREA1 := preload("res://data/regions/area1.tres")
const AREA2 := preload("res://data/regions/area2.tres")
const AREA3 := preload("res://data/regions/area3.tres")
const AREA4 := preload("res://data/regions/area4.tres")
const AREA5 := preload("res://data/regions/area5.tres")

const _ALL: Array = [AREA1, AREA2, AREA3, AREA4, AREA5]

## id -> RegionData. İlk erişimde kurulur.
static var _by_id: Dictionary = {}


static func all() -> Array[RegionData]:
	var out: Array[RegionData] = []
	out.assign(_ALL)
	return out


static func find_by_id(region_id: StringName) -> RegionData:
	if _by_id.is_empty():
		for region: RegionData in all():
			_by_id[region.id] = region
	return _by_id.get(region_id, null)
