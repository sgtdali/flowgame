extends SceneTree

## Simülasyon test ve denge koşumu.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/sim_test.gd
##
## Dört şeyi kanıtlar:
##   1. Determinizm   — aynı kurulum + aynı tick = aynı durum parmak izi
##   2. Kaydet/yükle  — kayıttan devam eden koşum, kesintisiz koşumla aynı
##   3. Tıkanma       — çıkışı olmayan istasyon dolunca durur, zincir geriye yürür
##   4. Denge         — 1 saatlik koşumda gerçek üretim ve gelir ne oluyor
##
## 4. madde tasarım belgesindeki en büyük riskin ("60 dakikalık tempo ilk
## denemede tutmaz") azaltmasıdır: tahmin etmek yerine ölçeriz.

const HOUR_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 60

var _failures: int = 0
var _checks: int = 0

## Beklenen kontrol sayisi. Bir derleme hatasi yuzunden testler hic
## calismazsa _failures 0 kalir ve kosum yanlislikla "gecti" der.
## Bu tam olarak bir kez basimiza geldi; sayac o yuzden var.
const EXPECTED_CHECKS: int = 35


func _initialize() -> void:
	print("")
	_test_determinism()
	_test_save_load()
	_test_legacy_food_save_migration()
	_test_blocking()
	_test_backpressure_chain()
	_test_starved()

	# roadmap.md Paket B — guc/para dogrulugu senaryolari.
	_test_power_solo_generator_sale()
	_test_power_full_mill_produces()
	_test_power_zero_power_no_progress()
	_test_power_partial_slows_proportionally()
	_test_power_no_ingots_frees_capacity_for_sale()
	_test_power_blocked_output_does_not_overflow_energy()
	_test_power_production_and_sale_share_capacity()
	_test_power_multiple_sale_points_split_not_duplicate()
	_test_power_consumer_cannot_double_connect()
	_test_power_disconnect_stops_delivery()
	_test_power_collect_does_not_double()
	_test_power_automation_transition_sweeps_once()
	_test_power_save_load_mid_batch()

	print("")
	if _checks < EXPECTED_CHECKS:
		print("SONUC: SADECE %d/%d kontrol calisti — testler cokmus olmali." % [
			_checks, EXPECTED_CHECKS])
		quit(1)
		return
	if _failures == 0:
		print("SONUC: %d kontrolun tamami gecti." % _checks)
	else:
		print("SONUC: %d/%d kontrol BASARISIZ." % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


## --- Referans hat -----------------------------------------------------------

## Tasarımdaki örnek hattı kurar ve istasyon id'lerini döndürür: demir
## (Maden -> Eritme -> Elektrikli Hadde -> Market) ve elektrik (Jeneratör ->
## Hadde'nin güç girişi + Power Exchange, kalan kapasite satışa gider).
func _build_reference_line(sim: FactorySim) -> Dictionary:
	var ids: Dictionary = {
		"maden": sim.add_station(BlockCatalog.MADEN_OCAGI),
		"extractor": sim.add_station(BlockCatalog.MINE_EXTRACTOR),
		"eritme": sim.add_station(BlockCatalog.ERITME),
		"jenerator": sim.add_station(BlockCatalog.JENERATOR),
		"pres": sim.add_station(BlockCatalog.PRES),
		"borsa": sim.add_station(BlockCatalog.ELEKTRIK_SATIS),
		"sevkiyat": sim.add_station(BlockCatalog.SEVKIYAT),
	}
	var wires: Array = [
		[ids.maden, 0, ids.extractor, 0],
		[ids.extractor, 0, ids.eritme, 0],
		[ids.eritme, 0, ids.pres, 0],
		[ids.pres, 0, ids.sevkiyat, 0],
	]
	for wire: Array in wires:
		if not sim.connect_stations(wire[0], wire[1], wire[2], wire[3]):
			_fail("Baglanti kurulamadi: %s" % [wire])
	if not sim.connect_power(ids.jenerator, ids.pres):
		_fail("Guc baglantisi kurulamadi: jenerator -> pres")
	if not sim.connect_power(ids.jenerator, ids.borsa):
		_fail("Guc baglantisi kurulamadi: jenerator -> borsa")
	return ids


func _run(sim: FactorySim, ticks: int) -> void:
	for i in ticks:
		sim.tick()


## --- Testler ----------------------------------------------------------------

func _test_determinism() -> void:
	var a := FactorySim.new()
	var b := FactorySim.new()
	_build_reference_line(a)
	_build_reference_line(b)
	_run(a, 5000)
	_run(b, 5000)
	_check("Determinizm: iki ayni kosum ayni parmak izi",
		a.state_hash() == b.state_hash(),
		"a=%s b=%s" % [a.state_hash().substr(0, 12), b.state_hash().substr(0, 12)])


func _test_save_load() -> void:
	var reference := FactorySim.new()
	_build_reference_line(reference)
	_run(reference, 3000)

	var resumed := FactorySim.new()
	_build_reference_line(resumed)
	_run(resumed, 1500)
	var snapshot: Dictionary = resumed.to_dict()

	# JSON turundan geciriyoruz: gercek kayit yolu bu, tip kaybi varsa burada cikar.
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var loaded := FactorySim.new()
	loaded.from_dict(round_tripped as Dictionary)
	_run(loaded, 1500)

	_check("Kaydet/yukle: kayittan devam = kesintisiz kosum",
		loaded.state_hash() == reference.state_hash(),
		"kayit=%s kesintisiz=%s" % [
			loaded.state_hash().substr(0, 12), reference.state_hash().substr(0, 12)])
	_check("Kaydet/yukle: gelir korundu",
		loaded.revenue == reference.revenue,
		"kayit=%d kesintisiz=%d" % [loaded.revenue, reference.revenue])


## v3/v4 kaydındaki kaldırılmış tarım düğümleri ve bağlantıları, demir hattını
## bozmadan atılmalı; işçi/yiyecek alanları da yeni simülasyona taşınmamalı.
func _test_legacy_food_save_migration() -> void:
	var before := FactorySim.new()
	var mine := before.add_station(BlockCatalog.MADEN_OCAGI)
	var extractor := before.add_station(BlockCatalog.MINE_EXTRACTOR)
	var hearth := before.add_station(BlockCatalog.ERITME)
	var market := before.add_station(BlockCatalog.SEVKIYAT)
	before.connect_stations(mine, 0, extractor, 0)
	before.connect_stations(extractor, 0, hearth, 0)
	before.connect_stations(hearth, 0, market, 0)
	var legacy: Dictionary = before.to_dict()
	legacy["food"] = 0
	legacy["workers_total"] = 99
	legacy["stations"].append({"id": 99, "type_id": "farm", "input": {}, "output": {}, "assigned_workers": 4})
	legacy["links"].append({"from": 99, "from_port": 0, "to": mine, "to_port": 0})
	var loaded := FactorySim.new()
	loaded.from_dict(legacy)
	_check("Eski kayit: tarim dugumu atlandi, demir istasyonlari korundu",
		loaded.station_count() == 4, "istasyon=%d" % loaded.station_count())
	_check("Eski kayit: sahipsiz tarim baglantisi atlandi",
		loaded.link_count() == 3, "baglanti=%d" % loaded.link_count())
	# bkz. _test_power_full_mill_produces'taki not: ilk kulce icin ~7500 tick gerekir.
	_run(loaded, 10000)
	_check("Eski kayit: kalan demir hatti uretmeye devam ediyor",
		loaded.total_uncollected() > 0, "bekleyen=%d" % loaded.total_uncollected())


func _test_blocking() -> void:
	# Cikisi hicbir yere bagli olmayan bir eritme: tamponu dolunca DURMALI.
	var sim := FactorySim.new()
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var extractor: int = sim.add_station(BlockCatalog.MINE_EXTRACTOR)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	sim.connect_stations(maden, 0, extractor, 0)
	sim.connect_stations(extractor, 0, eritme, 0)
	# 1 kulce = 60 cevher = 6000 ham cevher; kapasitesi 4 kulceye (24.000 ham
	# cevher) ulasip DURMASI icin madenin 8/sn hizinda ~30.000 tick gerekir
	# (bkz. r_cevher.tres: 1 cevher icin 100 ham cevher, r_ham_cevher.tres:
	# 8/sn) — pay birak diye biraz fazlasi verildi.
	_run(sim, 35000)

	var station: SimStation = sim.get_station(eritme)
	var capacity: int = BlockCatalog.ERITME.output_capacity
	_check("Tikanma: cikisi bagli olmayan istasyon kapasitede duruyor",
		station.total_output() == capacity and station.status == SimStation.Status.BLOCKED,
		"cikti=%d/%d durum=%s" % [station.total_output(), capacity, station.status_label()])


func _test_backpressure_chain() -> void:
	# Tikanma GERIYE yurumeli: eritme tikalyinca maden ocagi da dolup durmali.
	var sim := FactorySim.new()
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var extractor: int = sim.add_station(BlockCatalog.MINE_EXTRACTOR)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	sim.connect_stations(maden, 0, extractor, 0)
	sim.connect_stations(extractor, 0, eritme, 0)
	_run(sim, 35000)  # bkz. _test_blocking'deki not — 100 ham cevher/cevher zinciri uzun

	var source: SimStation = sim.get_station(maden)
	_check("Tikanma zinciri: kaynak da doldu ve durdu",
		source.status == SimStation.Status.BLOCKED
			and source.total_output() == BlockCatalog.MADEN_OCAGI.output_capacity,
		"kaynak cikti=%d durum=%s" % [source.total_output(), source.status_label()])



func _test_starved() -> void:
	# Cikisi ACIK ama girdisi gelmiyor: AC olmali, TIKALI degil.
	# Onceki testten farki: orada cikis da kapaliydi, o yuzden TIKALI ciyordu.
	var sim := FactorySim.new()
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	sim.connect_stations(eritme, 0, sevkiyat, 0)
	_run(sim, 200)

	var station: SimStation = sim.get_station(eritme)
	_check("Ac/tikali ayrimi: cikisi acik, girdisi yok -> AC",
		station.status == SimStation.Status.STARVED,
		"durum=%s giris=%d cikis=%d" % [
			station.status_label(), station.total_input(), station.total_output()])


## --- Guc testleri (roadmap.md Paket B) --------------------------------------

## Senaryo: yalniz jenerator + satis, demirsiz.
func _test_power_solo_generator_sale() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	if not sim.connect_power(gen, exch):
		_fail("Guc baglantisi kurulamadi: jenerator -> borsa")
		return
	_run(sim, 2000)
	_check("Guc: demirsiz, yalniz jenerator+satis gelir uretiyor",
		sim.total_uncollected() > 0, "bekleyen=%d" % sim.total_uncollected())
	_check("Guc: tek tuketicili satis noktasi tam kapasiteyi aliyor",
		sim.delivered_power(exch) == sim.power_capacity(gen),
		"teslim=%d kapasite=%d" % [sim.delivered_power(exch), sim.power_capacity(gen)])


## Senaryo: tam guclu hadde recetesine uygun kulce tuketip levha uretiyor mu.
func _test_power_full_mill_produces() -> void:
	var sim := FactorySim.new()
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var extractor: int = sim.add_station(BlockCatalog.MINE_EXTRACTOR)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	sim.connect_stations(maden, 0, extractor, 0)
	sim.connect_stations(extractor, 0, eritme, 0)
	sim.connect_stations(eritme, 0, pres, 0)
	sim.connect_stations(pres, 0, sevkiyat, 0)
	sim.connect_power(gen, pres)

	# 1 kulce = 60 cevher = 6000 ham cevher; madenin 8/sn hizinda tek bir
	# kulcenin ilk kez uretilmesi bile ~7500 tick ister (bkz. r_cevher.tres:
	# 1 cevher icin 100 ham cevher, r_ham_cevher.tres: 8/sn).
	var saw_full_power: bool = false
	for i in 10000:
		sim.tick()
		if sim.delivered_power(pres) >= 24:
			saw_full_power = true

	var st: SimStation = sim.get_station(pres)
	# consumed_total yalnizca Sevkiyat/Ar-Ge Laboratuvari icin tutulur (bkz.
	# SimStation.consumed_total dokumantasyonu) -- ureticide anlamli degil,
	# uretimin kendisi zaten kulceyi tukettigini kanitliyor.
	_check("Guc: tam guclu hadde kulce tuketip levha uretiyor",
		st.produced_total > 0,
		"uretim=%d" % st.produced_total)
	_check("Guc: hadde en az bir tick'te tam guc (24kW) aldi",
		saw_full_power, "gorulen_tam_guc=%s" % saw_full_power)


## Senaryo: guc baglantisi hic yokken bol kulce olsa da hadde ilerlemiyor.
func _test_power_zero_power_no_progress() -> void:
	var sim := FactorySim.new()
	var pres: int = sim.add_station(BlockCatalog.PRES)
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	sim.connect_stations(pres, 0, sevkiyat, 0)
	var st: SimStation = sim.get_station(pres)
	for i in 500:
		if st.total_input() < BlockCatalog.PRES.input_capacity:
			st.add_item(st.input, &"kulce", 1)
		sim.tick()
	_check("Guc: sifir guçte hadde hic ilerlemiyor, sahte uretim yok",
		st.produced_total == 0 and st.energy_ticks == 0,
		"uretim=%d enerji=%d" % [st.produced_total, st.energy_ticks])
	_check("Guc: sifir guçte durum GUCSUZ",
		st.status == SimStation.Status.UNPOWERED, "durum=%s" % st.status_label())


## Senaryo: ayni jeneratore bagli iki hadde -- dusuk id tam gucu alir, digeri
## kalani (kismi guc) alir ve ORANTILI yavaslar.
func _test_power_partial_slows_proportionally() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)  # kapasite 40
	var pres_a: int = sim.add_station(BlockCatalog.PRES)     # ister 24
	var pres_b: int = sim.add_station(BlockCatalog.PRES)     # ister 24, kalan 16
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	sim.connect_stations(pres_a, 0, sevkiyat, 0)
	sim.connect_stations(pres_b, 0, sevkiyat, 0)
	sim.connect_power(gen, pres_a)
	sim.connect_power(gen, pres_b)

	var st_a: SimStation = sim.get_station(pres_a)
	var st_b: SimStation = sim.get_station(pres_b)
	for i in 400:
		if st_a.total_input() < BlockCatalog.PRES.input_capacity:
			st_a.add_item(st_a.input, &"kulce", 1)
		if st_b.total_input() < BlockCatalog.PRES.input_capacity:
			st_b.add_item(st_b.input, &"kulce", 1)
		sim.tick()

	_check("Guc: dusuk id'li hadde tam guc (24kW) aliyor",
		sim.delivered_power(pres_a) == 24, "teslim=%d" % sim.delivered_power(pres_a))
	_check("Guc: yuksek id'li hadde kalani (16kW) aliyor",
		sim.delivered_power(pres_b) == 16, "teslim=%d" % sim.delivered_power(pres_b))
	_check("Guc: kismi guc orantili yavasliyor, tam gucten daha az uretiyor",
		st_b.produced_total > 0 and st_a.produced_total > st_b.produced_total,
		"tam_guc_uretim=%d kismi_guc_uretim=%d" % [st_a.produced_total, st_b.produced_total])


