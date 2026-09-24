class_name RegionState
extends RefCounted

## Harita katmanının kuralları (arayüzsüz): hangi bölge açık, hangisi açılabilir.
##
## Komşuluk şartı: kilitli bir bölge yalnızca açık bir bölgeye komşuysa
## açılabilir. Açılan bölge bir daha kilitlenmez.

enum Status { LOCKED, AVAILABLE, UNLOCKED }

## id -> true. Açık bölgeler.
var _unlocked: Dictionary = {}


func _init() -> void:
	for region: RegionData in RegionCatalog.all():
		if region.starts_unlocked:
			_unlocked[region.id] = true


func is_unlocked(region_id: StringName) -> bool:
	return _unlocked.has(region_id)


func status(region_id: StringName) -> Status:
	if is_unlocked(region_id):
		return Status.UNLOCKED
	var region: RegionData = RegionCatalog.find_by_id(region_id)
	if region != null:
		for neighbor_id: StringName in region.neighbors:
			if is_unlocked(neighbor_id):
				return Status.AVAILABLE
	return Status.LOCKED
