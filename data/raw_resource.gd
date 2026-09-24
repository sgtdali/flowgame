class_name RawResource
extends Resource

## Haritadaki bir ham madde alanından çıkan hammadde (tomruk, buğday...).
##
## Her hammadde için bir .tres -> res://data/raw_resources/
## Yataklar tükenmez; her yatak sabit hızda çıkarır (tasarım belgesi,
## "Hammaddeler" tablosu). Ham mal şehre satılmaz; fabrikada işlenir.

## Hammaddenin çıktığı alan türü; haritadaki noktanın adı ve simgesi bundan gelir.
enum SiteKind { FOREST, FARM, MINE }

@export var id: StringName = &""
@export var display_name: String = "New Resource"
@export var site_kind: SiteKind = SiteKind.FOREST
## Yatak başına çıkarım hızı (birim/dk).
@export var extraction_per_minute: int = 0


static func site_name(kind: SiteKind) -> String:
	match kind:
		SiteKind.FARM:
			return "Farm"
		SiteKind.MINE:
			return "Mine"
	return "Forest"
