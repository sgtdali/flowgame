extends SceneTree

## İlk 4 aşamalı hattın (Maden → Eritme → Sevkiyat → Tahsilat) denge koşumu.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/chain_balance.gd
##
## Gerçek `FactorySim`+`ProgressionState` üzerinde, aynı başlangıçtan, birkaç
## strateji karşılaştırılır: hiç geliştirme almadan biriktirmek, yalnızca
## üretim hızı (Maden) geliştirmeleri almak, yalnızca satış değeri (Sevkiyat)
## geliştirmeleri almak, ve ikisini farklı sıralarla almak. Yükseltmeler
## yalnızca erişilebilir bakiye ile satın alınır (bkz. `ProgressionState`).
##
## NEDEN AYRI BİR ARAÇ (balance_lib.gd DEĞİL): balance_lib.gd'nin stratejileri
## `sim.revenue`'yu doğrudan okur (tahsilat kavramı yok) ve ikinci bir
## Maden/Eritme kurarak "ayrı hat" stratejisini modeller — artık
## `max_instances=1` bunu geçersiz kılıyor (bkz. DESIGN.md D27). Bu deneyin
## sorusu da farklı: "aynı TEK hatta hangi yükseltme sırası ne zaman
## öder" — targeted/separate stratejilerin hiçbiri burada anlamlı değil.

const ARGE_COST: int = BlockCatalog.ARGE_LAB.build_cost
const HORIZON_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 20
const SAMPLE_TICKS: int = GameConfig.TICKS_PER_SECOND * 5
const CHECKPOINTS_SECONDS: Array = [60, 120, 180, 300, 600, 900]
const COLLECTION_INTERVALS_SECONDS: Array = [15.0, 30.0]
const ASSUMED_SPEED := 4.0

## Bu koşum sırasında gıda/işçi darboğaz YARATMASIN diye bol tutulur —
## gerçek START_FOOD ayrı bir doğrulama koşumunda sınanır (bkz. alttaki
## `_verify_real_start_food`).
const ANALYSIS_FOOD: int = 100000

enum Strategy { NONE, RATE_ONLY, VALUE_ONLY, RATE_THEN_VALUE, VALUE_THEN_RATE, TWO_THEN_STOP }

const STRATEGY_NAMES := {
	Strategy.NONE: "Hic gelistirme alma (biriktir)",
	Strategy.RATE_ONLY: "Sadece uretim hizi (Maden)",
	Strategy.VALUE_ONLY: "Sadece satis degeri (Sevkiyat)",
	Strategy.RATE_THEN_VALUE: "Once hiz, sonra deger",
	Strategy.VALUE_THEN_RATE: "Once deger, sonra hiz",
	Strategy.TWO_THEN_STOP: "Iki gelistirme al, sonra biriktir",
}


func _initialize() -> void:
	print("")
	print("--- HAT DENGESI: Maden -> Eritme -> Sevkiyat -> Tahsilat ---")
	print("Baslangic: %d TL | Maden yapim=%d Eritme yapim=%d Sevkiyat yapim=%d | Sonraki asama (Arge Sarayi)=%d TL" % [
		GameConfig.START_MONEY, BlockCatalog.MADEN_OCAGI.build_cost,
		BlockCatalog.ERITME.build_cost, BlockCatalog.SEVKIYAT.build_cost, ARGE_COST,
	])
	print("Maden yukseltme: taban=%d TL, buyume=x%.1f/seviye, +%.1f cevher/dk/seviye, max seviye=%d" % [
		BlockCatalog.MADEN_OCAGI.upgrade_base_cost, BlockCatalog.MADEN_OCAGI.upgrade_cost_growth,
		BlockCatalog.MADEN_OCAGI.upgrade_rate_increment, BlockCatalog.MADEN_OCAGI.max_level,
	])
	print("Sevkiyat yukseltme: taban=%d TL, buyume=x%.1f/seviye, +%%100 taban deger/seviye, max seviye=%d" % [
		BlockCatalog.SEVKIYAT.upgrade_base_cost, BlockCatalog.SEVKIYAT.upgrade_cost_growth,
		BlockCatalog.SEVKIYAT.max_level,
	])

	for interval: float in COLLECTION_INTERVALS_SECONDS:
		print("")
		print("=== Tahsilat araligi: %.0f sn ===" % interval)
		for strategy: int in STRATEGY_NAMES:
			_run_strategy(strategy, interval)

	_run_long_horizon_comparison()
	_verify_real_start_food()

	quit(0)


