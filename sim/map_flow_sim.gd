class_name MapFlowSim
extends RefCounted

## Harita katmanının akış simülasyonu (arayüzsüz).
##
## Her adım (dt oyun dakikası) sırasıyla: yataklar üretir → hatlar taşır
## (şehre gelen mal satılır) → fabrikaların içi aynı süre koşar → bakım düşer.
## Fabrikanın stokları FactoryInterior'dadır: hatlar giriş stoğuna koyar,
## çıkış stoğundan alır (görev 05).
## Tasarım: 1 oyun dakikası = 1 gerçek dakika (hızı arayüz ayarlar);
## mal hatta beklemez (görev 04, K1); aynı kaynaktan çeken hatlarda önce kurulan
## önce alır (K3); para tam sayı, kesirler birikir (K5).

## Kayan nokta karşılaştırma toleransı (taşıma payı dağıtımı ve paranın yuvarlanması).
const EPSILON: float = 0.000001
## Hat akışı panelde ve haritada yumuşatılarak gösterilir: fabrika çıktısı tam
## birimler hâlinde geldiği için anlık akış adım adım 0 ile tam hız arasında
## gidip gelir. Ortalamanın zaman sabiti (oyun dakikası).
const FLOW_SMOOTHING_MINUTES: float = 0.25
## Bu hızın (birim/dk) altındaki ortalama akış "taşımıyor" sayılır.
const FLOW_VISIBLE_MIN: float = 0.05

var regions: RegionState
var routes: RouteState
var factories: FactorySites
var market: CityMarket
## Oyun başından beri geçen oyun dakikası.
var clock: float = 0.0

var _config: MapConfig
## Nokta id -> {Good: miktar}. Şehirlerin stoğu yoktur; fabrikalarınki içeridedir.
var _stocks: Dictionary = {}
## Paraya henüz yansımamış kesirli gelir/bakım.
var _pending_money: float = 0.0
## Hat -> [ileri, geri]; her biri {Good: yumuşatılmış akış (birim/dk)}.
var _route_flow: Dictionary = {}


func _init(config: MapConfig = RegionState.DEFAULT_CONFIG) -> void:
	_config = config
	regions = RegionState.new(config)
	routes = RouteState.new(regions, config)
	factories = FactorySites.new(regions, config)
	market = CityMarket.new(config)


## Noktanın hatta verebileceği stok; fabrikada çıkış stoğu.
func stock(point_id: StringName, good: Good) -> float:
	var interior: FactoryInterior = factories.interior_at(point_id)
	if interior != null:
		return interior.output_stock(good)
	return (_stocks.get(point_id, {}) as Dictionary).get(good, 0.0)


## Bu yöndeki akış hızı (birim/dk, yumuşatılmış; bkz. FLOW_SMOOTHING_MINUTES).
func route_flow(route: MapRoute, direction: MapRoute.Direction) -> float:
	var total: float = 0.0
	for amount: float in _goods_flow(route, direction).values():
		total += amount
	return total


## Bu yönde görünür hızda (FLOW_VISIBLE_MIN üstü) bir şey taşınıyor mu?
func is_carrying(route: MapRoute, direction: MapRoute.Direction) -> bool:
	return route_flow(route, direction) >= FLOW_VISIBLE_MIN


## Bu yönde en çok taşınan mal; görünür hızda bir şey taşınmıyorsa null.
func main_cargo(route: MapRoute, direction: MapRoute.Direction) -> Good:
	var best: Good = null
	var best_amount: float = FLOW_VISIBLE_MIN
	for good: Good in _goods_flow(route, direction):
		var amount: float = _goods_flow(route, direction)[good]
		if amount >= best_amount:
			best = good
			best_amount = amount
	return best


func _goods_flow(route: MapRoute, direction: MapRoute.Direction) -> Dictionary:
	var flows: Array = _route_flow.get(route, [{}, {}])
	return flows[direction]


