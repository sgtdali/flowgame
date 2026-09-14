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
## Erken oyun hat denemesi (bkz. DESIGN.md D29): Maden+Eritme hattı tek
## başına, gıda zincirini hiç kurmadan birkaç DAKİKA (bazı stratejilerde
## ~10 dk'ya kadar — araştırma erişiminin zamanlayıcı güvenlik ağı, D27)
## çalışabilmeli; eskiden 30 idi ve 5 işçi * 1 gıda/dk upkeep ile 6 dakikada
## tükenip istasyonları AÇ (HUNGRY) durdururdu — görünmeyen bir darboğazdı.
## 300, ~60 dakikalık bir tampon verir: kalıcı olarak SINIRSIZ değil, ama bu
## kısa deneyin süresini rahatça kapsar.
const START_FOOD: int = 300
const RECRUIT_FOOD_COST: int = 15
const FOOD_PER_WORKER_PER_MINUTE: int = 1

## Başlangıç parası — ilk hattı kurmaya yetmeli, fazlası olmamalı.
const START_MONEY: int = 1000

## Erken oyun deneyi: kaynak/kapasite döngüsü (bkz. DESIGN.md D27).
##
## Araştırmaya gecikmeden ÖNCE oyuncu en az bu kadar geliştirme satın almalı.
## Yalnızca bunu şart koşmak, hiç geliştirme almayan bir oyuncuyu SONSUZA DEK
## kilitlerdi — bu yüzden RESEARCH_FALLBACK_TICKS ikinci bir (uzun, tek
## başına yeterli olmayan) yol sunar.
const MIN_UPGRADES_FOR_RESEARCH: int = 1

## Yukarıdaki şart hiç karşılanmazsa araştırmanın en geç açılacağı tick
## sayısı — "yalnızca uzun bir zamanlayıcıyla geciktirme" kuralının GÜVENLİK
## AĞI, birincil yol değil.
const RESEARCH_FALLBACK_TICKS: int = TICKS_PER_SECOND * 60 * 10

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