## Yukarıdaki tüm koşumlar ANALYSIS_FOOD (bol) kullanıyor — gerçek
## GameConfig.START_FOOD/START_WORKERS ile de "hiç geliştirme alma" (en
## uzun süren, 10 dk) yolunu bir güvenlik payıyla (16 dk) koşup gıdanın
## GERÇEKTEN yetip yetmediğini doğrular. Bu ayrı bir koşum: ANALYSIS_FOOD
## bilerek bol tutulur ki gıda, hat ekonomisi ölçümünü GÖRÜNMEZ BİR
## DARBOĞAZLA bulandırmasın (bkz. üstteki yorum) — gerçek değer burada
## ayrıca sınanır.
func _verify_real_start_food() -> void:
	print("")
	print("=== GERCEK START_FOOD DOGRULAMASI (START_FOOD=%d, isci=%d, 16 dk) ===" % [
		GameConfig.START_FOOD, GameConfig.START_WORKERS])
	var sim := FactorySim.new()
	var prog := ProgressionState.new()
	var ids: Dictionary = {}
	for entry: Array in [["maden", BlockCatalog.MADEN_OCAGI], ["eritme", BlockCatalog.ERITME], ["sevkiyat", BlockCatalog.SEVKIYAT]]:
		var type: BlockType = entry[1]
		prog.try_pay(type.build_cost, sim.revenue)
		ids[entry[0]] = sim.add_station(type)
	sim.connect_stations(ids.maden, 0, ids.eritme, 0)
	sim.connect_stations(ids.eritme, 0, ids.sevkiyat, 0)
	for station: SimStation in sim.stations():
		if station.type.requires_worker():
			sim.set_worker(station.id, true)
	# food/workers_total ZATEN GameConfig varsayılanı (FactorySim.new() onu
	# kullanır) — burada elle EZİLMİYOR, gerçek başlangıç koşulu sınanıyor.

	var horizon: int = GameConfig.TICKS_PER_SECOND * 60 * 16
	var hungry_tick: int = -1
	for t in range(1, horizon + 1):
		sim.tick()
		if sim.food_shortage and hungry_tick < 0:
			hungry_tick = t
	if hungry_tick < 0:
		print("  GECTI: 16 dk boyunca gida hic tukenmedi (food_shortage hep false).")
	else:
		print("  KALDI: gida %s aninda tukendi — START_FOOD yetersiz." % GameConfig.format_ticks(hungry_tick))


## Yukaridaki koşum "sonraki asamaya hazir" anında kesiliyor — bu yüzden
## "sonsuza kadar yukseltme almak en iyisi mi" sorusunu yanitlamiyor.
## Burada ayni 4 yolu SABIT (uzun) bir ufka kadar, ERKEN KESMEDEN kosturup
## NONE'a gore net kazanci ve harcanani karsilastiriyoruz — ROI'nin
## seviye buyudukce KOTULESTIGINI (maliyet katlanirken kazanc SABIT
## kaliyor) GERCEK simulasyonla gosteriyor, varsayimla degil.
func _run_long_horizon_comparison() -> void:
	print("")
	print("=== UZUN VADELI KARSILASTIRMA (15 dk, erken kesmeden, 15 sn tahsilat) ===")
	var horizon_ticks: int = GameConfig.TICKS_PER_SECOND * 60 * 15
	var checkpoints_sec: Array = [60, 180, 300, 600, 900]

	var none_earned: Dictionary = _run_to_horizon(Strategy.NONE, 15.0, horizon_ticks, checkpoints_sec, -1)
	var rate_max: Dictionary = _run_to_horizon(Strategy.RATE_ONLY, 15.0, horizon_ticks, checkpoints_sec, -1)
	var value_max: Dictionary = _run_to_horizon(Strategy.VALUE_ONLY, 15.0, horizon_ticks, checkpoints_sec, -1)
	var both_max: Dictionary = _run_to_horizon(Strategy.RATE_THEN_VALUE, 15.0, horizon_ticks, checkpoints_sec, -1)

	for sec: int in checkpoints_sec:
		print("  t=%4ds  NONE=%-6d  RATE_MAX=%-6d (+%-6d harcanan:%-4d)  VALUE_MAX=%-6d (+%-6d harcanan:%-4d)  BOTH_MAX=%-6d (+%-6d harcanan:%-4d)" % [
			sec, none_earned.earned[sec],
			rate_max.earned[sec], rate_max.earned[sec] - none_earned.earned[sec], rate_max.spent_by[sec],
			value_max.earned[sec], value_max.earned[sec] - none_earned.earned[sec], value_max.spent_by[sec],
			both_max.earned[sec], both_max.earned[sec] - none_earned.earned[sec], both_max.spent_by[sec],
		])


