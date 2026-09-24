extends SceneTree

## Akış simülasyonu testi (MapFlowSim, arayüzsüz).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/flow_test.gd
##
## Kanıtlar (görev 04 adım 2): yatak üretir ve stok sınırında durur; hat
## kapasitesini aşmaz; kabul edilmeyen mal taşınmaz; yük oranı ve artan payın
## aktarımı; fabrika tarif hızında işler, girdi yoksa durur; köy satışı ve
## doygunluk; bakım düşer; para eksiye iner ve alımı engeller; kilitli bölge
## üretmez; fabrika kurma kuralları; belirlilik; ilk para döngüsü kâr eder.

const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
const CART: TransportType = preload("res://data/transport_types/at_arabasi.tres")
const SAWMILL: ProcessRecipe = preload("res://data/recipes_map/bickihane.tres")
const LOGS: RawResource = preload("res://data/raw_resources/tomruk.tres")
const LUMBER: Good = preload("res://data/goods/kereste.tres")
const FLOUR: Good = preload("res://data/goods/un.tres")
const VILLAGE: CityLevel = preload("res://data/city_levels/koy.tres")
## Bir adım: 1 oyun saniyesi.
const DT: float = 1.0 / 60.0
const EPS: float = 0.01

const FOREST: StringName = &"area1/Site1"
const PLOT: StringName = &"area1/Plot1"
const CITY: StringName = &"area1/City"

var _failures: int = 0
var _checks: int = 0

const EXPECTED_CHECKS: int = 18


