class_name ResearchCatalog
extends RefCounted

## Araştırma ağacının tek kayıt noktası.
##
## Sıra, ağaçtaki gösterim sırasıdır. Bağımlılık `requires` alanından gelir,
## listedeki sıradan değil — düğümleri yeniden sıralamak ağacı bozmaz.

const PRESLEME := preload("res://data/research/presleme.tres")
const GENISLEME_1 := preload("res://data/research/genisleme_1.tres")
const HADDELEME := preload("res://data/research/haddeleme.tres")
const KESIM_HATTI := preload("res://data/research/kesim_hatti.tres")
const DEPOLAMA := preload("res://data/research/depolama.tres")
const GENISLEME_2 := preload("res://data/research/genisleme_2.tres")
const MONTAJ_HATTI := preload("res://data/research/montaj_hatti.tres")
const KALITE_KONTROL := preload("res://data/research/kalite_kontrol.tres")
const ARGE := preload("res://data/research/arge.tres")
const DERIN_SONDAJ := preload("res://data/research/derin_sondaj.tres")

const _ORDER: Array = [
	PRESLEME, GENISLEME_1, HADDELEME, KESIM_HATTI, DEPOLAMA,
	GENISLEME_2, MONTAJ_HATTI, KALITE_KONTROL, ARGE, DERIN_SONDAJ,
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
