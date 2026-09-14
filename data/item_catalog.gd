class_name ItemCatalog
extends RefCounted

## Ürün türlerinin tek kayıt noktası.
##
## Kayıttan yükleme için şart: tamponlarda ürünler id olarak saklanır
## ("levha": 3), geri yüklerken id'den ItemType'a dönmek gerekir.

const CEVHER := preload("res://data/items/cevher.tres")
const KULCE := preload("res://data/items/kulce.tres")
const LEVHA := preload("res://data/items/levha.tres")
const CUBUK := preload("res://data/items/cubuk.tres")
const VIDA := preload("res://data/items/vida.tres")
const GOVDE := preload("res://data/items/govde.tres")
const HURDA := preload("res://data/items/hurda.tres")
const WHEAT := preload("res://data/items/wheat.tres")
const FLOUR := preload("res://data/items/flour.tres")
const BREAD := preload("res://data/items/bread.tres")
const KALKAN := preload("res://data/items/kalkan.tres")
const KASK := preload("res://data/items/kask.tres")
const BANTLI_KASK := preload("res://data/items/bantli_kask.tres")

const _ALL: Array = [
	CEVHER, KULCE, LEVHA, CUBUK, VIDA, GOVDE, HURDA, WHEAT, FLOUR, BREAD,
	KALKAN, KASK, BANTLI_KASK,
]

## id -> ItemType. İlk erişimde kurulur; O(1) arama.
static var _by_id: Dictionary = {}


static func all() -> Array[ItemType]:
	var out: Array[ItemType] = []
	out.assign(_ALL)
	return out


static func find_by_id(item_id: StringName) -> ItemType:
	if _by_id.is_empty():
		for item: ItemType in all():
			_by_id[item.id] = item
	return _by_id.get(item_id, null)
