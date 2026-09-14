class_name Recipe
extends Resource

## Bir istasyonun ne tükettiği, ne ürettiği ve ne kadar sürdüğü.
##
## İstasyonun portları bu reçeteden TÜRETİLİR — elle yazılmaz.
## Montaj'ın iki girişi olması, buradaki iki girdiden gelir.

@export var id: StringName = &""
@export var inputs: Array[RecipeSlot] = []
@export var outputs: Array[RecipeSlot] = []

## Üretim süresi TICK cinsinden — float saniye değil.
##
## Simülasyon tamsayı tick sayar. Float süre birikimli yuvarlama hatası
## yapar ve aynı kaydın iki koşumu farklı sonuç verir; determinizm kırılır.
@export var duration_ticks: int = 10


## Sunum için: tick'i okunabilir süreye çevirir.
func duration_text(ticks_per_second: int) -> String:
	var seconds: float = float(duration_ticks) / float(maxi(1, ticks_per_second))
	if seconds >= 60.0:
		return "%.1f min" % (seconds / 60.0)
	return "%.1f sec" % seconds


func input_text() -> String:
	return _join(inputs)


func output_text() -> String:
	return _join(outputs)


static func _join(slots: Array[RecipeSlot]) -> String:
	if slots.is_empty():
		return "—"
	var parts: PackedStringArray = PackedStringArray()
	for slot: RecipeSlot in slots:
		parts.append(slot.label())
	return " + ".join(parts)
