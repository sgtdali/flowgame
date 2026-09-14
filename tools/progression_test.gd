extends SceneTree

## İlerleme temposu koşumu.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/progression_test.gd
##
## Makul oynayan bir oyuncuyu taklit eder: gıda hattını kurar, işçi atar,
## parası/ürünü yettikçe sıradaki araştırmayı alır, açılan istasyonu kurar ve
## hatta bağlar. Her aşamanın OYUN İÇİ kaç dakikada geldiğini ölçer.
##
## Neden: tahmin etmek yerine ölçüyoruz. Sayılar tutmazsa ayarlanacak yer
## belli: common/game_config.gd ve data/*.tres.
##
## NOT: Bu script "Erken oyun araştırmaları ürün akıtmayla açılsın" turunda
## (Ar-Ge Sarayı ve Dağıtıcı artık oyunun başında kurulabilir, ilk üç
## araştırma parayla değil laboratuvara akıtılan ürünle açılıyor) baştan
## yazıldı. Eski sürüm `GENISLEME_1/2` ve `slot_limit()` kullanıyordu —
## ikisi de ortaçağ dönüşümünde kaldırılan bir slot sistemine aitti ve script
## artık DERLENMİYORDU. Eski 63.3 dakikalık ölçüm bu yüzden GEÇERSİZ; bu
## dosyanın ürettiği yeni ölçüm tek geçerli referans.

const STAGE_TIMEOUT_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 90

var sim: FactorySim = FactorySim.new()
var prog: ProgressionState = ProgressionState.new()
var timeline: Array = []

## HIZLI BAŞARISIZLIK (bkz. sim_test.gd'deki eşdeğeri): her yardımcı
## fonksiyon girişte kontrol edip, halted ise no-op döner.
var halted: bool = false


func _initialize() -> void:
	print("")
	print("--- ILERLEME TEMPOSU ---")
	print("Baslangic: %d TL, %d isci, %d yiyecek" % [
		GameConfig.START_MONEY, GameConfig.START_WORKERS, GameConfig.START_FOOD])
	print("")

	_play()

	if halted:
		quit(1)
		return

	print("")
	print("%-32s %8s %10s %8s" % ["ASAMA", "SURE", "BAKIYE", "ISTASYON"])
	for row: Array in timeline:
		print("%-32s %8s %10s %8s" % [row[0], row[1], row[2], row[3]])

	var total_minutes: float = float(sim.tick_count) / float(GameConfig.TICKS_PER_SECOND) / 60.0
	print("")
	print("TOPLAM: %.1f dakika" % total_minutes)
	if total_minutes > 100.0:
		print("SONUC: tempo COK YAVAS gorunuyor — maliyetler dusurulmeli veya fiyatlar artirilmali.")
	elif total_minutes < 40.0:
		print("SONUC: tempo COK HIZLI gorunuyor — icerik cabuk tukeniyor.")
	else:
		print("SONUC: tempo makul araliginda (eski 63.3 dk olcumu artik gecersiz, bkz. dosya basindaki not).")
	quit(0)


## --- Senaryo ----------------------------------------------------------------

