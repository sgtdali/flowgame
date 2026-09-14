extends SceneTree

const DeliveryRateMeter = preload("res://common/delivery_rate_meter.gd")

var checks: int = 0
var failures: int = 0


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS  ", label)
	else:
		failures += 1
		push_error("FAIL  " + label)


func _initialize() -> void:
	var sim := FactorySim.new()
	_check(sim.workers_total == GameConfig.START_WORKERS and sim.food == GameConfig.START_FOOD, "starting workforce and food")

	var mine: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	sim.tick()
	_check(sim.get_station(mine).status == SimStation.Status.UNSTAFFED, "unstaffed mine pauses")
	_check(sim.get_station(mine).produced_total == 0, "unstaffed mine produces nothing")
	_check(sim.set_worker(mine, true), "worker assigned")
	for i in 30:
		sim.tick()
	_check(sim.get_station(mine).produced_total > 0, "staffed mine produces")

	var farm: int = sim.add_station(BlockCatalog.FARM)
	var mill: int = sim.add_station(BlockCatalog.MILL)
	var bakery: int = sim.add_station(BlockCatalog.BAKERY)
	var granary: int = sim.add_station(BlockCatalog.GRANARY)
	_check(sim.set_worker(farm, true) and sim.set_worker(mill, true) and sim.set_worker(bakery, true), "food chain staffed")
	_check(sim.connect_stations(farm, 0, mill, 0) and sim.connect_stations(mill, 0, bakery, 0) and sim.connect_stations(bakery, 0, granary, 0), "food chain connected")
	var food_before: int = sim.food
	var actual_meter := DeliveryRateMeter.new()
	actual_meter.sample(sim.tick_count, sim.food_produced_total)
	var actual_low: float = 100000.0
	var actual_high: float = 0.0
	for i in 1000:
		sim.tick()
		actual_meter.sample(sim.tick_count, sim.food_produced_total)
		if i >= 500:
			actual_low = minf(actual_low, actual_meter.per_minute())
			actual_high = maxf(actual_high, actual_meter.per_minute())
	_check(sim.food > food_before and sim.food_produced_total > 0, "bread replenishes food after upkeep")
	_check(actual_low >= 14.0 and actual_high <= 16.0, "live food chain holds near 15 food/min")
	var food_to_recruit: int = sim.food
	_check(sim.recruit_worker(), "food recruits a worker")
	_check(sim.food == food_to_recruit - GameConfig.RECRUIT_FOOD_COST and sim.workers_total == GameConfig.START_WORKERS + 1, "recruitment costs food")
	var restored := FactorySim.new()
	restored.from_dict(sim.to_dict())
	_check(restored.food == sim.food and restored.food_produced_total == sim.food_produced_total and restored.workers_total == sim.workers_total and restored.workers_assigned() == sim.workers_assigned(), "workforce and food survive save/load")
	var legacy: Dictionary = sim.to_dict()
	legacy.erase("food")
	legacy.erase("workers_total")
	legacy.erase("food_shortage")
	for entry: Dictionary in legacy["stations"]:
		entry.erase("assigned_worker")
	var migrated := FactorySim.new()
	migrated.from_dict(legacy)
	_check(migrated.workers_assigned() == sim.workers_assigned() and migrated.workers_total >= migrated.workers_assigned(), "old saves migrate staffed workshops")

	var unlimited := FactorySim.new()
	var last_id: int = -1
	for i in GameConfig.START_WORKERS + 1:
		last_id = unlimited.add_station(BlockCatalog.MADEN_OCAGI)
		if i < GameConfig.START_WORKERS:
			unlimited.set_worker(last_id, true)
	_check(unlimited.station_count() == GameConfig.START_WORKERS + 1 and not unlimited.set_worker(last_id, true), "no node cap; workforce limits staffing")

	var hungry := FactorySim.new()
	hungry.food = 0
	var hungry_mine: int = hungry.add_station(BlockCatalog.MADEN_OCAGI)
	hungry.set_worker(hungry_mine, true)
	for i in GameConfig.TICKS_PER_SECOND * 60:
		hungry.tick()
	_check(hungry.food_shortage and hungry.get_station(hungry_mine).status == SimStation.Status.HUNGRY, "food shortage pauses industry")
	var hf: int = hungry.add_station(BlockCatalog.FARM)
	var hm: int = hungry.add_station(BlockCatalog.MILL)
	var hb: int = hungry.add_station(BlockCatalog.BAKERY)
	var hg: int = hungry.add_station(BlockCatalog.GRANARY)
	hungry.set_worker(hf, true)
	hungry.set_worker(hm, true)
	hungry.set_worker(hb, true)
	hungry.connect_stations(hf, 0, hm, 0)
	hungry.connect_stations(hm, 0, hb, 0)
	hungry.connect_stations(hb, 0, hg, 0)
	for i in GameConfig.TICKS_PER_SECOND * 120:
		hungry.tick()
	_check(hungry.food > 0 and not hungry.food_shortage, "food chain recovers from shortage")
	var meter := DeliveryRateMeter.new()
	var delivered: int = 0
	var lowest: float = 100000.0
	var highest: float = 0.0
	for tick in 1000:
		if tick % 80 == 0 or tick % 80 == 1:
			delivered += 1
		meter.sample(tick, delivered)
		if tick >= 400:
			lowest = minf(lowest, meter.per_minute())
			highest = maxf(highest, meter.per_minute())
	_check(lowest >= 14.0 and highest <= 16.0, "batched bread delivery shows a steady 15 food/min")
	for tick in range(1000, 1200):
		meter.sample(tick, delivered)
	_check(meter.per_minute() < 8.0, "delivery rate falls when food stops arriving")
	print("Workforce checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)
