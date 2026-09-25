class_name FactorySites
extends RefCounted

## Arsalardaki fabrikalar (arayüzsüz).
##
## Tasarım: arsaya fabrika kurmak yalnızca bedeli öder; tarif seçilmez, içi boş
## gelir ve oyuncu düğüm editörüyle kurar (FactoryInterior). Yalnızca açık
## bölgede. Fabrika yıkılamaz. Bakım MapFlowSim'de düşülür.

var _regions: RegionState
var _config: MapConfig
## Arsa id -> FactoryInterior. Kurulma sırası korunur (belirlilik).
var _factories: Dictionary = {}


func _init(regions: RegionState, config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_regions = regions
	_config = config


## Arsadaki fabrikanın içi; fabrika yoksa null.
func interior_at(plot_id: StringName) -> FactoryInterior:
	return _factories.get(plot_id, null)


func has_factory(plot_id: StringName) -> bool:
	return _factories.has(plot_id)


func plots() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_factories.keys())
	return out


func count() -> int:
	return _factories.size()


func upkeep_per_minute() -> int:
	return count() * _config.factory_upkeep


## Kurulamıyorsa nedeni (arayüzde gösterilir); kurulabiliyorsa "".
## `ignore_money`: yalnızca para eksikse "" döner (arayüz fiyatı kırmızı gösterir).
func build_block_reason(plot_id: StringName, ignore_money: bool = false) -> String:
	var info: MapPoints.Info = MapPoints.find(plot_id)
	if info == null or info.kind != MapPoints.Kind.FACTORY_PLOT:
		return "Factories can only be built on plots"
	if not _regions.is_unlocked(info.region_id):
		var region: RegionData = RegionCatalog.find_by_id(info.region_id)
		return "%s is locked" % (region.display_name if region != null else String(info.region_id))
	if _factories.has(plot_id):
		return "A factory is already built here"
	if not ignore_money and not _regions.wallet.can_afford(_config.factory_cost):
		return "Not enough money"
	return ""


func build(plot_id: StringName) -> bool:
	if not build_block_reason(plot_id).is_empty():
		return false
	_regions.wallet.spend(_config.factory_cost)
	_factories[plot_id] = FactoryInterior.new(_config)
	return true
