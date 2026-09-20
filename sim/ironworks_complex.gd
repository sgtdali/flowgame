class_name IronworksComplex
extends RefCounted

## Kompleks, istasyonların yerine geçen yeni bir üretici değildir. Mevcut
## istasyonların sahipliği, ortak tamponları ve ortak güç altyapısıdır.
enum Strategy { INGOT_FOCUS, BALANCED, PLATE_FOCUS }

var id: int = -1
var display_name: String = "Ironworks 01"
var station_ids: Array[int] = []
var material_bus: Dictionary = {}
var material_capacity: int = 100
## "station_id:port" -> true. Bir giriş/çıkış aynı anda ya doğrudan ya bus'tır.
var shared_inputs: Dictionary = {}
var shared_outputs: Dictionary = {}
var power_bus_members: Dictionary = {}
var power_source_ids: Array[int] = []
var strategy: Strategy = Strategy.BALANCED


func _init(p_id: int = -1, p_name: String = "") -> void:
	id = p_id
	display_name = p_name if not p_name.is_empty() else "Ironworks %02d" % p_id


static func port_key(station_id: int, port: int) -> String:
	return "%d:%d" % [station_id, port]


func contains(station_id: int) -> bool:
	return station_ids.has(station_id)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"stations": station_ids.duplicate(),
		"bus": FactorySim._ids_to_strings(material_bus),
		"capacity": material_capacity,
		"shared_inputs": shared_inputs.duplicate(),
		"shared_outputs": shared_outputs.duplicate(),
		"power_members": power_bus_members.duplicate(),
		"power_sources": power_source_ids.duplicate(),
		"strategy": int(strategy),
	}


func load_dict(data: Dictionary) -> void:
	display_name = String(data.get("name", display_name))
	station_ids.clear()
	for value: Variant in data.get("stations", []):
		station_ids.append(int(value))
	station_ids.sort()
	material_bus = FactorySim._strings_to_ids(data.get("bus", {}))
	material_capacity = maxi(1, int(data.get("capacity", 100)))
	shared_inputs = data.get("shared_inputs", {}).duplicate()
	shared_outputs = data.get("shared_outputs", {}).duplicate()
	power_bus_members = data.get("power_members", {}).duplicate()
	power_source_ids.clear()
	for value: Variant in data.get("power_sources", []):
		power_source_ids.append(int(value))
	power_source_ids.sort()
	strategy = clampi(int(data.get("strategy", Strategy.BALANCED)), Strategy.INGOT_FOCUS, Strategy.PLATE_FOCUS)


func fingerprint() -> String:
	var station_parts: PackedStringArray = PackedStringArray()
	for station_id: int in station_ids:
		station_parts.append(str(station_id))
	var inputs: Array = shared_inputs.keys()
	var outputs: Array = shared_outputs.keys()
	inputs.sort()
	outputs.sort()
	return "%d:%s:%s:i%s:o%s:p%s:s%d" % [
		id, display_name, FactorySim._stable_buffer(material_bus), ",".join(inputs),
		",".join(outputs), ",".join(power_source_ids), int(strategy),
	]
