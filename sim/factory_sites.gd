class_name FactorySites
extends RefCounted

## Haritadaki fabrikalar (arayüzsüz).
##
## Tasarım: fabrika açık bir bölgenin içinde oyuncunun seçtiği yere kurulur;
## sabit arsa yoktur. Kurmak yalnızca bedeli öder; içi boş gelir ve oyuncu
## düğüm editörüyle kurar (FactoryInterior). Fabrika yıkılamaz. Yerini arayüz
## tutar; kural tarafı yalnızca hangi bölgede olduğunu bilir. Kimlik
## "<bölge id>/Factory<n>", n kurulma sırasıdır (görev 08, K3). Bakım MapFlowSim'de düşülür.

var _regions: RegionState
var _config: MapConfig
## Fabrika id -> FactoryInterior. Kurulma sırası korunur (belirlilik).
var _factories: Dictionary = {}
## Fabrika id -> bölge id.
var _region_of: Dictionary = {}
var _built: int = 0


func _init(regions: RegionState, config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_regions = regions
	_config = config


## Fabrikanın içi; bu kimlikte fabrika yoksa null.
func interior_at(factory_id: StringName) -> FactoryInterior:
	return _factories.get(factory_id, null)


func has_factory(factory_id: StringName) -> bool:
	return _factories.has(factory_id)


## Kurulu fabrikaların kimlikleri, kurulma sırasıyla.
func plots() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_factories.keys())
	return out


func region_of(factory_id: StringName) -> StringName:
	return _region_of.get(factory_id, &"")


## Bir sonraki fabrikanın kurulma sırası (adı "Factory <n>").
func next_number() -> int:
	return _built + 1


func count() -> int:
	return _factories.size()


func upkeep_per_minute() -> int:
	return count() * _config.factory_upkeep


## `region_id` bölgesine kurulamıyorsa nedeni (arayüzde gösterilir); kurulabiliyorsa "".
## `ignore_money`: yalnızca para eksikse "" döner (arayüz fiyatı kırmızı gösterir).
func build_block_reason(region_id: StringName, ignore_money: bool = false) -> String:
	var region: RegionData = RegionCatalog.find_by_id(region_id)
	if region == null:
		return "Factories can only be built inside a region"
	if not _regions.is_unlocked(region_id):
		return "%s is locked" % region.display_name
	if not ignore_money and not _regions.wallet.can_afford(_config.factory_cost):
		return "Not enough money"
	return ""


## Bölgeye fabrika kurar; yeni fabrikanın kimliğini döndürür (kurulamazsa &"").
func build(region_id: StringName) -> StringName:
	if not build_block_reason(region_id).is_empty():
		return &""
	_regions.wallet.spend(_config.factory_cost)
	_built += 1
	var factory_id: StringName = StringName("%s/Factory%d" % [region_id, _built])
	_factories[factory_id] = FactoryInterior.new(_config)
	_region_of[factory_id] = region_id
	return factory_id
