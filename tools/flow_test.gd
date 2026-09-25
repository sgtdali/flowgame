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
## Görev 05 adım 3: fabrika içi editörle kurulur (FactoryInterior); fabrika her
## malı kabul eder ve giriş kapısı kendiliğinden gelir; hatlar yalnızca çıkış
## stoğundan alır; dakikalık giren/çıkan; uyarı (çıkış dolu, girdi bekleme).

const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
const CART: TransportType = preload("res://data/transport_types/at_arabasi.tres")
const SAWMILL: BlockType = preload("res://data/factory_blocks/sawmill.tres")
const LOGS: RawResource = preload("res://data/raw_resources/tomruk.tres")
const WHEAT: RawResource = preload("res://data/raw_resources/bugday.tres")
const LUMBER: Good = preload("res://data/goods/kereste.tres")
const FLOUR: Good = preload("res://data/goods/un.tres")
const VILLAGE: CityLevel = preload("res://data/city_levels/koy.tres")
## Bir adım: 1 oyun saniyesi.
const DT: float = 1.0 / 60.0
const EPS: float = 0.01

const FOREST: StringName = &"area1/Site1"
const PLOT: StringName = &"area1/Plot1"
const PLOT2: StringName = &"area1/Plot2"
const CITY: StringName = &"area1/City"

var _failures: int = 0
var _checks: int = 0

const EXPECTED_CHECKS: int = 22


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
	_test_factory_interior_link()
	_test_factory_warning()
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


## Arsaya fabrika kurar; içine Logs in → Sawmill → Output: Lumber döşer.
## Dönüş: Sawmill'in istasyon id'si (kurulamazsa -1).
func _build_sawmill(sim: MapFlowSim, plot: StringName = PLOT) -> int:
	if not sim.factories.build(plot):
		return -1
	var interior: FactoryInterior = sim.factories.interior_at(plot)
	var gate: int = interior.ensure_input_gate(LOGS)
	var saw: int = interior.add_station(SAWMILL)
	var out: int = interior.add_output_gate(LUMBER)
	if not (interior.connect_stations(gate, 0, saw, 0) and interior.connect_stations(saw, 0, out, 0)):
		return -1
	return saw


## Orman → arsa (Sawmill) → köy, iki hat da 150 birim / 1 araç = 10/dk.
func _sawmill_chain(config: MapConfig = MAP_CONFIG) -> MapFlowSim:
	var sim: MapFlowSim = MapFlowSim.new(config)
	_build_sawmill(sim)
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
	_build_sawmill(sim)
	var route: MapRoute = sim.routes.build(FOREST, PLOT, 300.0, CART)  # 5/dk
	_run(sim, 10.0)
	var flow: float = sim.route_flow(route, MapRoute.Direction.FORWARD)
	_check("Hat kapasitesini asmiyor (300 birim, 1 arac = 5/dk)", absf(flow - 5.0) < EPS,
			"akis=%.2f" % flow)
	# Girdi 5/dk geliyor, Sawmill 10/dk isleyebilir → cikti girdi kadar.
	# Parçalar içeride birkaç birim yolda olabilir.
	_check("Fabrika girdisi kadar isliyor (10 dk -> ~50, stok siniri 50)",
			sim.stock(PLOT, LUMBER) > 47.0 and sim.stock(PLOT, LUMBER) <= 50.0,
			"lumber=%.2f" % sim.stock(PLOT, LUMBER))

	var idle: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	_build_sawmill(idle)
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
	_build_sawmill(sim)
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
	var ok: bool = sim.factories.build(PLOT)
	_check("Fabrika kuruluyor, fiyati dusuyor",
			ok and sim.regions.money == money - MAP_CONFIG.factory_cost)
	_check("Arsa disina, kilitli bolgeye, ayni arsaya ikinci kez kurulamiyor",
			not sim.factories.build_block_reason(FOREST).is_empty()
			and sim.factories.build_block_reason(&"area2/Plot1").contains("locked")
			and not sim.factories.build(PLOT))


func _test_factory_interior_link() -> void:
	var sim: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	var before: bool = sim.accepts(PLOT, WHEAT)
	sim.factories.build(PLOT)
	sim.factories.build(PLOT2)
	sim.routes.build(FOREST, PLOT, 150.0, CART)
	sim.routes.build(PLOT, PLOT2, 150.0, CART)
	_run(sim, 3.0)
	var inside: FactoryInterior = sim.factories.interior_at(PLOT)
	_check("Bos arsa kabul etmiyor; fabrika her mali kabul ediyor, giris kapisi geliyor",
			not before and sim.accepts(PLOT, WHEAT) and sim.accepts(PLOT, LOGS)
			and inside.input_stock(LOGS) > 20.0 and inside.input_gate_id(LOGS) != -1,
			"giris stogu=%.1f" % inside.input_stock(LOGS))
	_check("Giris stogundaki mal disari cikmiyor (yalnizca cikis stogundan)",
			sim.factories.interior_at(PLOT2).station_count() == 0
			and sim.supplies(PLOT).is_empty())

	var chain: MapFlowSim = _sawmill_chain()
	_run(chain, 5.0)
	var saw: FactoryInterior = chain.factories.interior_at(PLOT)
	_check("Dakikalik giren/cikan olculuyor (Logs ~10 giris, Lumber ~10 cikis)",
			absf(saw.input_last_minute(LOGS) - 10.0) <= 1.0
			and absf(saw.output_last_minute(LUMBER) - 10.0) <= 1.0,
			"giris=%.1f cikis=%.1f" % [saw.input_last_minute(LOGS), saw.output_last_minute(LUMBER)])


func _test_factory_warning() -> void:
	var blocked: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	_build_sawmill(blocked)
	blocked.routes.build(FOREST, PLOT, 150.0, CART)
	var starved: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	_build_sawmill(starved)
	var empty: MapFlowSim = MapFlowSim.new(MAP_CONFIG)
	empty.factories.build(PLOT)
	var chain: MapFlowSim = _sawmill_chain()
	for sim: MapFlowSim in [blocked, starved, empty, chain]:
		_run(sim, 8.0)
	_check("Uyari: cikisi dolan ve girdi bekleyen yanar; bos ve calisan fabrika yanmaz",
			blocked.factory_warning(PLOT) and starved.factory_warning(PLOT)
			and not empty.factory_warning(PLOT) and not chain.factory_warning(PLOT),
			"dolu=%s bekleyen=%s bos=%s zincir=%s" % [blocked.factory_warning(PLOT),
			starved.factory_warning(PLOT), empty.factory_warning(PLOT), chain.factory_warning(PLOT)])


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
