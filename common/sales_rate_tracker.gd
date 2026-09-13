class_name SalesRateTracker
extends RefCounted

## Sevkiyattan gelen toplam satış hızını (₺/dk ve adet/dk) ölçer.
##
## NEDEN ÜRÜN BAŞINA AYRI RateMeter: Tek bir RateMeter'a tüm satışları
## (karışık ürün tipleriyle) beslemek denendi ve başarısız oldu. Külçe 10₺,
## Gövde 220₺ — bu, 22 kat büyüklük farkı demek. Nadir gelen büyük bir satış
## "olay başına ortalama miktar" tahminini bir anda fırlatıyor, sonraki küçük
## satışlara kadar o şişkin tahminle hesap yapılıyor. Ölçüldü: karışık bir
## ekonomide gösterge 481 ile 3330 TL/dk arasında geziniyordu.
##
## Çözüm: her ÜRÜN TÜRÜ için AYRI bir RateMeter tutmak. Tek bir ürün türü
## içinde miktar hep sabittir (aynı fiyat, benzer parti büyüklüğü), bu yüzden
## o ürünün kendi ölçer'i kusursuz sabit kalır (zaten kanıtlandı). Sabit
## değerlerin toplamı da sabittir — karışık ekonomi artık tek tek homojen
## akışların toplamı olarak ele alınıyor, hepsi bir arada değil.

var _meters: Dictionary = {}  # item_id -> RateMeter


## Her karede çağrılır. `sold_counts` FactorySim'in tuttuğu kümülatif
## sözlük — ürün id'si -> şimdiye kadar satılan toplam adet.
func sample(tick: int, sold_counts: Dictionary) -> void:
	for item_id: StringName in sold_counts:
		if not _meters.has(item_id):
			_meters[item_id] = RateMeter.new()
		(_meters[item_id] as RateMeter).sample(tick, int(sold_counts[item_id]))


## Toplam gelir hızı (₺/dk). Her ürünün kendi kararlı hızı, o ürünün
## fiyatıyla çarpılıp toplanır.
func money_per_minute() -> float:
	var total: float = 0.0
	for item_id: StringName in _meters:
		var item: ItemType = ItemCatalog.find_by_id(item_id)
		if item != null:
			total += (_meters[item_id] as RateMeter).per_minute() * float(item.base_price)
	return total


## Toplam çıktı hızı (adet/dk), ürün türünden bağımsız.
func units_per_minute() -> float:
	var total: float = 0.0
	for item_id: StringName in _meters:
		total += (_meters[item_id] as RateMeter).per_minute()
	return total


func reset() -> void:
	_meters.clear()