## `_run_strategy` ile ayni satin alma mantigini kullanir ama ERKEN KESMEZ —
## `max_purchases`: -1 = sinirsiz (tip zaten max_level'da doğal olarak durur).
func _run_to_horizon(
	strategy: int, collection_interval_seconds: float, horizon_ticks: int,
	checkpoints_sec: Array, _unused: int
) -> Dictionary:
	var sim := FactorySim.new()
	var prog := ProgressionState.new()
	var ids: Dictionary = _build_chain(sim, prog)
	var maden: SimStation = sim.get_station(ids.maden)
	var sevkiyat: SimStation = sim.get_station(ids.sevkiyat)
	var collection_interval_ticks: int = maxi(1, roundi(collection_interval_seconds * GameConfig.TICKS_PER_SECOND))

	var earned: Dictionary = {}
	var spent_by: Dictionary = {}
	var remaining: Array = checkpoints_sec.duplicate()
	var purchases: Array = []
	var upgrades_bought: int = 0
	var total_spent: int = 0

	for t in range(1, horizon_ticks + 1):
		sim.tick()
		if t % collection_interval_ticks == 0:
			sim.collect_all()
			var before: int = prog.spent
			upgrades_bought = _maybe_purchase(strategy, prog, sim, maden, sevkiyat, upgrades_bought, purchases, t)
			total_spent += prog.spent - before
		if not remaining.is_empty() and t >= remaining[0] * GameConfig.TICKS_PER_SECOND:
			var sec: int = remaining.pop_front()
			earned[sec] = sim.revenue + sim.total_uncollected()
			# Yalnizca YUKSELTMEYE harcanan — insa maliyeti (650) her stratejide
			# ayni, karsilastirmadan cikarilmasi gerekmiyor ama net kazanci
			# harcamadan ayirmak icin ayri tutuyoruz.
			spent_by[sec] = total_spent

	return {"earned": earned, "spent_by": spent_by}