## Senaryo: kulcesi olmayan hadde guc istemez, tum kapasite satisa gider.
func _test_power_no_ingots_frees_capacity_for_sale() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)  # hic kulce beslenmiyor
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, pres)
	sim.connect_power(gen, exch)
	_run(sim, 500)

	var st: SimStation = sim.get_station(pres)
	_check("Guc: kulcesiz hadde guc istemiyor, uretmiyor",
		not st.producing and st.produced_total == 0 and sim.delivered_power(pres) == 0,
		"uretiyor=%s uretim=%d teslim=%d" % [st.producing, st.produced_total, sim.delivered_power(pres)])
	_check("Guc: kullanilmayan kapasitenin tamami satisa gidiyor",
		sim.delivered_power(exch) == sim.power_capacity(gen),
		"teslim=%d kapasite=%d" % [sim.delivered_power(exch), sim.power_capacity(gen)])


## Regresyon: cikisi bagli olmayan hadde TIKALI'ya girince enerji sayaci
## sinirsiz birikmemeli -- birikseydi, tikaniklik acilinca tek tick'te
## karsiligi olmayan birden fazla parca birden bosalirdi.
func _test_power_blocked_output_does_not_overflow_energy() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)
	sim.connect_power(gen, pres)
	var st: SimStation = sim.get_station(pres)
	for i in 500:
		if st.total_input() < BlockCatalog.PRES.input_capacity:
			st.add_item(st.input, &"kulce", 1)
		sim.tick()

	var cap: int = BlockCatalog.PRES.output_capacity
	var required_energy: int = roundi(BlockCatalog.PRES.duration_ticks_at_level(1)) * BlockCatalog.PRES.power_required_per_tick
	_check("Guc: cikisi bagli olmayan hadde kapasitede duruyor, tasmiyor",
		st.total_output() == cap, "cikti=%d/%d" % [st.total_output(), cap])
	_check("Guc: TIKALI hadde enerji sayaci esigi asmiyor",
		st.status == SimStation.Status.BLOCKED and st.energy_ticks <= required_energy,
		"durum=%s enerji=%d esik=%d" % [st.status_label(), st.energy_ticks, required_energy])