## Fabrikanın haritada uyarı işareti yanmalı mı? (fabrika yoksa false)
func factory_warning(plot_id: StringName) -> bool:
	var interior: FactoryInterior = factories.interior_at(plot_id)
	return interior != null and interior.has_warning()


## Geçen tam oyun dakikasında şehirlerden gelen toplam gelir.
func income_last_minute() -> float:
	var total: float = 0.0
	for info: MapPoints.Info in MapPoints.all():
		if info.kind == MapPoints.Kind.CITY:
			total += market.revenue_last_minute(info.id)
	return total


## Şu anki dakikalık bakım (araçlar + fabrikalar).
func upkeep_per_minute() -> int:
	return routes.total_upkeep_per_minute() + factories.upkeep_per_minute()


## Noktanın hatta verebileceği mallar (kaynak tarafı).
func supplies(point_id: StringName) -> Array[Good]:
	var out: Array[Good] = []
	var info: MapPoints.Info = MapPoints.find(point_id)
	if info == null:
		return out
	match info.kind:
		MapPoints.Kind.RESOURCE_SITE:
			out.append(info.resource)
		MapPoints.Kind.FACTORY_PLOT:
			var interior: FactoryInterior = factories.interior_at(point_id)
			if interior != null:
				out = interior.output_goods()
	return out


## Nokta bu malı kabul eder mi? (varış tarafı)
func accepts(point_id: StringName, good: Good) -> bool:
	var info: MapPoints.Info = MapPoints.find(point_id)
	if info == null:
		return false
	match info.kind:
		MapPoints.Kind.CITY:
			return market.accepts(point_id, good)
		MapPoints.Kind.FACTORY_PLOT:
			return factories.has_factory(point_id)  # fabrika her malı kabul eder
	return false


## Hattın bu yönünde taşınabilecek mallar.
func cargo_options(route: MapRoute, direction: MapRoute.Direction) -> Array[Good]:
	var out: Array[Good] = []
	for good: Good in supplies(route.source(direction)):
		if accepts(route.destination(direction), good):
			out.append(good)
	return out


## Bu yönde hiçbir şey taşınamıyorsa nedeni (panel için); taşınabiliyorsa "".
func direction_block_reason(route: MapRoute, direction: MapRoute.Direction) -> String:
	var offered: Array[Good] = supplies(route.source(direction))
	if offered.is_empty():
		return "Nothing to send from here"
	if cargo_options(route, direction).is_empty():
		return "Destination doesn't accept %s" % offered[0].display_name
	return ""


func step(dt: float) -> void:
	if dt <= 0.0:
		return
	_produce(dt)
	_move_goods(dt)
	_process_factories(dt)
	_pending_money -= upkeep_per_minute() * dt
	_commit_money()
	var minute_before: int = floori(clock)
	clock += dt
	if floori(clock) > minute_before:
		market.roll_minute()
		for plot_id: StringName in factories.plots():
			factories.interior_at(plot_id).roll_minute()


func _produce(dt: float) -> void:
	for info: MapPoints.Info in MapPoints.all():
		if info.kind == MapPoints.Kind.RESOURCE_SITE and regions.is_unlocked(info.region_id):
			_add_stock(info.id, info.resource, info.resource.extraction_per_minute * dt)


func _move_goods(dt: float) -> void:
	var blend: float = minf(1.0, dt / FLOW_SMOOTHING_MINUTES)
	for route: MapRoute in routes.routes():
		if not _route_flow.has(route):
			_route_flow[route] = [{}, {}]
		for direction: MapRoute.Direction in [MapRoute.Direction.FORWARD, MapRoute.Direction.BACKWARD]:
			var moved: Dictionary = _move_direction(route, direction, dt)
			var average: Dictionary = _route_flow[route][direction]
			for good: Good in moved:
				if not average.has(good):
					average[good] = 0.0
			for good: Good in average.keys():
				var rate: float = float(moved.get(good, 0.0)) / dt
				average[good] = float(average[good]) + (rate - float(average[good])) * blend


