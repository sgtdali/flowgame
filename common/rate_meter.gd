class_name RateMeter
extends RefCounted

## Kayan pencere üzerinden "dakikada kaç" ölçer.
##
## Kümülatif bir sayacın (üretilen toplam parça, toplam gelir) artış hızını
## verir. Anlık değil, son ~15 saniyelik pencere üzerinden: anlık ölçüm
## tick tick zıplar ve okunmaz olur.
##
## MİMARİ: Bu bir SUNUM aracıdır, simülasyonun parçası değil. Simülasyon
## kümülatif sayaçları tutar; hıza çevirmek ekranın işi. Bu yüzden kayıtta
## yer almaz — yükledikten birkaç saniye sonra kendi kendine dolar.

## Pencere uzunluğu. Kısa olursa değer zıplar, uzun olursa değişime geç tepki
## verir; 15 saniye ikisi arasında makul bir yer.
const WINDOW_TICKS: int = GameConfig.TICKS_PER_SECOND * 15

var _ticks: PackedInt64Array = PackedInt64Array()
var _values: PackedInt64Array = PackedInt64Array()


## Her karede çağrılabilir — aynı tick tekrar gelirse örnek çoğaltmaz.
func sample(tick: int, total: int) -> void:
	var count: int = _ticks.size()
	if count > 0 and _ticks[count - 1] == tick:
		_values[count - 1] = total
		return

	_ticks.append(tick)
	_values.append(total)

	while _ticks.size() > 2 and tick - _ticks[0] > WINDOW_TICKS:
		_ticks.remove_at(0)
		_values.remove_at(0)


func per_minute() -> float:
	var count: int = _ticks.size()
	if count < 2:
		return 0.0
	var elapsed: int = _ticks[count - 1] - _ticks[0]
	if elapsed <= 0:
		return 0.0
	var gained: int = _values[count - 1] - _values[0]
	return float(gained) * float(GameConfig.TICKS_PER_SECOND) * 60.0 / float(elapsed)


func reset() -> void:
	_ticks.clear()
	_values.clear()
