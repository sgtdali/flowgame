extends SceneTree

## Paket C (roadmap.md §5): üç aşamalı ilerleme ölçüm aracı.
##
## Aynı `FactorySim`/`ProgressionState`/`BlockCatalog`/`ResearchCatalog` ve
## güncel maliyetleri kullanır — araştırma önkoşulları, kaynak/örnek
## sınırları, bağlantı kuralları ve harcama kuralları ATLANMAZ. Her rota AYNI
## 1.000 altın başlangıçtan, aynı sabit demir hattından (Maden → Eritme →
## Market — `GameController._on_add_requested` ile aynı try_pay akışından
## geçerek kurulur) başlar.
##
## Ölçtüğü sıra: Elektrifikasyon → Jeneratör + Borsa → Elektrikli Hadde
## araştırması → Hadde kurulumu → Otomasyon. Bunlar HER rotada zorunlu alınır
## (üç aşamalı akışın kendisi); rotalar yalnızca ARADAKİ küçük yatırım
## politikasında ayrışır (madene mi yatırım, borsaya mı, ikisine mi, yoksa
## jeneratör çoğaltmaya mı).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/iron_progression_test.gd

## Tavan: bu kadar oyun-tick'inde otomasyona ulaşılamazsa rota "tıkandı"
## sayılır ve sahte bir sonuç raporlanmaz — bozuk bir hatta dakikalarca koşup
## sonucu denge bulgusu saymamak roadmap.md §5'in açık koşulu.
const MAX_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 40
## Manuel tahsilat aralığı — oyun saniyesi cinsinden (gerçek saniye değil).
const COLLECT_INTERVAL_TICKS: int = GameConfig.TICKS_PER_SECOND * 30
## Otomasyondan sonra sürdürülebilir geliri ölçmek için kullanılan pencere.
const MEASURE_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 4


func _initialize() -> void:
	print("")
	print("--- UC ASAMALI ILERLEME OLCUMU ---")
	print("Baslangic: %d altin, tick hizi %d/sn, tahsilat araligi %s oyun-sn, tavan %s oyun-dk" % [
		GameConfig.START_MONEY, GameConfig.TICKS_PER_SECOND,
		COLLECT_INTERVAL_TICKS / GameConfig.TICKS_PER_SECOND, MAX_TICKS / GameConfig.TICKS_PER_SECOND / 60])
	print("Not: Market Stall'un satis gelistirmesi bu turda kaldirildi (bkz.")
	print("DESIGN.md 'Market sale upgrade'); eski 'Satis odakli' rotasi artik")
	print("Power Exchange gelistirmesiyle ('Borsa odakli') temsil ediliyor.")
	print("")

	var routes: Array[Dictionary] = [
		_run_route("Biriktir", 0, 0, 0),
		_run_route("Maden odakli", 4, 0, 0),
		_run_route("Borsa odakli", 0, 4, 0),
		_run_route("Karma", 4, 4, 0),
		_run_route("Jenerator cogalt", 0, 0, 2),
	]

	for r: Dictionary in routes:
		_print_route(r)

	print("")
	print("=== OZET TABLO ===")
	print("%-16s %8s %10s %10s %10s %14s" % [
		"Rota", "Harcanan", "Otomasyon", "4x gercek", "Gelistirme", "Surdurulebilir"])
	for r: Dictionary in routes:
		if r["stalled"]:
			print("%-16s TIKANDI: %s" % [r["name"], r["stall_reason"]])
			continue
		var automation_tick: int = r["automation_tick"]
		print("%-16s %8s %10s %10s %10s %11.0f/dk" % [
			r["name"], GameConfig.format_money(r["spent"]),
			_format_game_time(automation_tick), _format_real_time_at_4x(automation_tick),
			"%d/%d/%d" % [r["mine_upgrades"], r["exchange_upgrades"], r["generators"]],
			r["sustainable_gold_per_min"],
		])
	print("(Gelistirme sutunu: maden/borsa gelistirme sayisi / toplam jenerator sayisi)")

	var any_stalled: bool = false
	for r: Dictionary in routes:
		if r["stalled"]:
			any_stalled = true
	quit(1 if any_stalled else 0)


## --- Tek bir rotanın koşumu ---------------------------------------------