## Bir yönde bu adımda taşınan miktarlar: {Good: miktar}.
func _move_direction(route: MapRoute, direction: MapRoute.Direction, dt: float) -> Dictionary:
	var moved: Dictionary = {}
	var options: Array[Good] = cargo_options(route, direction)
	if options.is_empty():
		return moved
	var src: StringName = route.source(direction)
	var dst: StringName = route.destination(direction)
	var weights: Array[float] = []
	var limits: Array[float] = []
	for good: Good in options:
		weights.append(route.weight(direction, good.id))
		limits.append(minf(stock(src, good), _free_space(dst, good)))
	var amounts: Array[float] = allocate(route.capacity_per_minute() * dt, weights, limits)
	for i: int in options.size():
		if amounts[i] <= 0.0:
			continue
		_take(src, options[i], amounts[i])
		if MapPoints.find(dst).kind == MapPoints.Kind.CITY:
			_pending_money += market.sell(dst, options[i], amounts[i])
		elif factories.has_factory(dst):
			factories.interior_at(dst).add_input(options[i], amounts[i])
		else:
			_add_stock(dst, options[i], amounts[i])
		moved[options[i]] = amounts[i]
	return moved


## Kapasiteyi ağırlıklara göre paylaştırır; bir malın sınırı payını
## dolduramazsa kalan pay diğerlerine geçer. Dönüş: mal başına miktar.
static func allocate(budget: float, weights: Array[float], limits: Array[float]) -> Array[float]:
	var amounts: Array[float] = []
	amounts.resize(weights.size())
	amounts.fill(0.0)
	var remaining: float = budget
	var open: Array[int] = []
	for i: int in weights.size():
		if weights[i] > 0.0 and limits[i] > EPSILON:
			open.append(i)
	while remaining > EPSILON and not open.is_empty():
		var total_weight: float = 0.0
		for i: int in open:
			total_weight += weights[i]
		var still_open: Array[int] = []
		var given: float = 0.0
		for i: int in open:
			var share: float = remaining * weights[i] / total_weight
			var take: float = minf(share, limits[i] - amounts[i])
			amounts[i] += take
			given += take
			if limits[i] - amounts[i] > EPSILON:
				still_open.append(i)
		remaining -= given
		# Hiç kimse sınıra takılmadıysa pay tamamen dağıtılmıştır.
		if still_open.size() == open.size():
			break
		open = still_open
	return amounts


func _process_factories(dt: float) -> void:
	for plot_id: StringName in factories.plots():
		factories.interior_at(plot_id).advance(dt)


func _free_space(point_id: StringName, good: Good) -> float:
	if MapPoints.find(point_id).kind == MapPoints.Kind.CITY:
		return INF
	var interior: FactoryInterior = factories.interior_at(point_id)
	if interior != null:
		return interior.input_space(good)
	return maxf(_config.point_stock_capacity - stock(point_id, good), 0.0)


func _take(point_id: StringName, good: Good, amount: float) -> void:
	var interior: FactoryInterior = factories.interior_at(point_id)
	if interior != null:
		interior.take_output(good, amount)
	else:
		_add_stock(point_id, good, -amount)


func _add_stock(point_id: StringName, good: Good, amount: float) -> void:
	if not _stocks.has(point_id):
		_stocks[point_id] = {}
	var goods: Dictionary = _stocks[point_id]
	goods[good] = clampf(goods.get(good, 0.0) + amount, 0.0, float(_config.point_stock_capacity))


## Birikmiş kesirli parayı tam birimler hâlinde cüzdana yansıtır. Tolerans:
## çok sayıda küçük adımın kayan nokta hatası 39.9999'u 39'a yuvarlamasın.
func _commit_money() -> void:
	var whole: int = int(_pending_money + signf(_pending_money) * EPSILON)
	if whole != 0:
		regions.wallet.adjust(whole)
		_pending_money -= whole
