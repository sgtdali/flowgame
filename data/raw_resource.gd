class_name RawResource
extends Resource

## Haritadaki bir bölgenin kaynak yatağından çıkan hammadde (kereste, tahıl...).
##
## Her hammadde için bir .tres -> res://data/raw_resources/
## Yataklar tükenmez; her yatak sabit hızda çıkarır (tasarım belgesi,
## "Hammaddeler" tablosu).

@export var id: StringName = &""
@export var display_name: String = "New Resource"
## Yatak başına çıkarım hızı (birim/dk).
@export var extraction_per_minute: int = 0
