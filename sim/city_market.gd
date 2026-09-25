class_name CityMarket
extends RefCounted

## Şehirlerin talebi ve satış fiyatı (arayüzsüz).
##
## Tasarım: şehir yalnızca talep ettiği işlenmiş malı alır, stok sınırı yoktur,
## mal gelir gelmez satılır. Doygunluk her oyun dakikasında sıfırlanır (görev
## 04, K4): o dakika içinde talebin eşiklerini geçen kısım daha ucuza satılır.

var _config: MapConfig
## Şehir id -> CityLevel.
var _levels: Dictionary = {}
## Şehir id -> {mal id: bu dakika satılan miktar}.
var _sold_this_minute: Dictionary = {}
## Şehir id -> {mal id: geçen dakika satılan miktar} (panelde gösterim için).
var _sold_last_minute: Dictionary = {}
## Şehir id -> geçen dakikanın geliri.
var _revenue_last_minute: Dictionary = {}
var _revenue_this_minute: Dictionary = {}
## Şehir id -> geçen dakika bir mal talebin ilk eşiğini (tam fiyat dilimini) aştı mı.
var _saturated_last_minute: Dictionary = {}


func _init(config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_config = config
	for info: MapPoints.Info in MapPoints.all():
		if info.kind == MapPoints.Kind.CITY:
			_levels[info.id] = config.starting_city_level
			_sold_this_minute[info.id] = {}
			_sold_last_minute[info.id] = {}
			_revenue_this_minute[info.id] = 0.0
			_revenue_last_minute[info.id] = 0.0


func level(city_id: StringName) -> CityLevel:
	return _levels.get(city_id, null)


## Şehir bu malı alır mı? (talep listesinde ve satılabilir)
func accepts(city_id: StringName, good: Good) -> bool:
	var city_level: CityLevel = level(city_id)
	return city_level != null and good.city_price > 0 and city_level.demand_for(good) > 0


func sold_this_minute(city_id: StringName, good: Good) -> float:
	return (_sold_this_minute.get(city_id, {}) as Dictionary).get(good.id, 0.0)


func sold_last_minute(city_id: StringName, good: Good) -> float:
	return (_sold_last_minute.get(city_id, {}) as Dictionary).get(good.id, 0.0)


func revenue_last_minute(city_id: StringName) -> float:
	return _revenue_last_minute.get(city_id, 0.0)


## Geçen dakika bir mal talebin tam fiyat dilimini aştı mı (daha ucuza satıldı mı)?
func saturated_last_minute(city_id: StringName) -> bool:
	return _saturated_last_minute.get(city_id, false)


## Bu dakika `good` için tam fiyat diliminin üstüne çıkıldı mı?
func _over_full_price(city_id: StringName, good_id: StringName, sold: float) -> bool:
	var city_level: CityLevel = level(city_id)
	for good: Good in city_level.demand_goods:
		if good.id == good_id and not city_level.saturation_thresholds.is_empty():
			return sold > city_level.saturation_thresholds[0] * city_level.demand_for(good) + 0.000001
	return false


## Malı satar ve geliri döner. Kabul edilmeyen mal için 0.
func sell(city_id: StringName, good: Good, amount: float) -> float:
	if amount <= 0.0 or not accepts(city_id, good):
		return 0.0
	var before: float = sold_this_minute(city_id, good)
	var revenue: float = price_for(level(city_id), good, before, amount)
	(_sold_this_minute[city_id] as Dictionary)[good.id] = before + amount
	_revenue_this_minute[city_id] = _revenue_this_minute[city_id] + revenue
	return revenue


## Bu dakika `already_sold` satılmışken `amount` daha satmanın geliri.
## Kademeler: talebin eşik katlarına kadar olan dilimler çarpanlarla fiyatlanır.
static func price_for(city_level: CityLevel, good: Good, already_sold: float,
		amount: float) -> float:
	var demand: float = city_level.demand_for(good)
	var revenue: float = 0.0
	var start: float = already_sold
	var end: float = already_sold + amount
	var tier_start: float = 0.0
	for i: int in city_level.saturation_multipliers.size():
		var tier_end: float = INF
		if i < city_level.saturation_thresholds.size():
			tier_end = city_level.saturation_thresholds[i] * demand
		var overlap: float = minf(end, tier_end) - maxf(start, tier_start)
		if overlap > 0.0:
			revenue += overlap * good.city_price * city_level.saturation_multipliers[i]
		tier_start = tier_end
	return revenue


## Oyun dakikası dolunca çağrılır: doygunluk sıfırlanır.
func roll_minute() -> void:
	for city_id: StringName in _levels:
		var saturated: bool = false
		for good_id: StringName in (_sold_this_minute[city_id] as Dictionary):
			if _over_full_price(city_id, good_id, _sold_this_minute[city_id][good_id]):
				saturated = true
		_saturated_last_minute[city_id] = saturated
		_sold_last_minute[city_id] = _sold_this_minute[city_id]
		_sold_this_minute[city_id] = {}
		_revenue_last_minute[city_id] = _revenue_this_minute[city_id]
		_revenue_this_minute[city_id] = 0.0
