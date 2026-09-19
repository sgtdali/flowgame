class_name Recipe
extends Resource

## Bir istasyonun ne tükettiği, ne ürettiği ve ne kadar sürdüğü.
##
## İstasyonun portları bu reçeteden TÜRETİLİR — elle yazılmaz.
## Montaj'ın iki girişi olması, buradaki iki girdiden gelir.

@export var id: StringName = &""
@export var inputs: Array[RecipeSlot] = []
@export var outputs: Array[RecipeSlot] = []

## Üretim süresi TICK cinsinden.
##
## KESİRLİ olabilir (ör. 1.667) — simülasyon artık `SimStation.progress_ticks`
## üzerinden kesirli bir biriktiriciyle çalışıyor (bkz. orada) ve her
## döngüden kalan küsuratı bir sonrakine taşıyor, o yüzden float'ın yuvarlama
## hatası birikmiyor. Bu, "dakikada tam X adet" gibi hedefleri
## `TICKS_PER_SECOND` ile tam bölünmeyen tick sayılarında da mümkün kılar.
@export var duration_ticks: float = 10.0


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