## Senaryo: uretim VE satis ayni jeneratore bagliyken paylastirilan toplam
## guc kaynak kapasitesini hic asmiyor; uretim once doyuyor, kalan satisa gider.
func _test_power_production_and_sale_share_capacity() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, pres)
	sim.connect_power(gen, exch)

	var st: SimStation = sim.get_station(pres)
	var capacity: int = sim.power_capacity(gen)
	var ever_exceeded: bool = false
	var mill_ever_full: bool = false
	var exchange_ever_got_leftover: bool = false
	for i in 300:
		if st.total_input() < BlockCatalog.PRES.input_capacity:
			st.add_item(st.input, &"kulce", 1)
		sim.tick()
		if sim.delivered_power(pres) + sim.delivered_power(exch) > capacity:
			ever_exceeded = true
		if sim.delivered_power(pres) == 24:
			mill_ever_full = true
		if sim.delivered_power(exch) == capacity - 24:
			exchange_ever_got_leftover = true

	_check("Guc: uretim+satis toplami kaynak kapasitesini hic asmadi",
		not ever_exceeded, "asildi=%s" % ever_exceeded)
	_check("Guc: uretim tam istedigini aldi, satis kalan kapasiteyi aldi",
		mill_ever_full and exchange_ever_got_leftover,
		"hadde_tam_guc=%s satis_kalan=%s" % [mill_ever_full, exchange_ever_got_leftover])


