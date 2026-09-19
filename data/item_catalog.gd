class_name ItemCatalog
extends RefCounted

## Ürün türlerinin tek kayıt noktası.
##
## Kayıttan yükleme için şart: tamponlarda ürünler id olarak saklanır
## ("levha": 3), geri yüklerken id'den ItemType'a dönmek gerekir.

const CEVHER := preload("res://data/items/cevher.tres")
## Iron Mine'ın çıkardığı işlenmemiş hâl — satılamaz muadili yok, Mine
## Extractor'dan geçmeden Eritme Ocağı'na giremez (bkz. r_cevher.tres, artık
## Mine Extractor'ın reçetesi).
const HAM_CEVHER := preload("res://data/items/ham_cevher.tres")
const KULCE := preload("res://data/items/kulce.tres")
const LEVHA := preload("res://data/items/levha.tres")
## Güç sisteminde satılan tek "ürün" — asla tamponlanmaz, yalnızca fiyatlama
## ve satış muhasebesi (accrued/collect/sold_counts) için ItemType olarak
## var (bkz. FactorySim._run_power_sale).
const ELEKTRIK := preload("res://data/items/elektrik.tres")
## Trade Network'ün ürettiği, Trade Depot'un tükettiği kontrol sinyali —
## asla satılmaz (`base_price = 0`), yalnızca "bu malı Depot'tan geçirebilir
## misin" sorusuna cevap verir (bkz. FactorySim._run_trade_depot).
const TALEP := preload("res://data/items/talep.tres")

const _ALL: Array = [
	CEVHER, HAM_CEVHER, KULCE, LEVHA, ELEKTRIK, TALEP,
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
