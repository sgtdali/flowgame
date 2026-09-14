class_name BlockCatalog
extends RefCounted

## Kullanılabilir tüm istasyon arketiplerinin tek kayıt noktası.
##
## Neden klasör taraması değil de `preload`? `DirAccess` ile res:// taramak
## editörde çalışır ama dışa aktarılmış (.pck) derlemede kırılgandır.
## preload derleme zamanında çözülür — her platformda aynı sonucu verir.

const MADEN_OCAGI := preload("res://data/block_types/maden_ocagi.tres")
const ERITME := preload("res://data/block_types/eritme.tres")
const PRES := preload("res://data/block_types/pres.tres")
const HADDE := preload("res://data/block_types/hadde.tres")
const KESIM := preload("res://data/block_types/kesim.tres")
const MONTAJ := preload("res://data/block_types/montaj.tres")
const KALITE := preload("res://data/block_types/kalite.tres")
const DEPO := preload("res://data/block_types/depo.tres")
const GERI_DONUSUM := preload("res://data/block_types/geri_donusum.tres")
const SEVKIYAT := preload("res://data/block_types/sevkiyat.tres")
const ARGE_LAB := preload("res://data/block_types/arge_lab.tres")
const MADEN_OCAGI_DERIN := preload("res://data/block_types/maden_ocagi_derin.tres")
const DAGITICI := preload("res://data/block_types/dagitici.tres")
const FARM := preload("res://data/block_types/farm.tres")
const MILL := preload("res://data/block_types/mill.tres")
const BAKERY := preload("res://data/block_types/bakery.tres")
const GRANARY := preload("res://data/block_types/granary.tres")
const KALKAN_USTASI := preload("res://data/block_types/kalkan_ustasi.tres")
const KASK_USTASI := preload("res://data/block_types/kask_ustasi.tres")
const KASK_BANTCISI := preload("res://data/block_types/kask_bantcisi.tres")

## Paletteki gösterim sırası — akışın doğal sırasını izler.
const _ORDER: Array = [
	FARM, MILL, BAKERY, GRANARY,
	MADEN_OCAGI, MADEN_OCAGI_DERIN, ERITME, ARGE_LAB, PRES, KALKAN_USTASI,
	KASK_USTASI, KASK_BANTCISI,
	HADDE, KESIM, MONTAJ, KALITE, DEPO, DAGITICI, GERI_DONUSUM, SEVKIYAT,
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
