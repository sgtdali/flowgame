extends SceneTree

## Fabrika içi testi (veri ve parça simülasyonu, arayüzsüz).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/factory_test.gd
##
## Kanıtlar (görev 05 adım 1): haritanın malları düğüm editörünün mal türüdür;
## fabrika blokları doğru tarif ve hızla gelir; kapılar her mal için şablondan
## üretilir ve portları malına kilitlidir.

const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
const LOGS: RawResource = preload("res://data/raw_resources/tomruk.tres")
const WHEAT: RawResource = preload("res://data/raw_resources/bugday.tres")
const LUMBER: Good = preload("res://data/goods/kereste.tres")
const FLOUR: Good = preload("res://data/goods/un.tres")
const SAWMILL: BlockType = preload("res://data/factory_blocks/sawmill.tres")
const MILL: BlockType = preload("res://data/factory_blocks/mill.tres")

var _failures: int = 0
var _checks: int = 0

const EXPECTED_CHECKS: int = 7


func _initialize() -> void:
	print("")
	_test_data()

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


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