func _run_strategy(strategy: int, collection_interval_seconds: float) -> void:
	var sim := FactorySim.new()
	var prog := ProgressionState.new()
	var ids: Dictionary = _build_chain(sim, prog)
	var maden: SimStation = sim.get_station(ids.maden)
	var sevkiyat: SimStation = sim.get_station(ids.sevkiyat)

	var collection_interval_ticks: int = maxi(1, roundi(collection_interval_seconds * GameConfig.TICKS_PER_SECOND))
	var checkpoints: Array = CHECKPOINTS_SECONDS.duplicate()
	var earned_at: Dictionary = {}
	var purchases: Array = []
	var stage2_ready_tick: int = -1
	var upgrades_bought: int = 0

	for t in range(1, HORIZON_TICKS + 1):
		sim.tick()

		if t % collection_interval_ticks == 0:
			sim.collect_all()
			upgrades_bought = _maybe_purchase(strategy, prog, sim, maden, sevkiyat, upgrades_bought, purchases, t)

		if not checkpoints.is_empty() and t >= checkpoints[0] * GameConfig.TICKS_PER_SECOND:
			var sec: int = checkpoints.pop_front()
			earned_at[sec] = sim.revenue + sim.total_uncollected()

		if stage2_ready_tick < 0:
			var have_money: bool = prog.balance(sim.revenue) >= ARGE_COST
			var gate_open: bool = prog.is_block_available(BlockCatalog.ARGE_LAB, t)
			if have_money and gate_open:
				stage2_ready_tick = t
				break

	print("")
	print("-- %s --" % STRATEGY_NAMES[strategy])
	if stage2_ready_tick >= 0:
		print("  Sonraki asamaya hazir: %s oyun-zamani (%s gercek-zaman @4x)" % [
			GameConfig.format_ticks(stage2_ready_tick), _real_time_text(stage2_ready_tick)])
	else:
		print("  Sonraki asamaya %d dk icinde ULASILAMADI." % (HORIZON_TICKS / GameConfig.TICKS_PER_SECOND / 60))
	for sec: int in CHECKPOINTS_SECONDS:
		if earned_at.has(sec):
			print("  %4ds toplam kazanc: %d TL" % [sec, earned_at[sec]])
	for entry: Dictionary in purchases:
		print("  [%s] %s -> seviye %d, bedel %d TL" % [
			GameConfig.format_ticks(entry.tick), entry.label, entry.level, entry.cost])


## Strateji tek bir tahsilat aninda EN FAZLA bir satin alma dener — gercek
## oyuncu ritmine yakin (D27'deki intro_timing.gd ile ayni yaklasim).
func _maybe_purchase(
	strategy: int, prog: ProgressionState, sim: FactorySim,
	maden: SimStation, sevkiyat: SimStation, bought_so_far: int, log: Array, tick: int
) -> int:
	var priority: Array[SimStation] = []
	match strategy:
		Strategy.NONE:
			return bought_so_far
		Strategy.RATE_ONLY:
			priority = [maden]
		Strategy.VALUE_ONLY:
			priority = [sevkiyat]
		Strategy.RATE_THEN_VALUE:
			priority = [maden, sevkiyat]
		Strategy.VALUE_THEN_RATE:
			priority = [sevkiyat, maden]
		Strategy.TWO_THEN_STOP:
			if bought_so_far >= 2:
				return bought_so_far
			priority = [maden, sevkiyat]

	for station: SimStation in priority:
		if not prog.upgrade_problem(station, sim.revenue).is_empty():
			continue
		var cost: int = ProgressionState.upgrade_cost(station.type, station.level)
		var problem: String = prog.try_upgrade(station, sim.revenue)
		if problem.is_empty():
			log.append({
				"tick": tick, "label": station.type.display_name,
				"level": station.level, "cost": cost,
			})
			return bought_so_far + 1
	return bought_so_far


## `prog`'a da inşa maliyetini düşer — gerçek oyunda `GameController.
## _on_add_requested` her kurulumda `try_pay` çağırır, burada da aynısı
## yapılmazsa bakiye yanlışlıkla START_MONEY'nin tamamıymış gibi görünür.
func _build_chain(sim: FactorySim, prog: ProgressionState) -> Dictionary:
	var ids: Dictionary = {}
	for entry: Array in [["maden", BlockCatalog.MADEN_OCAGI], ["eritme", BlockCatalog.ERITME], ["sevkiyat", BlockCatalog.SEVKIYAT]]:
		var type: BlockType = entry[1]
		prog.try_pay(type.build_cost, sim.revenue)
		ids[entry[0]] = sim.add_station(type)
	sim.connect_stations(ids.maden, 0, ids.eritme, 0)
	sim.connect_stations(ids.eritme, 0, ids.sevkiyat, 0)
	sim.workers_total = 10
	sim.food = ANALYSIS_FOOD
	for station: SimStation in sim.stations():
		if station.type.requires_worker():
			sim.set_worker(station.id, true)
	return ids


func _real_time_text(ticks: int) -> String:
	var real_seconds: float = float(ticks) / float(GameConfig.TICKS_PER_SECOND) / ASSUMED_SPEED
	if real_seconds >= 60.0:
		return "%.1f dk" % (real_seconds / 60.0)
	return "%.0f sn" % real_seconds
