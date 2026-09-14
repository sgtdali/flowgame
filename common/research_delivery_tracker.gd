class_name ResearchDeliveryTracker
extends RefCounted

## Ar-Ge Sarayı'na akıtılan her ürün için AYRI hız ölçümü.
##
## NEDEN AYRI SINIF (satış hızıyla karıştırılmaz): `SalesRateTracker` aynı
## desenle çalışır ama parayla ağırlıklandırır (`base_price`). Araştırma
## takibi parayı bilmiyor — yalnızca "bu ürün laboratuvara ne hızda geliyor"
## sorusuna cevap veriyor. `FactorySim.research_counts`, `sold_counts`'tan
## ZATEN ayrı tutuluyor (bkz. `_run_research` / `_run_sink`) — burası o
## ayrımı KORUYOR, karıştırmıyor.
##
## `RateMeter`'ın (zaten çözülmüş dalgalanma sorunu, bkz. o dosyanın notu)
## üstüne yalnızca üç OKUMA durumu ekler; algoritmasına dokunmaz:
##   MEASURING — henüz güvenilir bir hız için yeterli olay yok
##   STOPPED   — bir süredir hiç teslimat yok (eski hız donuk kalmaz)
##   VARIABLE  — olaylar arası süre normalden belirgin uzadı, ETA güvenilmez
##   STABLE    — hız ve ETA gösterilebilir

enum Status { MEASURING, STOPPED, VARIABLE, STABLE }

## Güvenilir bir hız için en az kaç teslimat olayı görülmeli.
const MIN_EVENTS_FOR_CONFIDENCE: int = 3

## "Durdu" sayılması için: ortalama aralığın kaç katı VEYA en az kaç tick
## geçmeli (ikisinin büyüğü — yeni başlayan yavaş bir akışı erken "durdu"
## sanmamak için mutlak bir taban da var).
const STOPPED_INTERVAL_MULTIPLIER: float = 4.0
const STOPPED_MIN_TICKS: int = GameConfig.TICKS_PER_SECOND * 12

## "Değişken" sayılması için: ortalama aralığın kaç katını geçince ETA'ya
## artık güvenilmez (STOPPED eşiğinden düşük olmalı).
const VARIABLE_INTERVAL_MULTIPLIER: float = 1.75

var _meters: Dictionary = {}   # item_id -> RateMeter


## Her karede çağrılır. `research_counts`: FactorySim'in tuttuğu kümülatif
## sözlük — ürün id'si -> laboratuvara şimdiye kadar akıtılan toplam adet.
func sample(tick: int, research_counts: Dictionary) -> void:
	for item_id: StringName in research_counts:
		if not _meters.has(item_id):
			_meters[item_id] = RateMeter.new()
		(_meters[item_id] as RateMeter).sample(tick, int(research_counts[item_id]))


func status(item_id: StringName) -> Status:
	var meter: RateMeter = _meters.get(item_id)
	if meter == null or not meter.has_measurement() or meter.event_count() < MIN_EVENTS_FOR_CONFIDENCE:
		return Status.MEASURING
	var since: int = meter.ticks_since_last_event()
	var stopped_at: float = maxf(float(STOPPED_MIN_TICKS), meter.avg_interval_ticks() * STOPPED_INTERVAL_MULTIPLIER)
	if float(since) >= stopped_at:
		return Status.STOPPED
	if float(since) >= meter.avg_interval_ticks() * VARIABLE_INTERVAL_MULTIPLIER:
		return Status.VARIABLE
	return Status.STABLE


func per_minute(item_id: StringName) -> float:
	var meter: RateMeter = _meters.get(item_id)
	return meter.per_minute() if meter != null else 0.0


## Kalan miktarı bu hızla bitirmek kaç dakika sürer. Hız güvenilir değilse
## (bkz. `status`) -1.0 döner — çağıran kesin bir sayı YAZMAMALI, "ölçülüyor"
## / "akış değişken" / "teslimat yok" göstermeli.
func eta_minutes(item_id: StringName, remaining: int) -> float:
	if remaining <= 0:
		return 0.0
	if status(item_id) != Status.STABLE:
		return -1.0
	var rate: float = per_minute(item_id)
	if rate <= 0.0:
		return -1.0
	return float(remaining) / rate


func reset() -> void:
	_meters.clear()