func _initialize() -> void:
	print("")
	_test_production()
	_test_route_capacity_and_factory()
	_test_acceptance()
	_test_allocation()
	_test_saturation()
	_test_upkeep_and_debt()
	_test_locked_region_idle()
	_test_factory_rules()
	_test_first_loop_and_determinism()

	print("")
	if _checks < EXPECTED_CHECKS:
		print("SONUC: yalnizca %d/%d kontrol calisti — test eksik kostu." % [
			_checks, EXPECTED_CHECKS])
		quit(1)
		return
	if _failures == 0:
		print("SONUC: %d/%d kontrol gecti." % [_checks, _checks])
	else:
		print("SONUC: %d/%d kontrol BASARISIZ." % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


func _run(sim: MapFlowSim, minutes: float) -> void:
	for i: int in roundi(minutes / DT):
		sim.step(DT)


## Orman → arsa (Sawmill) → köy, iki hat da 150 birim / 1 araç = 10/dk.
func _sawmill_chain(config: MapConfig = MAP_CONFIG) -> MapFlowSim:
	var sim: MapFlowSim = MapFlowSim.new(config)
	sim.factories.build(PLOT, SAWMILL)
	sim.routes.build(FOREST, PLOT, 150.0, CART)
	sim.routes.build(PLOT, CITY, 150.0, CART)
	return sim


func _test_production() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	_run(sim, 1.0)
	_check("Yatak 1 dakikada 20 uretiyor", absf(sim.stock(FOREST, LOGS) - 20.0) < EPS,
			"stok=%.2f" % sim.stock(FOREST, LOGS))
	_run(sim, 5.0)
	_check("Yatak stok sinirinda duruyor", absf(sim.stock(FOREST, LOGS) - MAP_CONFIG.point_stock_capacity) < EPS,
			"stok=%.2f" % sim.stock(FOREST, LOGS))


func _test_route_capacity_and_factory() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	sim.factories.build(PLOT, SAWMILL)
	var route: MapRoute = sim.routes.build(FOREST, PLOT, 300.0, CART)  # 5/dk
	_run(sim, 10.0)
	var flow: float = sim.route_flow(route, MapRoute.Direction.FORWARD)
	_check("Hat kapasitesini asmiyor (300 birim, 1 arac = 5/dk)", absf(flow - 5.0) < EPS,
			"akis=%.2f" % flow)
	# Girdi 5/dk geliyor, Sawmill 10/dk isleyebilir → cikti girdi kadar.
	_check("Fabrika girdisi kadar isliyor (10 dk -> ~50, stok siniri 50)",
			absf(sim.stock(PLOT, LUMBER) - 50.0) < 0.5,
			"lumber=%.2f" % sim.stock(PLOT, LUMBER))

	var idle: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	idle.factories.build(PLOT, SAWMILL)
	_run(idle, 3.0)
	_check("Girdisi olmayan fabrika uretmiyor", idle.stock(PLOT, LUMBER) < EPS)


func _test_acceptance() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	var route: MapRoute = sim.routes.build(FOREST, CITY, 150.0, CART)
	_run(sim, 3.0)
	var reason: String = sim.direction_block_reason(route, MapRoute.Direction.FORWARD)
	_check("Ormandan koye hat bir sey tasimiyor ve nedeni var",
			sim.route_flow(route, MapRoute.Direction.FORWARD) < EPS and not reason.is_empty()
			and sim.stock(FOREST, LOGS) > 49.0,
			"neden='%s'" % reason)
	_check("Koyden geri yonde gonderilecek bir sey yok",
			not sim.direction_block_reason(route, MapRoute.Direction.BACKWARD).is_empty())


func _test_allocation() -> void:
	var even: Array[float] = MapFlowSim.allocate(10.0, [1.0, 1.0] as Array[float], [100.0, 100.0] as Array[float])
	var ratio: Array[float] = MapFlowSim.allocate(10.0, [3.0, 1.0] as Array[float], [100.0, 100.0] as Array[float])
	var capped: Array[float] = MapFlowSim.allocate(10.0, [1.0, 1.0] as Array[float], [2.0, 100.0] as Array[float])
	_check("Yuk orani: esit 5/5, 3:1 -> 7.5/2.5",
			absf(even[0] - 5.0) < EPS and absf(ratio[0] - 7.5) < EPS and absf(ratio[1] - 2.5) < EPS,
			"esit=%s oran=%s" % [even, ratio])
	_check("Dolduramayan malin payi digerine geciyor (2 + 8)",
			absf(capped[0] - 2.0) < EPS and absf(capped[1] - 8.0) < EPS, "%s" % [capped])


func _test_saturation() -> void:
	var full: float = CityMarket.price_for(VILLAGE, LUMBER, 0.0, 10.0)
	var half: float = CityMarket.price_for(VILLAGE, LUMBER, 10.0, 5.0)
	var tenth: float = CityMarket.price_for(VILLAGE, LUMBER, 15.0, 5.0)
	_check("Doygunluk: 10 tam (10), 5 yari (2.5), 5 onda bir (0.5)",
			absf(full - 10.0) < EPS and absf(half - 2.5) < EPS and absf(tenth - 0.5) < EPS,
			"%.2f %.2f %.2f" % [full, half, tenth])
	var market: CityMarket = CityMarket.new(MAP_CONFIG)
	market.sell(CITY, LUMBER, 15.0)
	market.roll_minute()
	_check("Dakika dolunca doygunluk sifirlaniyor",
			absf(market.sell(CITY, LUMBER, 10.0) - 10.0) < EPS
			and not market.accepts(CITY, LOGS) and market.accepts(CITY, FLOUR))


func _test_upkeep_and_debt() -> void:
	var poor: MapConfig = MAP_CONFIG.duplicate()
	poor.starting_money = MAP_CONFIG.factory_cost + CART.route_cost + CART.vehicle_price
	var sim: MapFlowSim = MapFlowSim.new(poor)
	sim.factories.build(PLOT, SAWMILL)
	sim.routes.build(FOREST, PLOT, 150.0, CART)
	var upkeep: int = MAP_CONFIG.factory_upkeep + CART.vehicle_upkeep
	_run(sim, 10.0)
	_check("Bakim dakika basi dusuyor, para eksiye iniyor",
			sim.regions.money == -upkeep * 10, "para=%d beklenen=%d" % [sim.regions.money, -upkeep * 10])
	_check("Eksideyken alim yapilamiyor",
			sim.routes.build_block_reason(PLOT, CITY, CART) == "Not enough money"
			and not sim.regions.wallet.can_afford(1))


func _test_locked_region_idle() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	var mine: RawResource = MapPoints.find(&"area2/Site1").resource
	_run(sim, 2.0)
	_check("Kilitli bolgedeki yatak uretmiyor", sim.stock(&"area2/Site1", mine) < EPS)


func _test_factory_rules() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	var money: int = sim.regions.money
	var ok: bool = sim.factories.build(PLOT, SAWMILL)
	_check("Fabrika kuruluyor, fiyati dusuyor",
			ok and sim.regions.money == money - MAP_CONFIG.factory_cost)
	_check("Arsa disina, kilitli bolgeye, ayni arsaya ikinci kez kurulamiyor",
			not sim.factories.build_block_reason(FOREST, SAWMILL).is_empty()
			and sim.factories.build_block_reason(&"area2/Plot1", SAWMILL).contains("locked")
			and not sim.factories.build(PLOT, SAWMILL))


func _test_first_loop_and_determinism() -> void:
	var sim: MapFlowSim = _sawmill_chain()
	_run(sim, 5.0)  # ısınma
	var before: int = sim.regions.money
	_run(sim, 10.0)
	var net: int = sim.regions.money - before
	var upkeep: int = MAP_CONFIG.factory_upkeep + CART.vehicle_upkeep * 2
	# 10 Lumber/dk × 1 − 5 bakım = +5/dk
	_check("Ilk para dongusu kar ediyor (~+%d/dk)" % (10 - upkeep),
			absi(net - (10 - upkeep) * 10) <= 1, "10 dk net=%d" % net)
	var again: MapFlowSim = _sawmill_chain()
	_run(again, 15.0)
	_check("Ayni kurulum ayni sonucu veriyor",
			again.regions.money == sim.regions.money
			and absf(again.stock(PLOT, LUMBER) - sim.stock(PLOT, LUMBER)) < EPS)


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
