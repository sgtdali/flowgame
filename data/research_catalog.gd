class_name ResearchCatalog
extends RefCounted

## Araştırma ağacının tek kayıt noktası.
##
## Sıra, ağaçtaki gösterim sırasıdır. Bağımlılık `requires` alanından gelir,
## listedeki sıradan değil — düğümleri yeniden sıralamak ağacı bozmaz.

const PRESLEME := preload("res://data/research/presleme.tres")
const KALKAN_ZANAATI := preload("res://data/research/kalkan_zanaati.tres")
const KASK_ZANAATI := preload("res://data/research/kask_zanaati.tres")
const KASK_BANTLAMA := preload("res://data/research/kask_bantlama.tres")
const HADDELEME := preload("res://data/research/haddeleme.tres")
const KESIM_HATTI := preload("res://data/research/kesim_hatti.tres")
const DEPOLAMA := preload("res://data/research/depolama.tres")
const MONTAJ_HATTI := preload("res://data/research/montaj_hatti.tres")
const KALITE_KONTROL := preload("res://data/research/kalite_kontrol.tres")
const ARGE := preload("res://data/research/arge.tres")
const DERIN_SONDAJ := preload("res://data/research/derin_sondaj.tres")

const _ORDER: Array = [
	PRESLEME, KALKAN_ZANAATI, KASK_ZANAATI, KASK_BANTLAMA, DEPOLAMA,
	HADDELEME, KESIM_HATTI, MONTAJ_HATTI, KALITE_KONTROL, ARGE, DERIN_SONDAJ,
]


static func all() -> Array[ResearchNode]:
	var out: Array[ResearchNode] = []
	out.assign(_ORDER)
	return out


static func find_by_id(node_id: StringName) -> ResearchNode:
	for node: ResearchNode in all():
		if node.id == node_id:
			return node
	return null
