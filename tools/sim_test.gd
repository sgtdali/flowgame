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
const EXPECTED_CHECKS: int = 8


func _initialize() -> void:
	print("")
	_test_determinism()
	_test_save_load()
	_test_blocking()
	_test_backpressure_chain()
	_test_starved()
	_test_scrap_does_not_deadlock()

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

## Tasarımdaki örnek hattı kurar ve istasyon id'lerini döndürür.
func _build_reference_line(sim: FactorySim) -> Dictionary:
	var ids: Dictionary = {
		"maden": sim.add_station(BlockCatalog.MADEN_OCAGI),
		"eritme": sim.add_station(BlockCatalog.ERITME),
		"pres": sim.add_station(BlockCatalog.PRES),
		"dagitici": sim.add_station(BlockCatalog.DAGITICI),
		"hadde": sim.add_station(BlockCatalog.HADDE),
		"kesim": sim.add_station(BlockCatalog.KESIM),
		"montaj": sim.add_station(BlockCatalog.MONTAJ),
		"kalite": sim.add_station(BlockCatalog.KALITE),
		"sevkiyat": sim.add_station(BlockCatalog.SEVKIYAT),
		"geri": sim.add_station(BlockCatalog.GERI_DONUSUM),
	}
	var wires: Array = [
		[ids.maden, 0, ids.eritme, 0],
		[ids.eritme, 0, ids.pres, 0],
		[ids.pres, 0, ids.dagitici, 0],
		[ids.dagitici, 0, ids.hadde, 0],
		[ids.hadde, 0, ids.kesim, 0],
		[ids.dagitici, 1, ids.montaj, 0], # Levha -> Montaj girdi 1
		[ids.kesim, 0, ids.montaj, 1],    # Vida  -> Montaj girdi 2
		[ids.montaj, 0, ids.kalite, 0],
		[ids.kalite, 0, ids.sevkiyat, 0], # Uygun
		[ids.kalite, 1, ids.geri, 0],     # Ret -> Geri Donusum
		[ids.geri, 0, ids.pres, 0],       # Kulce -> Pres (geri besleme)
	]
	for wire: Array in wires:
		if not sim.connect_stations(wire[0], wire[1], wire[2], wire[3]):
			_fail("Baglanti kurulamadi: %s" % [wire])
	return ids


func _run(sim: FactorySim, ticks: int) -> void:
	if sim.workers_assigned() == 0:
		_staff_all(sim)
	for i in ticks:
		sim.tick()


func _staff_all(sim: FactorySim) -> void:
	# These checks isolate the original material-flow rules from food upkeep.
	sim.workers_total = 100
	sim.food = 10000
	for station: SimStation in sim.stations():
		if station.type.requires_worker():
			sim.set_worker(station.id, true)


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


func _test_blocking() -> void:
	# Cikisi hicbir yere bagli olmayan bir eritme: tamponu dolunca DURMALI.
	var sim := FactorySim.new()
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	sim.connect_stations(maden, 0, eritme, 0)
	_run(sim, 3000)

	var station: SimStation = sim.get_station(eritme)
	var capacity: int = BlockCatalog.ERITME.output_capacity
	_check("Tikanma: cikisi bagli olmayan istasyon kapasitede duruyor",
		station.total_output() == capacity and station.status == SimStation.Status.BLOCKED,
		"cikti=%d/%d durum=%s" % [station.total_output(), capacity, station.status_label()])


func _test_backpressure_chain() -> void:
	# Tikanma GERIYE yurumeli: eritme tikalyinca maden ocagi da dolup durmali.
	var sim := FactorySim.new()
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	sim.connect_stations(maden, 0, eritme, 0)
	_run(sim, 3000)

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


## Ret portu bagli degilken Kalite Kontrol hatti KILITLEMEMELI.
##
## Gerileme testi: bu tam olarak yasandi. Hurda cikis tamponunu doldurunca
## istasyon elindeki hurdaya takilip kaliyor, takildigi icin saglam uretimi
## de duruyordu. Geri donusum hatti bir dongu olusturdugu icin hurda hic
## bosalmiyor ve fabrikanin TAMAMI kalici olarak kilitleniyordu.
func _test_scrap_does_not_deadlock() -> void:
	var sim := FactorySim.new()
	var kalite: int = sim.add_station(BlockCatalog.KALITE)
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	sim.connect_stations(kalite, 0, sevkiyat, 0)   # uygun -> sat
	# Ret portu BILEREK bagli degil.

	var station: SimStation = sim.get_station(kalite)
	_staff_all(sim)
	for i in 600:
		# Montaj kurmadan beslemek icin govdeyi dogrudan girdiye koyuyoruz.
		if station.total_input() < BlockCatalog.KALITE.input_capacity:
			station.add_item(station.input, &"govde", 1)
		sim.tick()

	var scrap_cap: int = BlockCatalog.KALITE.output_capacity
	# Bu koşum auto_collect'i acmiyor: satis geliri Sevkiyat'ta BIRIKIR
	# (bkz. FactorySim._run_sink, DESIGN.md D27) — hattin akip akmadigini
	# gosteren artik sim.revenue degil total_uncollected().
	_check("Fire kilitlenmesi: Ret portu bos olsa da hat akiyor",
		sim.total_uncollected() > 0 and station.status != SimStation.Status.BLOCKED,
		"bekleyen=%d durum=%s uretim=%d" % [sim.total_uncollected(), station.status_label(), station.produced_total])
	_check("Fire kilitlenmesi: hurda kutusu kapasitede duruyor, tasmiyor",
		int(station.output.get(&"hurda", 0)) <= scrap_cap,
		"hurda=%d kapasite=%d" % [int(station.output.get(&"hurda", 0)), scrap_cap])


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