## Senaryo: ayni jeneratore bagli iki satis noktasi kapasiteyi PAYLASIR,
## COGALTMAZ.
func _test_power_multiple_sale_points_split_not_duplicate() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var exch_a: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	var exch_b: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, exch_a)
	sim.connect_power(gen, exch_b)
	_run(sim, 100)

	var capacity: int = sim.power_capacity(gen)
	_check("Guc: iki satis noktasi kapasiteyi paylasiyor, cogaltmiyor",
		sim.delivered_power(exch_a) + sim.delivered_power(exch_b) == capacity,
		"a=%d b=%d kapasite=%d" % [sim.delivered_power(exch_a), sim.delivered_power(exch_b), capacity])


## Senaryo: bir tuketici ayni anda iki jeneratore baglanamiyor -- guc iki kez
## sayilamaz.
func _test_power_consumer_cannot_double_connect() -> void:
	var sim := FactorySim.new()
	var gen_a: int = sim.add_station(BlockCatalog.JENERATOR)
	var gen_b: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)
	sim.connect_power(gen_a, pres)
	var second_ok: bool = sim.connect_power(gen_b, pres)
	_check("Guc: bir tuketici iki jeneratore birden baglanamiyor",
		not second_ok and sim.power_links().size() == 1,
		"ikinci_baglanti_kabul=%s toplam_baglanti=%d" % [second_ok, sim.power_links().size()])


