class_name RegionData
extends Resource

## Haritadaki bir bölgenin oyun verisi.
##
## Her bölge için bir .tres -> res://data/regions/
## Bölgenin şekli burada DEĞİL: features/worldmap/RegionMap.tscn içindeki
## çizimde durur (kullanıcı elle çizer). Çizimdeki bölge düğümü bu veriyi
## `RegionView.data` ile gösterir.

@export var id: StringName = &""
@export var display_name: String = "New Region"
## Bölgedeki kaynak yatakları. Aynı hammadde iki kez yazılırsa iki yatak demektir.
@export var resources: Array[RawResource] = []
## Bölgedeki şehirlerin adları; sırası nokta kimliğini verir (City1, City2...).
## Fabrikaların yeri sabit değildir: açık bölgede oyuncunun seçtiği yere kurulur.
@export var city_names: Array[String] = []
## Komşu bölgelerin id'leri. Karşılıklı olmalı ve çizimde gerçekten
## değmeli (region_test kontrol eder). Bölge açmada komşuluk şartı bunu kullanır.
@export var neighbors: Array[StringName] = []
@export var starts_unlocked: bool = false


func has_city() -> bool:
	return not city_names.is_empty()
