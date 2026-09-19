class_name ResearchCatalog
extends RefCounted

## Araştırma ağacının tek kayıt noktası.
##
## Sıra, ağaçtaki gösterim sırasıdır. Bağımlılık `requires` alanından gelir,
## listedeki sıradan değil — düğümleri yeniden sıralamak ağacı bozmaz.

const ELEKTRIFIKASYON := preload("res://data/research/elektrifikasyon.tres")
const PRESLEME := preload("res://data/research/presleme.tres")
const OTOMASYON := preload("res://data/research/otomasyon.tres")

const _ORDER: Array = [
	ELEKTRIFIKASYON, PRESLEME, OTOMASYON,
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
