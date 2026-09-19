class_name PowerLink
extends RefCounted

## Bir jeneratörden bir güç tüketicisine tek yönlü bağlantı.
##
## `SimLink`'ten (malzeme) BİLİNÇLİ olarak ayrı: elektrik tamponlanmaz, anlık
## kapasite olarak akar (bkz. FactorySim._phase_power). Her istasyonun tek bir
## güç portu olduğu için port indeksi yerine doğrudan istasyon id'leriyle
## eşleşir.

var from_id: int = -1
var to_id: int = -1


func _init(p_from_id: int = -1, p_to_id: int = -1) -> void:
	from_id = p_from_id
	to_id = p_to_id


func matches(a_id: int, b_id: int) -> bool:
	return from_id == a_id and to_id == b_id
