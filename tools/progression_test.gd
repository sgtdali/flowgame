extends SceneTree

## İlerleme temposu koşumu.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/progression_test.gd
##
## Makul oynayan bir oyuncuyu taklit eder: parası yettikçe sıradaki
## araştırmayı alır, açılan istasyonu kurar ve hatta bağlar. Her aşamanın
## OYUN İÇİ kaç dakikada geldiğini ölçer.
##
## Neden: tasarım belgesindeki en büyük risk "60 dakikalık tempo ilk denemede
## tutmaz". Elle oynayıp tahmin etmek yerine ölçüyoruz. Sayılar tutmazsa
## ayarlanacak yer belli: common/game_config.gd ve data/*.tres.

## Bir aşamanın gelmesi için tanınan en fazla oyun içi süre.
const STAGE_TIMEOUT_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 90

var sim: FactorySim = FactorySim.new()
var prog: ProgressionState = ProgressionState.new()
var timeline: Array = []
var failed: bool = false


func _initialize() -> void:
	print("")
	print("--- ILERLEME TEMPOSU ---")
	print("Baslangic: %d TL, %d slot" % [GameConfig.START_MONEY, GameConfig.START_SLOTS])
	print("")

	_play()

	print("")
	print("%-28s %8s %10s %8s" % ["ASAMA", "SURE", "BAKIYE", "ISTASYON"])
	for row: Array in timeline:
		print("%-28s %8s %10s %8s" % [row[0], row[1], row[2], row[3]])

	var total_minutes: float = float(sim.tick_count) / float(GameConfig.TICKS_PER_SECOND) / 60.0
	print("")
	print("TOPLAM: %.1f dakika (hedef: 60)" % total_minutes)
	if failed:
		print("SONUC: bir asamaya ulasilamadi.")
	elif total_minutes > 75.0:
		print("SONUC: tempo COK YAVAS — maliyetler dusurulmeli veya fiyatlar artirilmali.")
	elif total_minutes < 35.0:
		print("SONUC: tempo COK HIZLI — icerik bir saati doldurmuyor.")
	else:
		print("SONUC: tempo hedef araliginda.")
	quit(1 if failed else 0)


## --- Senaryo ----------------------------------------------------------------

func _play() -> void:
	# 1) Baslangic hatti: cevher -> kulce -> sat
	var maden1: int = _build(BlockCatalog.MADEN_OCAGI)
	var eritme1: int = _build(BlockCatalog.ERITME)
	var sevkiyat: int = _build(BlockCatalog.SEVKIYAT)
	_wire(maden1, 0, eritme1, 0)
	_wire(eritme1, 0, sevkiyat, 0)
	_mark("Baslangic hatti kuruldu")

	# 2) Pres: kulce yerine levha sat (10 TL -> 28 TL)
	if not _afford_and_research(ResearchCatalog.PRESLEME):
		return
	var pres: int = _build(BlockCatalog.PRES)
	sim.disconnect_stations(eritme1, 0, sevkiyat, 0)
	_wire(eritme1, 0, pres, 0)
	_wire(pres, 0, sevkiyat, 0)
	_mark("Pres kuruldu")

	# 3) Genisleme + ikinci on hat: maden ocagi darbogazini hafiflet
	if not _afford_and_research(ResearchCatalog.GENISLEME_1):
		return
	var maden2: int = _build(BlockCatalog.MADEN_OCAGI)
	var eritme2: int = _build(BlockCatalog.ERITME)
	_wire(maden2, 0, eritme2, 0)
	_wire(eritme2, 0, pres, 0)
	_mark("Ikinci on hat")

	# 4) Hadde + Kesim: bir levhadan iki vida (28 TL -> 40 TL)
	if not _afford_and_research(ResearchCatalog.HADDELEME):
		return
	var hadde: int = _build(BlockCatalog.HADDE)
	if not _afford_and_research(ResearchCatalog.KESIM_HATTI):
		return
	var kesim: int = _build(BlockCatalog.KESIM)
	# Pres'in çıkışı tek tele sınırlı — Montaj'a ihtiyaç doğunca da levha
	# lazım olacağından, dallanma noktasını baştan bir Dağıtıcı ile kuruyoruz.
	# Dağıtıcı, Ara Depolama araştırmasıyla birlikte açılıyor. Pres henüz
	# Sevkiyat'a bağlıyken (gelir kesilmeden) parayı bekliyoruz, SONRA
	# koparıp Dağıtıcı'ya yönlendiriyoruz.
	if not _afford_and_research(ResearchCatalog.DEPOLAMA):
		return
	# Dağıtıcı'yı da Pres hâlâ Sevkiyat'a bağlıyken (gelir kesilmeden) satın
	# alıyoruz, ancak SONRA koparıp yönlendiriyoruz.
	var dagitici: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(pres, 0, sevkiyat, 0)
	_wire(pres, 0, dagitici, 0)
	_wire(dagitici, 0, hadde, 0)
	_wire(hadde, 0, kesim, 0)
	_wire(kesim, 0, sevkiyat, 0)
	_mark("Vida hatti")

	# 5) Montaj: levha + vida -> govde (150 TL)
	if not _afford_and_research(ResearchCatalog.GENISLEME_2):
		return
	if not _afford_and_research(ResearchCatalog.MONTAJ_HATTI):
		return
	var montaj: int = _build(BlockCatalog.MONTAJ)
	sim.disconnect_stations(kesim, 0, sevkiyat, 0)
	_wire(dagitici, 1, montaj, 0)  # levha, Dağıtıcı'nın ikinci portundan
	_wire(kesim, 0, montaj, 1)     # vida
	_wire(montaj, 0, sevkiyat, 0)
	_mark("Montaj hatti")

	# 6) Kalite Kontrol
	if not _afford_and_research(ResearchCatalog.KALITE_KONTROL):
		return
	var kalite: int = _build(BlockCatalog.KALITE)
	sim.disconnect_stations(montaj, 0, sevkiyat, 0)
	_wire(montaj, 0, kalite, 0)
	_wire(kalite, 0, sevkiyat, 0)
	# Ret portu MUTLAKA bir yere gitmeli. Boş bırakılırsa hurda çıkış
	# tamponunda birikir, dolunca Kalite Kontrol kalıcı olarak tıkanır ve
	# hattın tamamı durur. Geri Dönüşüm henüz açık değil, o yüzden hurdayı
	# şimdilik satıyoruz.
	_wire(kalite, 1, sevkiyat, 0)
	_mark("Kalite kontrol")

	# 7) Ar-Ge Laboratuvari + geri donusum
	if not _afford_and_research(ResearchCatalog.ARGE):
		return
	var geri: int = _build(BlockCatalog.GERI_DONUSUM)
	var lab: int = _build(BlockCatalog.ARGE_LAB)
	sim.disconnect_stations(kalite, 1, sevkiyat, 0)
	_wire(kalite, 1, geri, 0)      # ret -> geri donusum (hurdayi satmak yerine)
	_wire(geri, 0, pres, 0)        # kulce -> pres
	# Uygun gövdenin yarısı laboratuvara gitsin: kalite:0 tek tele sınırlı,
	# ikinci bir Dağıtıcı ile bölüyoruz. Yine SATIN ALMAYI, en değerli akışı
	# (gövde) kesmeden önce yapıyoruz.
	var dagitici2: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(kalite, 0, sevkiyat, 0)
	_wire(kalite, 0, dagitici2, 0)
	_wire(dagitici2, 0, sevkiyat, 0)
	_wire(dagitici2, 1, lab, 0)
	_mark("Ar-Ge laboratuvari")

	# 8) Son arastirma: 150 govde laboratuvara
	if not _afford_and_research(ResearchCatalog.DERIN_SONDAJ):
		return
	_build(BlockCatalog.MADEN_OCAGI_DERIN)
	_mark("Derin maden (FINAL)")