## Senaryo: baglanti kesilince eski tuketici guc almayi ve satmayi birakiyor.
func _test_power_disconnect_stops_delivery() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, exch)
	_run(sim, 200)
	var before: int = sim.total_uncollected()

	sim.disconnect_power(gen, exch)
	_run(sim, 200)
	var after: int = sim.total_uncollected()

	_check("Guc: baglanti kesilince eski tuketici guc almiyor",
		sim.delivered_power(exch) == 0, "teslim=%d" % sim.delivered_power(exch))
	_check("Guc: baglanti kesilince satis durdu, para artmadi",
		after == before, "once=%d sonra=%d" % [before, after])


## Senaryo: ayni istasyonu iki kez tahsil etmek parayi cogaltmiyor.
func _test_power_collect_does_not_double() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, exch)
	_run(sim, 500)

	var first: int = sim.collect(exch)
	var second: int = sim.collect(exch)
	_check("Guc: ayni istasyonu iki kez tahsil etmek para cogaltmiyor",
		first > 0 and second == 0, "ilk=%d ikinci=%d" % [first, second])


## Senaryo: otomasyona gecerken birikmis para BIR KEZ suruklenir, satis hizi
## sayaci tahsilattan bagimsiz artmaya devam eder (bkz. GameController.
## _on_unlock_requested -- bu test ayni sirayi elle uygular).
func _test_power_automation_transition_sweeps_once() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, exch)
	_run(sim, 500)

	var accrued_before: int = sim.total_uncollected()
	sim.auto_collect = true
	var swept: int = sim.collect_all()
	_check("Otomasyon: birikmis para bir kez supruluyor",
		swept == accrued_before and sim.total_uncollected() == 0,
		"suprulen=%d once=%d" % [swept, accrued_before])

	var revenue_before: int = sim.revenue
	var sold_before: int = int(sim.sold_counts.get(&"elektrik", 0))
	_run(sim, 300)
	_check("Otomasyon: yeni satislar dogrudan kasaya giriyor",
		sim.revenue > revenue_before and sim.total_uncollected() == 0,
		"kasa_once=%d kasa_sonra=%d bekleyen=%d" % [revenue_before, sim.revenue, sim.total_uncollected()])
	_check("Otomasyon: satis hizi sayaci tahsilattan bagimsiz artmaya devam ediyor",
		int(sim.sold_counts.get(&"elektrik", 0)) > sold_before,
		"once=%d sonra=%d" % [sold_before, int(sim.sold_counts.get(&"elektrik", 0))])


