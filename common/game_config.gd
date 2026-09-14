class_name GameConfig
extends RefCounted

## Denge sayılarının TEK yeri.
##
## Tasarım belgesindeki en büyük risk "60 dakikalık tempo ilk denemede
## tutmaz". Azaltması: ayarlanacak her sayı burada toplanır, koda dağılmaz.
## Denge koşumu (Faz 2) bu değerleri ölçüp ayarlamak için kullanılacak.

## Simülasyonun temel hızı. Tüm süreler tick cinsinden sayılır.
const TICKS_PER_SECOND: int = 10

## The first workers and food reserve let both craft and food routes start.
const START_WORKERS: int = 5
const START_FOOD: int = 30
const RECRUIT_FOOD_COST: int = 15
const FOOD_PER_WORKER_PER_MINUTE: int = 1

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
		return "%.1f hr" % (seconds / 3600.0)
	if seconds >= 60.0:
		return "%.1f min" % (seconds / 60.0)
	return "%.1f sec" % seconds


## Binlik ayraçlı para metni. Para int tutulur, biçimlendirme sunumda yapılır.
static func format_money(amount: int) -> String:
	var digits: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if amount < 0 else "") + out