func _play() -> void:
	# 1) Gida hatti: sonraki her yeni istasyonun iscisi buradan finanse edilir.
	var farm: int = _build(BlockCatalog.FARM)
	var mill: int = _build(BlockCatalog.MILL)
	var bakery: int = _build(BlockCatalog.BAKERY)
	var granary: int = _build(BlockCatalog.GRANARY)
	_wire(farm, 0, mill, 0)
	_wire(mill, 0, bakery, 0)
	_wire(bakery, 0, granary, 0)
	_staff(farm)
	_staff(mill)
	_staff(bakery)
	_mark("Gida hatti kuruldu")

	# 2) Baslangic demir hatti: cevher -> kulce -> sat
	var maden1: int = _build(BlockCatalog.MADEN_OCAGI)
	var eritme1: int = _build(BlockCatalog.ERITME)
	var sevkiyat: int = _build(BlockCatalog.SEVKIYAT)
	_wire(maden1, 0, eritme1, 0)
	_wire(eritme1, 0, sevkiyat, 0)
	_staff(maden1)
	_staff(eritme1)
	_mark("Baslangic hatti kuruldu")

	# 3) Ar-Ge Sarayi + Dagitici: ikisi de artik oyunun basinda kurulabiliyor.
	# Cevheri sat -> Ar-Ge Sarayi/Dagitici icin para biriksin, SONRA cevherin
	# bir kismini laboratuvara yonlendir.
	var lab: int = _build(BlockCatalog.ARGE_LAB)
	var dagitici1: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(maden1, 0, eritme1, 0)
	_wire(maden1, 0, dagitici1, 0)
	_wire(dagitici1, 0, eritme1, 0)
	_wire(dagitici1, 1, lab, 0)   # cevher -> laboratuvar
	_mark("Ar-Ge Sarayi kuruldu")

	# 4) Presleme: 40 cevher laboratuvara akitilinca acilir (para degil).
	if not _afford_and_research(ResearchCatalog.PRESLEME):
		return
	sim.disconnect_stations(dagitici1, 1, lab, 0)   # daha fazla cevhere gerek yok
	var pres: int = _build(BlockCatalog.PRES)
	_staff(pres)
	sim.disconnect_stations(eritme1, 0, sevkiyat, 0)
	_wire(eritme1, 0, pres, 0)
	_wire(pres, 0, sevkiyat, 0)
	_mark("Pres kuruldu")

	# 5) Kalkan Zanaati: 25 levha laboratuvara akitilinca acilir.
	var dagitici2: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(pres, 0, sevkiyat, 0)
	_wire(pres, 0, dagitici2, 0)
	_wire(dagitici2, 0, sevkiyat, 0)
	_wire(dagitici2, 1, lab, 0)   # levha -> laboratuvar
	if not _afford_and_research(ResearchCatalog.KALKAN_ZANAATI):
		return
	sim.disconnect_stations(dagitici2, 1, lab, 0)   # daha fazla levhaya gerek yok

	# Kalkan Ustaligi, iki koldan besleniyor: kulce (dogrudan) + levha (islenmis).
	var kalkan_ustasi: int = _build(BlockCatalog.KALKAN_USTASI)
	_staff(kalkan_ustasi)
	var dagitici3: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(eritme1, 0, pres, 0)
	_wire(eritme1, 0, dagitici3, 0)
	_wire(dagitici3, 0, pres, 0)
	_wire(dagitici3, 1, kalkan_ustasi, 0)   # kulce -> kalkan ustasi girdi 0
	_wire(dagitici2, 1, kalkan_ustasi, 1)   # levha -> kalkan ustasi girdi 1 (bosalan port)
	_mark("Kalkan ustaligi kuruldu")

	# 6) Ara Depolama: 15 kalkan laboratuvara akitilinca acilir.
	var dagitici4: int = _build(BlockCatalog.DAGITICI)
	_wire(kalkan_ustasi, 0, dagitici4, 0)
	_wire(dagitici4, 0, sevkiyat, 0)
	_wire(dagitici4, 1, lab, 0)   # kalkan -> laboratuvar
	if not _afford_and_research(ResearchCatalog.DEPOLAMA):
		return
	sim.disconnect_stations(dagitici4, 1, lab, 0)
	_build(BlockCatalog.DEPO)   # satin alinabilirligi kanitlar, hatta orulmez
	_mark("Ara Depolama (erken oyun sonu)")

	# --- Buradan sonrasi degismedi: eski parali arastirma zinciri ---

	# 7) Hadde + Kesim: bir levhadan iki vida
	if not _afford_and_research(ResearchCatalog.HADDELEME):
		return
	var hadde: int = _build(BlockCatalog.HADDE)
	_staff(hadde)
	if not _afford_and_research(ResearchCatalog.KESIM_HATTI):
		return
	var kesim: int = _build(BlockCatalog.KESIM)
	_staff(kesim)
	# Levha su ana kadar Dagitici2 uzerinden {sevkiyat, kalkan ustasi} icin
	# bolunuyordu. Satisi kesip Hadde'ye yonlendiriyoruz — vida hatti daha
	# degerli.
	sim.disconnect_stations(dagitici2, 0, sevkiyat, 0)
	_wire(dagitici2, 0, hadde, 0)
	_wire(hadde, 0, kesim, 0)
	_wire(kesim, 0, sevkiyat, 0)
	_mark("Vida hatti")

	# 8) Montaj: 2 levha + 3 vida -> govde. Levha artik yalnizca Hadde ve
	# Kalkan Ustasi'na gidiyor; Montaj icin ucuncu bir levha kolu lazim —
	# Pres ciktisinin hemen ardina yeni bir Dagitici ekliyoruz.
	if not _afford_and_research(ResearchCatalog.MONTAJ_HATTI):
		return
	var montaj: int = _build(BlockCatalog.MONTAJ)
	_staff(montaj)
	var dagitici5: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(pres, 0, dagitici2, 0)
	_wire(pres, 0, dagitici5, 0)
	_wire(dagitici5, 0, dagitici2, 0)
	_wire(dagitici5, 1, montaj, 0)   # levha
	sim.disconnect_stations(kesim, 0, sevkiyat, 0)
	_wire(kesim, 0, montaj, 1)       # vida
	_wire(montaj, 0, sevkiyat, 0)
	_mark("Montaj hatti")

	# 9) Kalite Kontrol
	if not _afford_and_research(ResearchCatalog.KALITE_KONTROL):
		return
	var kalite: int = _build(BlockCatalog.KALITE)
	_staff(kalite)
	sim.disconnect_stations(montaj, 0, sevkiyat, 0)
	_wire(montaj, 0, kalite, 0)
	_wire(kalite, 0, sevkiyat, 0)
	_wire(kalite, 1, sevkiyat, 0)   # Ret portu gecici olarak satisa baglanir
	_mark("Kalite kontrol")

	# 10) Ar-Ge (artik yalniz Geri Donusum aciyor — Ar-Ge Sarayi zaten kurulu)
	if not _afford_and_research(ResearchCatalog.ARGE):
		return
	var geri: int = _build(BlockCatalog.GERI_DONUSUM)
	_staff(geri)
	sim.disconnect_stations(kalite, 1, sevkiyat, 0)
	_wire(kalite, 1, geri, 0)
	_wire(geri, 0, pres, 0)
	var dagitici6: int = _build(BlockCatalog.DAGITICI)
	sim.disconnect_stations(kalite, 0, sevkiyat, 0)
	_wire(kalite, 0, dagitici6, 0)
	_wire(dagitici6, 0, sevkiyat, 0)
	_wire(dagitici6, 1, lab, 0)
	_mark("Geri donusum")

	# 11) Son arastirma: 100 govde laboratuvara
	if not _afford_and_research(ResearchCatalog.DERIN_SONDAJ):
		return
	var derin: int = _build(BlockCatalog.MADEN_OCAGI_DERIN)
	_staff(derin)
	_mark("Derin maden (FINAL)")


