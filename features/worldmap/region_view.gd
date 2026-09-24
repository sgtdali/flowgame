class_name RegionView
extends Area2D

## Çizimdeki bir bölge düğümü (RegionMap.tscn → Area1, Area2...).
##
## Şekil, kullanıcının bu düğümün altına elle çizdiği Polygon2D'lerdir;
## birden fazla olabilir (ada, kopuk parça). Oyun verisi `data`'dadır.

@export var data: RegionData


## Bölgenin parçaları, bu düğümün yerel koordinatında.
## Polygon2D'nin kendi kayması (position vb.) hesaba katılır.
func get_polygons() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for child: Node in get_children():
		var shape: Polygon2D = child as Polygon2D
		if shape != null and shape.polygon.size() >= 3:
			out.append(shape.transform * shape.polygon)
	return out
