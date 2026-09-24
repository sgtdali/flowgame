@tool
class_name Good
extends Resource

## Haritada taşınan bir mal (tomruk, kereste, un...). Hammaddeler (RawResource)
## bundan türer. Her mal için bir .tres -> res://data/goods/ (hammaddeler
## res://data/raw_resources/).
##
## @tool: haritadaki noktalar editörde de çizilir ve mal adını okur.

@export var id: StringName = &""
@export var display_name: String = "New Good"
## Şehre satış fiyatı (birim başına). 0 = şehre satılmaz (ham mal satılmaz).
@export var city_price: int = 0
