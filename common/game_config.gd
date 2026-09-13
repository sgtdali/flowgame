class_name GameConfig
extends RefCounted

## Denge sayılarının TEK yeri.
##
## Tasarım belgesindeki en büyük risk "60 dakikalık tempo ilk denemede
## tutmaz". Azaltması: ayarlanacak her sayı burada toplanır, koda dağılmaz.
## Denge koşumu (Faz 2) bu değerleri ölçüp ayarlamak için kullanılacak.

## Simülasyonun temel hızı. Tüm süreler tick cinsinden sayılır.
const TICKS_PER_SECOND: int = 10

## Oyuncunun başlangıçtaki istasyon slotu sayısı.
const START_SLOTS: int = 5

## Başlangıç parası — ilk hattı kurmaya yetmeli, fazlası olmamalı.
const START_MONEY: int = 1000

## Bir karede işlenebilecek en fazla tick.
##
## Tavan ZORUNLU: bir kare takılırsa tick borcu birikir, oyun kendini daha da
## yavaşlatır ve geri dönemez ("spiral of death").
const MAX_TICKS_PER_FRAME: int = 100


## Tick sayısını okunabilir süreye çevirir. Sunum katmanının tek biçimlendiricisi.
static func format_ticks(ticks: int) -> String:
	var seconds: float = float(ticks) / float(TICKS_PER_SECOND)
	if seconds >= 3600.0:
		return "%.1f sa" % (seconds / 3600.0)
	if seconds >= 60.0:
		return "%.1f dk" % (seconds / 60.0)
	return "%.1f sn" % seconds
