@tool
class_name Good
extends ItemType

## Haritada taşınan bir mal (tomruk, kereste, un...). Hammaddeler (RawResource)
## bundan türer. Her mal için bir .tres -> res://data/goods/ (hammaddeler
## res://data/raw_resources/).
##
## Eski oyunun ItemType'ından türer: böylece aynı mal fabrika içindeki düğüm
## editöründe de (tarif, port, kuyruk) doğrudan kullanılır. id, display_name,
## color ve icon_char ItemType'tan gelir; ItemType.base_price haritada kullanılmaz.
##
## @tool: haritadaki noktalar editörde de çizilir ve mal adını okur.

## Şehre satış fiyatı (birim başına). 0 = şehre satılmaz (ham mal satılmaz).
@export var city_price: int = 0