## --- Yardimcilar ------------------------------------------------------------

func _build(type: BlockType) -> int:
	if sim.station_count() >= prog.slot_limit():
		_fail("Slot yetmedi: %s icin (%d/%d)" % [
			type.display_name, sim.station_count(), prog.slot_limit()])
		return -1
	if not prog.try_pay(type.build_cost, sim.revenue):
		# Parasi yetene kadar bekle, sonra kur.
		if not _run_until(func() -> bool: return prog.balance(sim.revenue) >= type.build_cost,
				"%s icin para" % type.display_name):
			return -1
		prog.try_pay(type.build_cost, sim.revenue)
	return sim.add_station(type)


func _build_by_id(block_id: String) -> int:
	return _build(BlockCatalog.find_by_id(StringName(block_id)))


func _wire(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	if from_id < 0 or to_id < 0:
		return
	if not sim.connect_stations(from_id, from_port, to_id, to_port):
		_fail("Baglanti kurulamadi: %d:%d -> %d:%d (%s)" % [
			from_id, from_port, to_id, to_port,
			sim.connection_problem(from_id, from_port, to_id, to_port)])


func _afford_and_research(node: ResearchNode) -> bool:
	var ok: bool = _run_until(
		func() -> bool: return prog.unlock_problem(node, sim.revenue, sim.research_counts).is_empty(),
		"arastirma: %s" % node.display_name)
	if not ok:
		return false
	var problem: String = prog.try_unlock(node, sim.revenue, sim.research_counts)
	if not problem.is_empty():
		_fail("Arastirma alinamadi: %s (%s)" % [node.display_name, problem])
		return false
	return true


func _run_until(predicate: Callable, label: String) -> bool:
	var spent_ticks: int = 0
	while not predicate.call():
		sim.tick()
		spent_ticks += 1
		if spent_ticks > STAGE_TIMEOUT_TICKS:
			_fail("%s icin 90 dakikada ulasilamadi" % label)
			_dump_line()
			return false
	return true


## Zaman asiminda hattin fotografi. Tahmin etmek yerine bakiyoruz.
func _dump_line() -> void:
	print("    --- hat durumu ---")
	for st: SimStation in sim.stations():
		print("    #%-2d %-20s %-10s giris=%-3d cikis=%-3d uretim=%d" % [
			st.id, st.type.display_name, st.status_label(),
			st.total_input(), st.total_output(), st.produced_total])
	print("    gelir=%d  laboratuvara akan=%s" % [sim.revenue, sim.research_counts])


func _mark(label: String) -> void:
	timeline.append([
		label,
		"%.1f dk" % (float(sim.tick_count) / float(GameConfig.TICKS_PER_SECOND) / 60.0),
		GameConfig.format_money(prog.balance(sim.revenue)),
		"%d/%d" % [sim.station_count(), prog.slot_limit()],
	])


func _fail(message: String) -> void:
	failed = true
	print("  HATA: %s" % message)
