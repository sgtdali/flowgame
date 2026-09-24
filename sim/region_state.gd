class_name RegionState
extends RefCounted

## Harita katmanının kuralları (arayüzsüz): para, hangi bölge açık, hangisi açılabilir.
##
## Komşuluk şartı: kilitli bir bölge yalnızca açık bir bölgeye komşuysa
## açılabilir. Açılan bölge bir daha kilitlenmez.
## Maliyet bölgeye değil sıraya bağlıdır (bkz. MapConfig).
## Para şimdilik burada tutulur; fabrika ekonomisine bağlamak ayrı görevdir.

enum Status { LOCKED, AVAILABLE, UNLOCKED }

const DEFAULT_CONFIG: MapConfig = preload("res://data/map_config.tres")

var money: int = 0

var _config: MapConfig
## id -> true. Açık bölgeler (başlangıçta açık olanlar dahil).
var _unlocked: Dictionary = {}
## Para ile açılmış bölge sayısı; maliyet bununla artar.
var _purchased: int = 0


func _init(config: MapConfig = DEFAULT_CONFIG) -> void:
	_config = config
	money = config.starting_money
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


## Bir sonraki bölgeyi açmanın maliyeti (hangi bölge olduğu fark etmez).
func unlock_cost() -> int:
	return _config.first_unlock_cost + _config.unlock_cost_step * _purchased


## Bölge şu an açılamıyorsa nedeni (arayüzde gösterilir); açılabiliyorsa "".
func unlock_block_reason(region_id: StringName) -> String:
	if RegionCatalog.find_by_id(region_id) == null:
		return "Unknown region"
	match status(region_id):
		Status.UNLOCKED:
			return "Already unlocked"
		Status.LOCKED:
			return "Needs an unlocked neighbor"
	if money < unlock_cost():
		return "Not enough money"
	return ""


func can_unlock(region_id: StringName) -> bool:
	return unlock_block_reason(region_id).is_empty()


## Bölgeyi açar ve parayı düşer. Açılamıyorsa hiçbir şey değişmez.
func unlock(region_id: StringName) -> bool:
	if not can_unlock(region_id):
		return false
	money -= unlock_cost()
	_purchased += 1
	_unlocked[region_id] = true
	return true
