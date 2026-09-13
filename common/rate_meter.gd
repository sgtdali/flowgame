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
## (1) Sabit pencere (son N tick, boxcar filtre): üretim düzenli olsa bile —
##     ör. 14 tick'te bir — pencere üretim periyoduna tam bölünmezse, kenar
##     her bir üretim anını geçtiğinde sayaç sert bir basamak atlıyordu.
##     Ölçüldü: gerçek ortalama 42.86/dk iken görüntü sürekli 40-44 arası
##     zıplıyordu.
## (2) Üstel yumuşatılmış türev: kenar sıçraması kayboldu ama üretim ayrık
##     olduğu için (çoğu tick'te değişim sıfır, üretim anında ani sıçrama)
##     yumuşatılmış değer HER KAREDE sürekli sürünüyordu — "zıplama" yerine
##     "durmadan kayma" oldu, ki şikayet edilen şey buydu.
##
## Doğru model: üretim bir OLAY DİZİSİ (nokta süreci). Hız, ardışık olaylar
## arasındaki SÜRENİN ortalamasından hesaplanır — konumun türevinden değil.
## Düzenli üretimde iki olay arası süre hep aynıdır, bu yüzden gösterilen
## değer olaylar arasında TAMAMEN SABİT kalır; yalnızca her üretim anında
## bir sonraki olaya göre hafifçe güncellenir. Bir hız ölçer tekerlek
## dönüşleri arasındaki süreden hız kestirir; konumu sürekli türevleyip
## gürültüyü yumuşatmaya çalışmaz.

## Ardışık olay aralıklarının üstel ortalaması ne kadar hızlı güncellensin.
## Küçük değer = çok sayıda geçmiş olayın ortalaması (sakin, geç tepki).
const EVENT_ALPHA: float = 0.3

var _has_total: bool = false
var _last_total: int = 0

## Son üretim OLAYININ görüldüğü tick (total'ın gerçekten arttığı an).
var _last_event_tick: int = 0

## En son sample() çağrısındaki tick — "şu an" için. Üretim olmasa da her
## karede güncellenir; uzun süredir olay yoksa hızın sıfıra sönmesini sağlar.
var _last_seen_tick: int = 0

## Ardışık olaylar arası sürenin (tick, birim başına) üstel ortalaması.
## -1 = henüz hiç olay görülmedi.
var _avg_interval: float = -1.0


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
		return  # bu karede yeni üretim yok — ortalama aralık değişmez

	# Birden fazla birim aynı tick'te gelmiş olabilir (toplu boşaltma);
	# aralığı birim başına düşürüyoruz ki hız hesabı bozulmasın.
	var interval_per_unit: float = float(tick - _last_event_tick) / float(delta)
	if _avg_interval < 0.0:
		_avg_interval = interval_per_unit
	else:
		_avg_interval += (interval_per_unit - _avg_interval) * EVENT_ALPHA

	_last_event_tick = tick
	_last_total = total


func per_minute() -> float:
	if _avg_interval <= 0.0:
		return 0.0
	# Son olaydan bu yana geçen süre ortalama aralığı aşıyorsa, hız o
	# oranda düşük gösterilir — istasyon durduğunda gösterge sıfıra söner,
	# eski hızda donup kalmaz.
	var since_last_event: float = float(_last_seen_tick - _last_event_tick)
	var effective_interval: float = maxf(_avg_interval, since_last_event)
	return 1.0 / effective_interval * float(GameConfig.TICKS_PER_SECOND) * 60.0


func reset() -> void:
	_has_total = false
	_last_total = 0
	_last_event_tick = 0
	_last_seen_tick = 0
	_avg_interval = -1.0