## Senaryo: yarim enerji birikimi ve guc baglantilari kaydet/yukleden
## kesintisiz kosumla ayni sonucu vermeli.
func _test_power_save_load_mid_batch() -> void:
	var sim := FactorySim.new()
	var gen: int = sim.add_station(BlockCatalog.JENERATOR)
	var pres: int = sim.add_station(BlockCatalog.PRES)
	var exch: int = sim.add_station(BlockCatalog.ELEKTRIK_SATIS)
	sim.connect_power(gen, pres)
	sim.connect_power(gen, exch)

	var st: SimStation = sim.get_station(pres)
	for i in 5:
		if st.total_input() < BlockCatalog.PRES.input_capacity:
			st.add_item(st.input, &"kulce", 1)
		sim.tick()
	if st.energy_ticks <= 0:
		_fail("Kurulum: enerji sayaci hala sifir, senaryo enerji birikimini sinamiyor")
		return

	var snapshot: Dictionary = sim.to_dict()
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var loaded := FactorySim.new()
	loaded.from_dict(round_tripped as Dictionary)
	var loaded_st: SimStation = loaded.get_station(pres)

	_check("Kayit/yukle: yarim enerji birikimi korunuyor",
		loaded_st.energy_ticks == st.energy_ticks,
		"once=%d sonra=%d" % [st.energy_ticks, loaded_st.energy_ticks])
	_check("Kayit/yukle: guc baglantilari korunuyor",
		loaded.power_links().size() == sim.power_links().size(),
		"once=%d sonra=%d" % [sim.power_links().size(), loaded.power_links().size()])

	_run(sim, 500)
	_run(loaded, 500)
	_check("Kayit/yukle: yarim uretimden devam eden kosum kesintisizle esit",
		loaded.state_hash() == sim.state_hash(),
		"kayit=%s kesintisiz=%s" % [loaded.state_hash().substr(0, 12), sim.state_hash().substr(0, 12)])


## --- Denge raporu -----------------------------------------------------------

func _balance_report() -> void:
	var sim := FactorySim.new()
	var ids: Dictionary = _build_reference_line(sim)
	_run(sim, HOUR_TICKS)

	print("")
	print("--- DENGE KOSUMU: referans hat, 1 saat (%d tick) ---" % HOUR_TICKS)
	print("Gelir           : %d TL  (%.1f TL/dk)" % [sim.revenue, float(sim.revenue) / 60.0])
	for item_id: StringName in sim.sold_counts:
		var item: ItemType = ItemCatalog.find_by_id(item_id)
		print("Satilan %-9s: %d adet  (%.2f/dk)" % [
			item.display_name, sim.sold_counts[item_id],
			float(sim.sold_counts[item_id]) / 60.0])

	print("")
	print("Istasyon durumu:")
	print("  AC     = girdisi gelmiyor, ONCEKI istasyon yavas")
	print("  TIKALI = ciktisini bosaltamiyor, SONRAKI istasyon yavas")
	for key: String in ids:
		var st: SimStation = sim.get_station(ids[key])
		print("  %-10s uretim=%-6d giris=%-2d cikis=%-2d %s" % [
			key, st.produced_total, st.total_input(), st.total_output(),
			st.status_label().to_upper()])


## --- Yardimcilar ------------------------------------------------------------

func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)


func _fail(message: String) -> void:
	_checks += 1
	_failures += 1
	print("  KALDI  %s" % message)