## --- Yardimcilar ------------------------------------------------------------

func _build(type: BlockType) -> int:
	if halted or type == null:
		return -1
	if not prog.try_pay(type.build_cost, sim.revenue):
		if not _run_until(func() -> bool: return prog.balance(sim.revenue) >= type.build_cost,
				"%s icin para" % type.display_name):
			return -1
		prog.try_pay(type.build_cost, sim.revenue)
	return sim.add_station(type)


func _wire(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	if halted:
		return
	if from_id < 0 or to_id < 0:
		return
	if sim.connection_problem(from_id, from_port, to_id, to_port) == "This route already exists.":
		return
	if not sim.connect_stations(from_id, from_port, to_id, to_port):
		_fail("Baglanti kurulamadi: %d:%d -> %d:%d (%s)" % [
			from_id, from_port, to_id, to_port,
			sim.connection_problem(from_id, from_port, to_id, to_port)])


## İşçi gerektiren bir istasyona işçi atar. Boşta işçi yoksa yiyecekle
## yenisini işe alır (gerekirse yiyecek birikene kadar bekler).
func _staff(id: int) -> void:
	if halted or id < 0:
		return
	var station: SimStation = sim.get_station(id)
	if station == null or not station.type.requires_worker():
		return
	if sim.workers_assigned() >= sim.workers_total:
		_recruit_worker()
		if halted:
			return
	if not sim.set_worker(id, true):
		_fail("Isci atanamadi: istasyon %d" % id)


func _recruit_worker() -> void:
	if halted:
		return
	if not _run_until(func() -> bool: return sim.food >= GameConfig.RECRUIT_FOOD_COST,
			"yiyecek (isci alimi)"):
		return
	if not sim.recruit_worker():
		_fail("Isci alinamadi: yiyecek yetersiz")


func _afford_and_research(node: ResearchNode) -> bool:
	if halted:
		return false
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
	if halted:
		return false
	var spent_ticks: int = 0
	while not predicate.call():
		sim.tick()
		spent_ticks += 1
		if spent_ticks > STAGE_TIMEOUT_TICKS:
			_fail("%s icin 90 dakikada ulasilamadi" % label)
			_dump_line()
			return false
	return true


func _dump_line() -> void:
	print("    --- hat durumu ---")
	for st: SimStation in sim.stations():
		print("    #%-2d %-20s %-10s giris=%-3d cikis=%-3d uretim=%d" % [
			st.id, st.type.display_name, st.status_label(),
			st.total_input(), st.total_output(), st.produced_total])
	print("    gelir=%d  isci=%d/%d  yiyecek=%d  laboratuvara akan=%s" % [
		sim.revenue, sim.workers_assigned(), sim.workers_total, sim.food, sim.research_counts])


func _mark(label: String) -> void:
	if halted:
		return
	timeline.append([
		label,
		"%.1f dk" % (float(sim.tick_count) / float(GameConfig.TICKS_PER_SECOND) / 60.0),
		GameConfig.format_money(prog.balance(sim.revenue)),
		"%d" % sim.station_count(),
	])


func _fail(message: String) -> void:
	if halted:
		return
	halted = true
	print("")
	print("  HATA: %s" % message)
	print("")
	print("Suraya kadar TAMAMLANMIŞ asamalar:")
	for row: Array in timeline:
		print("  %-32s %8s %10s %8s" % [row[0], row[1], row[2], row[3]])
	_dump_line()
