class_name RateMeter
extends RefCounted

## Kayan pencere üzerinden "dakikada kaç" ölçer.
##
## Kümülatif bir sayacın (üretilen toplam parça, toplam gelir) artış hızını
## verir. Anlık değil, üretim OLAYLARI ARASINDAKİ SÜRENİN ortalamasından —
## anlık türev tick tick zıplar ve okunmaz olur.
##
## MİMARİ: Bu bir SUNUM aracıdır, simülasyonun parçası değil. Simülasyon
## kümülatif sayaçları tutar; hıza çevirmek ekranın işi. Bu yüzden kayıtta
## yer almaz — yükledikten birkaç saniye sonra kendi kendine dolar.
##
## NEDEN OLAY ARALIĞI, SÜREKLİ TÜREV DEĞİL: İlk iki deneme başarısız oldu.
## (1) Sabit pencere (boxcar filtre): üretim periyodu pencereye tam
##     bölünmezse, kenar her üretim anını geçtiğinde sayaç sert basamak
##     atlıyordu (42.86/dk gerçek ortalama, görüntü 40↔44 zıplıyordu).
## (2) Üstel yumuşatılmış türev: kenar sıçraması gitti ama üretim ayrık
##     olduğundan yumuşatılmış değer her karede sürekli sürünüyordu.
## (3) Olay aralığı ortalaması — ama aralığı BİRİM BAŞINA (ticks/delta)
##     tutmuştuk. Bir satışta 10₺ birden gelince "birim başına aralık" 2.0
##     tick'e düşüyordu; bunu son olaydan bu yana geçen HAM tick sayısıyla
##     (0-20 arası) karşılaştırınca an be an "çok beklendi" sanıp sönmeye
##     başlıyordu — satıştan hemen sonra 300₺/dk, sonraki satışa dek sürekli
##     düşüp 31₺/dk'ya iniyor, sonra tekrar sıçrıyordu. Birim uyuşmazlığıydı:
##     "1₺ üretmek kaç tick sürer" ile "son olaydan bu yana kaç tick geçti"
##     karşılaştırılamaz — biri normalize, diğeri ham.
##
## Doğru model: OLAYLAR ARASI HAM SÜREYİ ve olay başına düşen MİKTARI ayrı
## ayrı ortalamak, sonra ikisini bölmek. Böylece "ne kadar beklendiği" ile
## "normalde ne kadar beklenmesi gerektiği" aynı birimde (ham tick)
## karşılaştırılır. Bir hız göstergesi tekerlek dönüşleri arasındaki süreden
## hız kestirir; konumu sürekli türevleyip gürültüyü yumuşatmaya çalışmaz.

## Ardışık olay ölçümlerinin üstel ortalaması ne kadar hızlı güncellensin.
## Küçük değer = çok sayıda geçmiş olayın ortalaması (sakin, geç tepki).
const EVENT_ALPHA: float = 0.3

var _has_total: bool = false
var _last_total: int = 0

## Son üretim OLAYININ görüldüğü tick (total'ın gerçekten arttığı an).
var _last_event_tick: int = 0

## En son sample() çağrısındaki tick — "şu an" için. Üretim olmasa da her
## karede güncellenir; uzun süredir olay yoksa hızın sıfıra sönmesini sağlar.
var _last_seen_tick: int = 0

## Ardışık olaylar arasındaki HAM sürenin (tick) üstel ortalaması.
## -1 = henüz hiç olay görülmedi.
var _avg_interval: float = -1.0

## Bir olayda tipik olarak ne kadar artış olduğunun üstel ortalaması
## (ör. tek satışta kaç ₺, tek üretimde kaç adet).
var _avg_delta: float = 0.0

## Şimdiye kadar görülen OLAY sayısı (delta>0 olan sample çağrıları).
## Araştırma takip panelinin "ölçülüyor" / "kararlı" ayrımı için —
## yalnızca 1-2 olayla hesaplanan bir hız/ETA yanıltıcı kesinlik verir.
var _event_count: int = 0


## Her karede çağrılabilir.
func sample(tick: int, total: int) -> void:
	if not _has_total:
		_has_total = true
		_last_total = total
		_last_event_tick = tick
		_last_seen_tick = tick
		return

	_last_seen_tick = tick

	var delta: int = total - _last_total
	if delta <= 0:
		return  # bu karede yeni üretim yok — ortalamalar değişmez

	_event_count += 1
	var interval: float = float(tick - _last_event_tick)
	if _avg_interval < 0.0:
		_avg_interval = interval
		_avg_delta = float(delta)
	else:
		_avg_interval += (interval - _avg_interval) * EVENT_ALPHA
		_avg_delta += (float(delta) - _avg_delta) * EVENT_ALPHA

	_last_event_tick = tick
	_last_total = total


func per_minute() -> float:
	if _avg_interval <= 0.0:
		return 0.0
	# Son olaydan bu yana geçen süre normal aralığı aşıyorsa, hız o oranda
	# düşük gösterilir — istasyon durduğunda gösterge sıfıra söner, eski
	# hızda donup kalmaz. İkisi de HAM tick cinsinden — birim uyuşuyor.
	var since_last_event: float = float(_last_seen_tick - _last_event_tick)
	var effective_interval: float = maxf(_avg_interval, since_last_event)
	return _avg_delta / effective_interval * float(GameConfig.TICKS_PER_SECOND) * 60.0


func reset() -> void:
	_has_total = false
	_last_total = 0
	_last_event_tick = 0
	_last_seen_tick = 0
	_avg_interval = -1.0
	_avg_delta = 0.0
	_event_count = 0


## --- Sunum katmanı için salt okunur erişim (bkz. ResearchDeliveryTracker) --

func event_count() -> int:
	return _event_count


func has_measurement() -> bool:
	return _avg_interval >= 0.0


## Ardışık olaylar arası ortalama HAM tick. `has_measurement()` false ise anlamsız.
func avg_interval_ticks() -> float:
	return _avg_interval


func ticks_since_last_event() -> int:
	return _last_seen_tick - _last_event_tick