## `mine_upgrade_cap`: madene en fazla kaç seviye yatırım yapılsın (max 3,
## çünkü max_level=4 -> 3 geliştirme). `exchange_upgrade_cap`: Power
## Exchange için aynısı. `extra_generator_cap`: ilk jeneratörün ÜSTÜNE kaç
## ek jeneratör+borsa çifti kurulsun (jeneratör çoğaltmanın geçerli bir
## rota olup olmadığını sınamak için — roadmap.md §5, "jenerator cogaltma
## gecerliyse aday olmali").
func _run_route(name: String, mine_upgrade_cap: int, exchange_upgrade_cap: int, extra_generator_cap: int) -> Dictionary:
	var sim := FactorySim.new()
	var progression := ProgressionState.new()
	var events: Array[Dictionary] = []
	var logged: Dictionary = {}

	# Sabit demir hattı — her rotada aynı, GameController'ın kendisinin
	# yaptığı gibi try_pay üzerinden kurulur.
	var maden: int = _build(sim, progression, BlockCatalog.MADEN_OCAGI)
	var extractor: int = _build(sim, progression, BlockCatalog.MINE_EXTRACTOR)
	var eritme: int = _build(sim, progression, BlockCatalog.ERITME)
	var sevkiyat: int = _build(sim, progression, BlockCatalog.SEVKIYAT)
	sim.connect_stations(maden, 0, extractor, 0)
	sim.connect_stations(extractor, 0, eritme, 0)
	sim.connect_stations(eritme, 0, sevkiyat, 0)
	_log_once(events, logged, sim, "demir_hatti_kuruldu")

	var mine_upgrades_done: int = 0
	var exchange_upgrades_done: int = 0
	var generators_built: int = 0
	var primary_generator: int = -1
	var exchange: int = -1
	var mill: int = -1

	while sim.tick_count < MAX_TICKS:
		# Tahsilat — otomasyon açılana kadar oyuncunun tıkladığı eylem.
		if not sim.auto_collect and sim.tick_count > 0 and sim.tick_count % COLLECT_INTERVAL_TICKS == 0:
			var collected: int = sim.collect_all()
			if collected > 0:
				_log_once(events, logged, sim, "ilk_tahsilat")

		# --- Zorunlu büyük açılışlar: her rota aynı sırayla alır. ---
		if not progression.is_unlocked(&"elektrifikasyon"):
			if progression.try_unlock(ResearchCatalog.ELEKTRIFIKASYON, sim.revenue, sim.research_counts).is_empty():
				_log_once(events, logged, sim, "elektrifikasyon_arastirmasi_alindi")
		elif primary_generator < 0:
			primary_generator = _build(sim, progression, BlockCatalog.JENERATOR)
			if primary_generator >= 0:
				generators_built += 1
				_log_once(events, logged, sim, "jenerator_kuruldu")
		elif exchange < 0:
			exchange = _build(sim, progression, BlockCatalog.ELEKTRIK_SATIS)
			if exchange >= 0:
				sim.connect_power(primary_generator, exchange)
				_log_once(events, logged, sim, "borsa_kuruldu_ilk_elektrik_satisi_mumkun")
		elif not progression.is_unlocked(&"presleme"):
			if progression.try_unlock(ResearchCatalog.PRESLEME, sim.revenue, sim.research_counts).is_empty():
				_log_once(events, logged, sim, "hadde_arastirmasi_alindi")
		elif mill < 0:
			mill = _build(sim, progression, BlockCatalog.PRES)
			if mill >= 0:
				sim.disconnect_stations(eritme, 0, sevkiyat, 0)
				sim.connect_stations(eritme, 0, mill, 0)
				sim.connect_stations(mill, 0, sevkiyat, 0)
				sim.connect_power(primary_generator, mill)
				_log_once(events, logged, sim, "hadde_kuruldu_ilk_levha_yakinda")
		elif not progression.is_unlocked(&"otomasyon"):
			if progression.try_unlock(ResearchCatalog.OTOMASYON, sim.revenue, sim.research_counts).is_empty():
				sim.auto_collect = true
				sim.collect_all()
				_log_once(events, logged, sim, "otomasyon_alindi")
				break  # Zorunlu sira tamam; olcum penceresine gec.

		# --- Rotaya özgü küçük yatırımlar. ---
		if mine_upgrades_done < mine_upgrade_cap:
			if progression.try_upgrade(sim.get_station(maden), sim.revenue).is_empty():
				mine_upgrades_done += 1
				_log_once(events, logged, sim, "ilk_maden_gelistirme")

		if exchange >= 0 and exchange_upgrades_done < exchange_upgrade_cap:
			if progression.try_upgrade(sim.get_station(exchange), sim.revenue).is_empty():
				exchange_upgrades_done += 1
				_log_once(events, logged, sim, "ilk_borsa_gelistirme")

		if extra_generator_cap > 0 and primary_generator >= 0 and generators_built <= extra_generator_cap:
			var extra_gen: int = _build(sim, progression, BlockCatalog.JENERATOR)
			if extra_gen >= 0:
				# Bir tuketici (bkz. Paket A) tek jeneratore bagli olabildigi
				# icin her ek jeneratorun KENDI borsasi olmali.
				var extra_exch: int = _build(sim, progression, BlockCatalog.ELEKTRIK_SATIS)
				if extra_exch >= 0:
					sim.connect_power(extra_gen, extra_exch)
					generators_built += 1
					_log_once(events, logged, sim, "ek_jenerator_kuruldu_%d" % generators_built)

		sim.tick()

	var reached_automation: bool = progression.is_unlocked(&"otomasyon")
	if not reached_automation:
		return {
			"name": name, "stalled": true,
			"stall_reason": _diagnose_stall(sim, progression, primary_generator, exchange, mill),
			"events": events, "spent": progression.spent,
		}

	var revenue_before: int = sim.revenue
	_run(sim, MEASURE_TICKS)
	var sustainable: float = float(sim.revenue - revenue_before) / (float(MEASURE_TICKS) / float(GameConfig.TICKS_PER_SECOND) / 60.0)

	return {
		"name": name, "stalled": false, "stall_reason": "",
		"events": events,
		"spent": progression.spent,
		"mine_upgrades": mine_upgrades_done,
		"exchange_upgrades": exchange_upgrades_done,
		"generators": generators_built,
		"automation_tick": logged.get("otomasyon_alindi", -1),
		"sustainable_gold_per_min": sustainable,
	}


