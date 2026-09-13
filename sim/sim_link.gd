class_name SimLink
extends RefCounted

## İki istasyon arasındaki tek yönlü bağlantı.
##
## Uçlar GraphEdit düğüm adıyla değil, kalıcı sim id'siyle tutulur.

var from_id: int = -1
var from_port: int = 0
var to_id: int = -1
var to_port: int = 0


func _init(p_from_id: int = -1, p_from_port: int = 0, p_to_id: int = -1, p_to_port: int = 0) -> void:
	from_id = p_from_id
	from_port = p_from_port
	to_id = p_to_id
	to_port = p_to_port


func matches(a_id: int, a_port: int, b_id: int, b_port: int) -> bool:
	return from_id == a_id and from_port == a_port and to_id == b_id and to_port == b_port
