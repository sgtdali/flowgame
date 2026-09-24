extends SceneTree

## Hat kuralları testi (RouteState, arayüzsüz).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/route_test.gd
##
## Kanıtlar (görev 03 adım 1):
##   kilitli bölgeye / aynı noktaya / aynı iki nokta arasına ikinci kez hat kurulamaz,
##   para yetmezse kurulamaz, kurunca kurulum + 1 araç düşer, kapasite formülü doğru,
##   araç ekleme/çıkarma ve iadeler doğru, son araç çıkarılamaz, bakım toplamı doğru,
##   bölge açma ile hatlar aynı cüzdanı kullanır.

const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
const CART: TransportType = preload("res://data/transport_types/at_arabasi.tres")
const TRUCK: TransportType = preload("res://data/transport_types/kamyon.tres")
const CAPACITY_EPSILON: float = 0.001

var _failures: int = 0
var _checks: int = 0

const EXPECTED_CHECKS: int = 14


func _initialize() -> void:
	print("")
	_test_basic_flow()
	_test_not_enough_money()
	_test_unlock_opens_routes()

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


func _test_basic_flow() -> void:
	var regions: RegionState = RegionState.new(MAP_CONFIG)
	var routes: RouteState = RouteState.new(regions, MAP_CONFIG)
	var money: int = regions.money

	_check("Ayni noktaya hat kurulamiyor",
			not routes.build_block_reason(&"area1/City", &"area1/City", CART).is_empty())
	var locked_reason: String = routes.build_block_reason(&"area1/City", &"area2/Site1", CART)
	_check("Kilitli bolgedeki noktaya hat kurulamiyor",
			locked_reason.contains("locked") and routes.build(&"area1/City", &"area2/Site1", 300.0, CART) == null,
			"neden='%s'" % locked_reason)

	var first: MapRoute = routes.build(&"area1/Site1", &"area1/City", 150.0, CART)
	var cost: int = CART.route_cost + CART.vehicle_price
	_check("Hat kuruluyor, kurulum + 1 arac dusuyor",
			first != null and first.vehicles == 1 and regions.money == money - cost,
			"para=%d beklenen=%d" % [regions.money, money - cost])
	_check("Kapasite: 150 birim, 1 arac -> 10/dk",
			first != null and absf(first.capacity_per_minute() - 10.0) < CAPACITY_EPSILON,
			"kapasite=%s" % (first.capacity_per_minute() if first != null else -1.0))
	_check("Ayni iki nokta arasina ikinci hat kurulamiyor (ters sira dahil)",
			routes.build(&"area1/City", &"area1/Site1", 150.0, CART) == null
			and routes.routes().size() == 1)
	_check("Arastirilmamis tur kurulamiyor",
			routes.build_block_reason(&"area1/Plot1", &"area1/City", TRUCK).contains("not researched"))

	var second: MapRoute = routes.build(&"area1/Plot1", &"area1/Plot2", 600.0, CART)
	for i: int in 3:
		routes.add_vehicle(second)
	var expected_money: int = money - cost * 2 - CART.vehicle_price * 3
	_check("Arac ekleniyor, para dusuyor",
			second.vehicles == 4 and regions.money == expected_money,
			"arac=%d para=%d beklenen=%d" % [second.vehicles, regions.money, expected_money])
	_check("Kapasite: 600 birim, 4 arac -> 10/dk",
			absf(second.capacity_per_minute() - 10.0) < CAPACITY_EPSILON,
			"kapasite=%s" % second.capacity_per_minute())

	var refund: int = floori(CART.vehicle_price * MAP_CONFIG.vehicle_refund_percent / 100.0)
	routes.remove_vehicle(second)
	_check("Arac cikarinca yuzde iade",
			second.vehicles == 3 and regions.money == expected_money + refund,
			"para=%d beklenen=%d" % [regions.money, expected_money + refund])
	_check("Son arac cikarilamiyor",
			not routes.remove_vehicle(first) and first.vehicles == 1)
	_check("Bakim toplami: 1 + 3 arac",
			routes.total_upkeep_per_minute() == CART.vehicle_upkeep * 4,
			"bakim=%d" % routes.total_upkeep_per_minute())

	var before_remove: int = regions.money
	routes.remove_route(second)
	_check("Hat silinince araclarin iadesi, kurulum iade yok",
			routes.routes().size() == 1 and regions.money == before_remove + refund * 3,
			"para=%d beklenen=%d" % [regions.money, before_remove + refund * 3])


func _test_not_enough_money() -> void:
	var poor: MapConfig = MapConfig.new()
	poor.starting_money = CART.route_cost + CART.vehicle_price - 1
	var regions: RegionState = RegionState.new(poor)
	var routes: RouteState = RouteState.new(regions, poor)
	_check("Para yetmezse hat kurulamiyor, para degismiyor",
			routes.build(&"area1/Site1", &"area1/City", 150.0, CART) == null
			and regions.money == poor.starting_money
			and routes.build_block_reason(&"area1/Site1", &"area1/City", CART) == "Not enough money")


func _test_unlock_opens_routes() -> void:
	var regions: RegionState = RegionState.new(MAP_CONFIG)
	var routes: RouteState = RouteState.new(regions, MAP_CONFIG)
	regions.unlock(&"area2")
	var money_after_unlock: int = regions.money
	var route: MapRoute = routes.build(&"area1/City", &"area2/Site1", 300.0, CART)
	_check("Bolge acilinca hat kurulabiliyor; bolge ve hat ayni cuzdandan",
			route != null and regions.money == money_after_unlock - CART.route_cost - CART.vehicle_price
			and money_after_unlock == MAP_CONFIG.starting_money - MAP_CONFIG.first_unlock_cost,
			"para=%d" % regions.money)


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
