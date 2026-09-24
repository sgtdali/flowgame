class_name FactorySites
extends RefCounted

## Arsalardaki geçici sabit fabrikalar (arayüzsüz).
##
## Tasarım: boş arsaya kurulur, kurarken tarif seçilir ve değişmez; yalnızca
## açık bölgede. Görev 04: fabrika yıkılamaz. Bakım MapFlowSim'de düşülür.

var _regions: RegionState
var _config: MapConfig
## Arsa id -> ProcessRecipe. Kurulma sırası korunur (belirlilik).
var _recipes: Dictionary = {}


func _init(regions: RegionState, config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_regions = regions
	_config = config


func recipe_at(plot_id: StringName) -> ProcessRecipe:
	return _recipes.get(plot_id, null)


func plots() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_recipes.keys())
	return out


func count() -> int:
	return _recipes.size()


func upkeep_per_minute() -> int:
	return count() * _config.factory_upkeep


## Kurulamıyorsa nedeni (arayüzde gösterilir); kurulabiliyorsa "".
func build_block_reason(plot_id: StringName, recipe: ProcessRecipe) -> String:
	var info: MapPoints.Info = MapPoints.find(plot_id)
	if info == null or info.kind != MapPoints.Kind.FACTORY_PLOT:
		return "Factories can only be built on plots"
	if not _regions.is_unlocked(info.region_id):
		var region: RegionData = RegionCatalog.find_by_id(info.region_id)
		return "%s is locked" % (region.display_name if region != null else String(info.region_id))
	if _recipes.has(plot_id):
		return "A factory is already built here"
	if not _config.factory_recipes.has(recipe):
		return "Unknown recipe"
	if not _regions.wallet.can_afford(_config.factory_cost):
		return "Not enough money"
	return ""


func build(plot_id: StringName, recipe: ProcessRecipe) -> bool:
	if not build_block_reason(plot_id, recipe).is_empty():
		return false
	_regions.wallet.spend(_config.factory_cost)
	_recipes[plot_id] = recipe
	return true
