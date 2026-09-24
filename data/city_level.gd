class_name CityLevel
extends Resource

## Bir şehir seviyesinin talebi (köy, kasaba...). Her seviye için bir .tres ->
## res://data/city_levels/
##
## Doygunluk (tasarım belgesi): bir oyun dakikası içinde satılan miktar,
## talebin saturation_thresholds[i] katını geçince fiyat
## saturation_multipliers[i + 1] ile çarpılır. Örn. eşikler [1.0, 1.5],
## çarpanlar [1.0, 0.5, 0.1]: %100'e kadar tam, %100–150 yarı, üstü %10.

@export var id: StringName = &""
@export var display_name: String = "New Level"
@export var demand_goods: Array[Good] = []
## Dakikalık talep; demand_goods ile aynı sırada.
@export var demand_per_minute: Array[int] = []
@export var saturation_thresholds: Array[float] = [1.0, 1.5]
@export var saturation_multipliers: Array[float] = [1.0, 0.5, 0.1]


func demand_for(good: Good) -> int:
	var index: int = demand_goods.find(good)
	return demand_per_minute[index] if index >= 0 and index < demand_per_minute.size() else 0
