extends SceneTree

## Fabrika içi testi (veri ve parça simülasyonu, arayüzsüz).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/factory_test.gd
##
## Kanıtlar (görev 05 adım 1): haritanın malları düğüm editörünün mal türüdür;
## fabrika blokları doğru tarif ve hızla gelir; kapılar her mal için şablondan
## üretilir ve portları malına kilitlidir.
## (adım 2): giriş stoğu → giriş kapısı → Sawmill → çıkış kapısı → çıkış stoğu;
## Sawmill 10/dk; çıkış stoğu dolunca içerisi tıkanır; Mill 2 Wheat → 1 Flour;
## Splitter iki kola böler; doğrudan aktarma; giriş kapısı kendiliğinden gelir
## ve silinmez; giriş stoğu sınırı; belirlilik.

const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
const LOGS: RawResource = preload("res://data/raw_resources/tomruk.tres")
const WHEAT: RawResource = preload("res://data/raw_resources/bugday.tres")
const LUMBER: Good = preload("res://data/goods/kereste.tres")
const FLOUR: Good = preload("res://data/goods/un.tres")
const SAWMILL: BlockType = preload("res://data/factory_blocks/sawmill.tres")
const MILL: BlockType = preload("res://data/factory_blocks/mill.tres")
const SPLITTER: BlockType = preload("res://data/factory_blocks/splitter.tres")
## Bir adım: 1 oyun saniyesi (harita da böyle adımlar).
const DT: float = 1.0 / 60.0

var _failures: int = 0
var _checks: int = 0

const EXPECTED_CHECKS: int = 20


func _initialize() -> void:
	print("")
	_test_data()
	_test_sawmill_line()
	_test_output_full()
	_test_mill_and_splitter()
	_test_pass_through_and_gates()
	_test_determinism()

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


## Oyun dakikasında üretilen çıktı: süre tick cinsinden, saat eski oyunla aynı hızda.
static func _per_minute(block: BlockType) -> float:
	return float(GameConfig.TICKS_PER_SECOND) * 60.0 / block.duration_ticks_at_level(1)


func _test_data() -> void:
	_check("Haritanin mallari duzum editorunun mal turu (ItemType)",
			(LOGS as Variant) is ItemType and (LUMBER as Variant) is ItemType
			and LOGS.display_name == "Logs" and LUMBER.city_price == 1)
	_check("Sawmill: 1 Logs -> 1 Lumber, 10/dk",
			SAWMILL.input_items() == [LOGS] and SAWMILL.output_items() == [LUMBER]
			and SAWMILL.recipe.inputs[0].count == 1
			and is_equal_approx(_per_minute(SAWMILL), 10.0),
			"%.2f/dk" % _per_minute(SAWMILL))
	_check("Mill: 2 Wheat -> 1 Flour, 10/dk",
			MILL.input_items() == [WHEAT] and MILL.output_items() == [FLOUR]
			and MILL.recipe.inputs[0].count == 2
			and is_equal_approx(_per_minute(MILL), 10.0))
	_check("Palette Sawmill, Mill, Splitter, Depot var",
			MAP_CONFIG.factory_blocks.size() == 4
			and MAP_CONFIG.factory_blocks.has(SAWMILL) and MAP_CONFIG.factory_blocks.has(MILL))

	var gate_in: FactoryGate = MAP_CONFIG.gate_in.for_good(LOGS)
	_check("Giris kapisi: girisi yok, cikisi Logs'a kilitli",
			gate_in.direction == FactoryGate.Direction.IN and gate_in.good == LOGS
			and gate_in.input_labels().is_empty() and gate_in.output_items() == [LOGS]
			and gate_in.display_name == "Logs in",
			"%s / %s" % [gate_in.display_name, gate_in.input_labels()])
	var gate_out: FactoryGate = MAP_CONFIG.gate_out.for_good(LUMBER)
	_check("Cikis kapisi: cikisi yok, girisi Lumber'a kilitli",
			gate_out.direction == FactoryGate.Direction.OUT
			and gate_out.output_labels().is_empty() and gate_out.input_items() == [LUMBER]
			and gate_out.display_name == "Output: Lumber",
			"%s / %s" % [gate_out.display_name, gate_out.output_labels()])
	_check("Kapi uretmek sablonu degistirmiyor",
			MAP_CONFIG.gate_in.good == null and MAP_CONFIG.gate_in.recipe == null
			and gate_in.id != MAP_CONFIG.gate_out.for_good(LOGS).id)


## Giriş stoğunu her adımda doldurarak `minutes` oyun dakikası koşar.
func _run(factory: FactoryInterior, minutes: float, feed: Array[Good] = []) -> void:
	for i: int in roundi(minutes * 60.0):
		for good: Good in feed:
			factory.add_input(good, factory.input_space(good))
		factory.advance(DT)


func _connect(factory: FactoryInterior, from_id: int, from_port: int, to_id: int, to_port: int) -> bool:
	var ok: bool = factory.connect_stations(from_id, from_port, to_id, to_port)
	if not ok:
		print("         baglanti kurulamadi: %s" % factory.connection_problem(
				from_id, from_port, to_id, to_port))
	return ok


## Logs in → Sawmill → Output: Lumber. Dönüş: [fabrika, sawmill id].
func _sawmill_factory() -> Array:
	var factory: FactoryInterior = FactoryInterior.new(MAP_CONFIG)
	var gate: int = factory.ensure_input_gate(LOGS)
	var saw: int = factory.add_station(SAWMILL)
	var out: int = factory.add_output_gate(LUMBER)
	_connect(factory, gate, 0, saw, 0)
	_connect(factory, saw, 0, out, 0)
	return [factory, saw]


