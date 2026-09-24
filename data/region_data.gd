class_name RegionData
extends Resource

## Haritadaki bir bölgenin oyun verisi.
##
## Her bölge için bir .tres -> res://data/regions/
## Bölgenin şekli burada DEĞİL: features/worldmap/RegionMap.tscn içindeki
## çizimde durur (kullanıcı elle çizer). Çizimdeki bölge düğümü bu veriyi
## `RegionView.data` ile gösterir.

enum Terrain { FLAT, HILLY, MOUNTAINOUS }

@export var id: StringName = &""
@export var display_name: String = "New Region"
## Arazi ileride hat maliyetini ve kapasitesini etkileyecek (tasarım belgesi).
@export var terrain: Terrain = Terrain.FLAT
## Bölgedeki kaynak yatakları (1–3). Aynı hammadde iki kez yazılırsa iki yatak demektir.
@export var resources: Array[RawResource] = []
## Kurulabilecek fabrika sayısı (2–4).
@export var factory_slots: int = 2
## Boş = bölgede şehir yok.
@export var city_name: String = ""
## Komşu bölgelerin id'leri. Karşılıklı olmalı ve çizimde gerçekten
## değmeli (region_test kontrol eder). Bölge açmada komşuluk şartı bunu kullanır.
@export var neighbors: Array[StringName] = []
@export var starts_unlocked: bool = false


func has_city() -> bool:
	return not city_name.is_empty()


static func terrain_name(value: Terrain) -> String:
	match value:
		Terrain.HILLY:
			return "Hilly"
		Terrain.MOUNTAINOUS:
			return "Mountainous"
	return "Flat"
