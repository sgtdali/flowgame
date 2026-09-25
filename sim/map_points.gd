class_name MapPoints
extends RefCounted

## Harita noktalarının kaydı (arayüzsüz): kimlik, tür, hammadde.
##
## Noktalar bölge verisinden türetilir; adlandırma, çizim sahnesini üreten
## tools/point_placer.gd ile aynıdır: "<bölge id>/Site<n>", "/City<n>". Fabrikalar
## burada değil, oyunda kurulunca FactorySites'ta kayıtlıdır ("<bölge id>/Factory<n>").
## point_test.gd sahnedeki noktaların bu kayıtla birebir aynı olduğunu doğrular.

## Sıra sahnedeki MapPoint.Kind ile aynı (sahnede sayı olarak saklanır).
enum Kind { RESOURCE_SITE, FACTORY, CITY }


class Info:
	var id: StringName
	var region_id: StringName
	var kind: Kind
	## Yalnızca ham madde alanında.
	var resource: RawResource

	func _init(point_id: StringName, region: StringName, point_kind: Kind,
			point_resource: RawResource = null) -> void:
		id = point_id
		region_id = region
		kind = point_kind
		resource = point_resource


static var _by_id: Dictionary = {}
static var _all: Array[Info] = []


static func all() -> Array[Info]:
	_ensure()
	return _all.duplicate()


static func find(point_id: StringName) -> Info:
	_ensure()
	return _by_id.get(point_id, null)


static func for_region(region_id: StringName) -> Array[Info]:
	var out: Array[Info] = []
	for info: Info in all():
		if info.region_id == region_id:
			out.append(info)
	return out


static func _ensure() -> void:
	if not _all.is_empty():
		return
	for region: RegionData in RegionCatalog.all():
		for i: int in region.city_names.size():
			_add(Info.new(_id(region, "City%d" % (i + 1)), region.id, Kind.CITY))
		for i: int in region.resources.size():
			_add(Info.new(_id(region, "Site%d" % (i + 1)), region.id, Kind.RESOURCE_SITE,
					region.resources[i]))


static func _add(info: Info) -> void:
	_all.append(info)
	_by_id[info.id] = info


static func _id(region: RegionData, point_name: String) -> StringName:
	return StringName("%s/%s" % [region.id, point_name])