func _test_sawmill_line() -> void:
	var built: Array = _sawmill_factory()
	var factory: FactoryInterior = built[0]
	_run(factory, 1.0, [LOGS])  # ısınma: boru hattı dolsun
	var before: float = factory.output_stock(LUMBER)
	_run(factory, 3.0, [LOGS])
	var made: float = factory.output_stock(LUMBER) - before
	_check("Sawmill 10/dk Lumber uretip cikis stoguna koyuyor",
			absf(made - 30.0) <= 1.0, "3 dk = %.1f" % made)
	_check("Giris stogu hattan beslenince kapi Logs cekiyor",
			factory.get_station(factory.input_gate_id(LOGS)).produced_total >= 40)


func _test_output_full() -> void:
	var built: Array = _sawmill_factory()
	var factory: FactoryInterior = built[0]
	_run(factory, 8.0, [LOGS])
	var saw: SimStation = factory.get_station(built[1])
	_check("Cikis stogu 50'de duruyor", is_equal_approx(factory.output_stock(LUMBER), 50.0),
			"stok=%.1f" % factory.output_stock(LUMBER))
	_check("Cikis dolunca Sawmill tikaniyor", saw.status == SimStation.Status.BLOCKED,
			"durum=%s" % SimStation.status_name(saw.status))
	_check("En dolu cikis stogu haritadaki cubuga 1.0 veriyor; cikissiz fabrika -1",
			is_equal_approx(factory.fullest_output(), 1.0)
			and FactoryInterior.new(MAP_CONFIG).fullest_output() < 0.0)
	factory.take_output(LUMBER, 20.0)
	_run(factory, 0.5, [LOGS])
	_check("Cikis bosalinca Sawmill yeniden calisiyor",
			factory.output_stock(LUMBER) > 30.0 and saw.status != SimStation.Status.BLOCKED)


func _test_mill_and_splitter() -> void:
	var factory: FactoryInterior = FactoryInterior.new(MAP_CONFIG)
	var gate: int = factory.ensure_input_gate(WHEAT)
	var mill: int = factory.add_station(MILL)
	var out: int = factory.add_output_gate(FLOUR)
	_connect(factory, gate, 0, mill, 0)
	_connect(factory, mill, 0, out, 0)
	_run(factory, 1.0, [WHEAT])
	var gate_before: int = factory.get_station(gate).produced_total
	var before: float = factory.output_stock(FLOUR)
	_run(factory, 3.0, [WHEAT])
	var flour: float = factory.output_stock(FLOUR) - before
	var wheat: int = factory.get_station(gate).produced_total - gate_before
	_check("Mill 2 Wheat -> 1 Flour, 10/dk", absf(flour - 30.0) <= 1.0 and absi(wheat - 60) <= 6,
			"3 dk: Flour %.1f, Wheat %d" % [flour, wheat])

	var split: FactoryInterior = FactoryInterior.new(MAP_CONFIG)
	var logs: int = split.ensure_input_gate(LOGS)
	var splitter: int = split.add_station(SPLITTER)
	var saw_a: int = split.add_station(SAWMILL)
	var saw_b: int = split.add_station(SAWMILL)
	var lumber: int = split.add_output_gate(LUMBER)
	var wired: bool = (_connect(split, logs, 0, splitter, 0)
			and _connect(split, splitter, 0, saw_a, 0) and _connect(split, splitter, 1, saw_b, 0)
			and _connect(split, saw_a, 0, lumber, 0) and _connect(split, saw_b, 0, lumber, 0))
	_run(split, 1.0, [LOGS])
	split.take_output(LUMBER, float(split.capacity))  # 2 dk'lık üretim stoğa sığsın
	_run(split, 2.0, [LOGS])
	_check("Splitter iki Sawmill'i besliyor (20/dk)",
			wired and absf(split.output_stock(LUMBER) - 40.0) <= 2.0,
			"2 dk = %.1f" % split.output_stock(LUMBER))


func _test_pass_through_and_gates() -> void:
	var factory: FactoryInterior = FactoryInterior.new(MAP_CONFIG)
	_check("Bos fabrikada kapi yok", factory.station_count() == 0 and factory.input_gate_id(LOGS) == -1)
	var accepted: float = factory.add_input(LOGS, 80.0)
	var gate: int = factory.input_gate_id(LOGS)
	_check("Mal gelince giris kapisi kendiliginden geliyor, stok 50'yi asmiyor",
			gate != -1 and is_equal_approx(accepted, 50.0) and factory.station_count() == 1)
	factory.add_input(LOGS, 1.0)
	factory.remove_station(gate)
	_check("Ayni mal ikinci kez kapi kurmuyor; giris kapisi silinmiyor",
			factory.station_count() == 1 and factory.get_station(gate) != null
			and not factory.can_remove(gate))
	var out: int = factory.add_output_gate(LOGS)
	_connect(factory, gate, 0, out, 0)
	_run(factory, 0.2)
	_check("Giris kapisi dogrudan cikis kapisina baglanip aktarma yapiyor",
			is_equal_approx(factory.output_stock(LOGS), 50.0)
			and factory.input_stock(LOGS) < 1.0 and factory.output_goods() == [LOGS],
			"cikis=%.1f giris=%.1f" % [factory.output_stock(LOGS), factory.input_stock(LOGS)])


func _test_determinism() -> void:
	var first: FactoryInterior = _sawmill_factory()[0]
	var second: FactoryInterior = _sawmill_factory()[0]
	_run(first, 3.0, [LOGS])
	_run(second, 3.0, [LOGS])
	_check("Ayni kurulum ayni sonucu veriyor",
			first.state_hash() == second.state_hash()
			and first.output_stock(LUMBER) == second.output_stock(LUMBER))


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
