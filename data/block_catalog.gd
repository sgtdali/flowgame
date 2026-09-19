class_name BlockCatalog
extends RefCounted

## Kullanılabilir tüm istasyon arketiplerinin tek kayıt noktası.
##
## Neden klasör taraması değil de `preload`? `DirAccess` ile res:// taramak
## editörde çalışır ama dışa aktarılmış (.pck) derlemede kırılgandır.
## preload derleme zamanında çözülür — her platformda aynı sonucu verir.

const MADEN_OCAGI := preload("res://data/block_types/maden_ocagi.tres")
const MINE_EXTRACTOR := preload("res://data/block_types/mine_extractor.tres")
const ERITME := preload("res://data/block_types/eritme.tres")
const JENERATOR := preload("res://data/block_types/jenerator.tres")
const ELEKTRIK_SATIS := preload("res://data/block_types/elektrik_satis.tres")
const PRES := preload("res://data/block_types/pres.tres")
const SEVKIYAT := preload("res://data/block_types/sevkiyat.tres")
const DAGITICI := preload("res://data/block_types/dagitici.tres")
const TRADE_NETWORK := preload("res://data/block_types/trade_network.tres")
const TRADE_DEPOT := preload("res://data/block_types/trade_depot.tres")

## Eski kayıtlarda görünmesi beklenen, aktif oyundan çıkarılmış kayıt
## türleri — yükleme sırasında sessizce atılırlar (bkz. `is_removed_type_id`).
## v5: tarım istasyonları. v7: zırh/silah üretim zinciri (Guard Press, Helm
## Forge, Helm Bander, Storehouse, Drawbench, Rivet Press, Assembly Press,
## Quality Inspector, Salvage Hearth, Deep Iron Mine, Research Lab) — üç
## aşamalı demir/elektrik akışının dışında kalan, hiçbir araştırmadan artık
## açılamayan içerik.
const REMOVED_TYPE_IDS: Array[String] = [
	"farm", "mill", "bakery", "granary",
	"kalkan_ustasi", "kask_ustasi", "kask_bantcisi", "depo", "hadde", "kesim",
	"montaj", "kalite", "geri_donusum", "maden_ocagi_derin", "arge_lab",
	"komur_ocagi",
]

## Paletteki gösterim sırası — akışın doğal sırasını izler.
const _ORDER: Array = [
	MADEN_OCAGI, MINE_EXTRACTOR, ERITME, JENERATOR, ELEKTRIK_SATIS, PRES,
	DAGITICI, TRADE_NETWORK, TRADE_DEPOT, SEVKIYAT,
]


static func all() -> Array[BlockType]:
	var out: Array[BlockType] = []
	out.assign(_ORDER)
	return out


## Kaydedilmiş bir akış yüklenirken tip kimliğini arketipe çevirir.
static func find_by_id(type_id: StringName) -> BlockType:
	for type: BlockType in all():
		if type.id == type_id:
			return type
	return null


static func is_removed_type_id(type_id: StringName) -> bool:
	return REMOVED_TYPE_IDS.has(String(type_id))