func _diagnose_stall(sim: FactorySim, progression: ProgressionState, gen: int, exch: int, mill: int) -> String:
	if not progression.is_unlocked(&"elektrifikasyon"):
		return "Elektrifikasyon arastirmasina hic ulasilamadi (bakiye=%s, gerekli=%s)" % [
			GameConfig.format_money(progression.balance(sim.revenue)),
			GameConfig.format_money(ResearchCatalog.ELEKTRIFIKASYON.cost_money)]
	if gen < 0:
		return "Elektrifikasyon acildi ama Jenerator kurulamadi (bakiye yetersiz)"
	if exch < 0:
		return "Jenerator kuruldu ama Power Exchange kurulamadi (bakiye yetersiz)"
	if not progression.is_unlocked(&"presleme"):
		return "Elektrifikasyon tamamlandi ama Elektrikli Hadde arastirmasina ulasilamadi"
	if mill < 0:
		return "Hadde arastirmasi acildi ama tesis kurulamadi (bakiye yetersiz)"
	return "Hadde kuruldu ama Otomasyon arastirmasina MAX_TICKS icinde ulasilamadi"


func _print_route(r: Dictionary) -> void:
	print("")
	print("-- %s --" % r["name"])
	if r["stalled"]:
		print("  TIKANDI: %s" % r["stall_reason"])
	for e: Dictionary in r["events"]:
		print("  %-42s oyun %-8s 4x gercek %s" % [
			e["label"], _format_game_time(e["tick"]), _format_real_time_at_4x(e["tick"])])


## --- Yardımcılar --------------------------------------------------------

func _build(sim: FactorySim, progression: ProgressionState, type: BlockType) -> int:
	if type.max_instances > 0:
		var count: int = 0
		for st: SimStation in sim.stations():
			if st.type.id == type.id:
				count += 1
		if count >= type.max_instances:
			return -1
	if not progression.try_pay(type.build_cost, sim.revenue):
		return -1
	return sim.add_station(type)


func _run(sim: FactorySim, ticks: int) -> void:
	for i in ticks:
		sim.tick()


func _log_once(events: Array[Dictionary], logged: Dictionary, sim: FactorySim, label: String) -> void:
	if logged.has(label):
		return
	logged[label] = sim.tick_count
	events.append({"tick": sim.tick_count, "label": label})


func _format_game_time(ticks: int) -> String:
	if ticks < 0:
		return "N/A"
	var seconds: int = ticks / GameConfig.TICKS_PER_SECOND
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _format_real_time_at_4x(ticks: int) -> String:
	if ticks < 0:
		return "N/A"
	var seconds: int = ticks / GameConfig.TICKS_PER_SECOND / 4
	return "%d:%02d" % [seconds / 60, seconds % 60]
