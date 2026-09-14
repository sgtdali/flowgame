extends SceneTree

## Erken oyun deneyi (bkz. DESIGN.md D27): ilk geliştirmeye ve araştırmaya
## erişime kaç oyun-saniyesi/gerçek dakika sürdüğünü ölçer.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/intro_timing.gd
##
## NEDEN AYRI BİR ARAÇ (eski `tools/balance_lib.gd` yeniden kullanılmadı):
## O kütüphanenin "hedefli yatırım" / "ayrı hat" stratejileri 2./3. Maden
## Ocağı ve Çiftlik KURARAK darboğazı çözüyordu. Bu deneyle birlikte
## `max_instances=1` bunu YASAKLIYOR — Maden ve Çiftlik artık yalnızca
## GELİŞTİRİLEBİLİR, çoğaltılamaz. `BalanceLib.Sandbox.build()` ayrıca
## parayı DOĞRUDAN `sim.revenue`'dan okuyordu; bu deneyde satış geliri artık
## `collect()` çağrılmadan kasaya hiç ulaşmıyor (bkz. FactorySim.auto_collect)
## — o kütüphane bu yüzden bu senaryo için sessizce YANLIŞ sonuç verirdi.
## Bu araç onun yerine GERÇEKÇİ, PERİYODİK bir tahsilat modeli kullanır —
## "anında ve sürekli tahsil eden kusursuz oyuncu" varsayımı YOK.
##
## `tools/balance_search.gd` / `balance_audit.gd` / `balance_lib.gd` bu
## deneyden sonra araştırma-sonrası zincir (Presleme ve ötesi) için hâlâ
## geçerli — ama Maden/Çiftlik'i çoğaltan strateji kolları artık BOZUK ve
## bu turda güncellenmedi (bilinen sınır, aşağıda ayrıca not edildi).

const ASSUMED_SPEED := 4.0

## Farklı "oyuncu ne sıklıkla Tahsil Et'e basıyor" varsayımlarını tarar —
## GERÇEK saniye, ASSUMED_SPEED'de. Kusursuz/anlık tahsilat YOK; oyuncunun
## dikkatini başka işe (kurulum, izleme) ayırdığı gerçekçi bir aralık.
const COLLECTION_INTERVALS_SECONDS: Array = [10.0, 20.0, 45.0]

const MAX_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 90
const MD_OUT := "res://tools/intro_timing.md"


func _initialize() -> void:
	print("")
	print("--- ERKEN OYUN DENEYI: ZAMANLAMA ---")
	print("")

	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Erken Oyun Deneyi — Zamanlama Raporu")
	lines.append("")
	lines.append("Üretici: `tools/intro_timing.gd`. Hiçbir denge değeri değiştirmez —")
	lines.append("yalnızca mevcut `.tres`/`GameConfig` değerleriyle ölçer.")
	lines.append("")
	lines.append("**Tahsilat modeli**: oyuncu her `X` GERÇEK saniyede bir \"Tahsil Et\"e")
	lines.append("bastığı varsayılıyor (%.0fx hızda) — anında/sürekli tahsil eden kusursuz" % ASSUMED_SPEED)
	lines.append("bir oyuncu DEĞİL. Birden fazla aralık tarandı, aralığın etkisi ayrı")
	lines.append("gösteriliyor.")
	lines.append("")
	lines.append("**İlk geliştirme** = oyuncunun karşılayabildiği İLK geliştirmeyi satın")
	lines.append("aldığı an (en ucuzundan başlanır). **Araştırmaya erişim** = Ar-Ge Sarayı")
	lines.append("kurulabilir hâle GELDİĞİ an (`requires_first_upgrade` kapısı açıldığında)")
	lines.append("— bina fiilen SATIN ALINDIĞI an da ayrıca raporlanıyor, ikisi aynı şey")
	lines.append("değil.")
	lines.append("")
	lines.append("| Tahsilat aralığı | İlk geliştirme | Ar-Ge Sarayı erişilebilir | Ar-Ge Sarayı kuruldu |")
	lines.append("|---|---|---|---|")

	for interval: float in COLLECTION_INTERVALS_SECONDS:
		var result: Dictionary = _run_scenario(interval)
		_print_result(interval, result)
		lines.append("| %.0f sn | %s | %s | %s |" % [
			interval,
			_fmt(result.first_upgrade_tick),
			_fmt(result.milestone_tick),
			_fmt(result.lab_built_tick),
		])

	lines.append("")
	lines.append("Sütun değerleri \"oyun-sn (gerçek dk @ %.0fx)\" biçiminde." % ASSUMED_SPEED)
	lines.append("")
	lines.append("## Bu deneyde seçilen sabitler")
	lines.append("")
	lines.append("| Parametre | Değer | Nerede |")
	lines.append("|---|---|---|")
	lines.append("| Maden/Çiftlik sınırı | %d | `BlockType.max_instances` |" % BlockCatalog.MADEN_OCAGI.max_instances)
	lines.append("| Maden geliştirme (taban/kat/max) | %d altın / ×%.1f / L%d |" % [
		BlockCatalog.MADEN_OCAGI.upgrade_base_cost, BlockCatalog.MADEN_OCAGI.upgrade_cost_growth, BlockCatalog.MADEN_OCAGI.max_level])
	lines.append("| Çiftlik geliştirme (taban/kat/max) | %d altın / ×%.1f / L%d |" % [
		BlockCatalog.FARM.upgrade_base_cost, BlockCatalog.FARM.upgrade_cost_growth, BlockCatalog.FARM.max_level])
	lines.append("| Eritme geliştirme (taban/kat/max) | %d altın / ×%.1f / L%d |" % [
		BlockCatalog.ERITME.upgrade_base_cost, BlockCatalog.ERITME.upgrade_cost_growth, BlockCatalog.ERITME.max_level])
	lines.append("| Değirmen/Fırın geliştirme (taban) | %d / %d altın |" % [
		BlockCatalog.MILL.upgrade_base_cost, BlockCatalog.BAKERY.upgrade_base_cost])
	lines.append("| Her seviye hız kazancı | ×%.2f süre (%%%.0f daha hızlı) |" % [
		BlockCatalog.MADEN_OCAGI.upgrade_duration_factor, (1.0 - BlockCatalog.MADEN_OCAGI.upgrade_duration_factor) * 100.0])
	lines.append("| Araştırma erişim eşiği | %d geliştirme VEYA %s | `GameConfig.MIN_UPGRADES_FOR_RESEARCH` / `RESEARCH_FALLBACK_TICKS` |" % [
		GameConfig.MIN_UPGRADES_FOR_RESEARCH, GameConfig.format_ticks(GameConfig.RESEARCH_FALLBACK_TICKS)])
	lines.append("")
	lines.append("## Bilinen sınır")
	lines.append("")
	lines.append("`tools/balance_lib.gd`'nin HEDEFLİ/AYRI HAT stratejileri, Maden/Çiftlik'i")
	lines.append("2./3. kez İNŞA EDEREK darboğazı çözüyordu — bu artık `max_instances=1`")
	lines.append("ile YASAK. Bu araç onları bu turda GÜNCELLEMEDİ (kapsam: yalnızca erken")
	lines.append("oyun deneyinin kendi zamanlamasını ölç). Presleme-ve-sonrası zincir için")
	lines.append("o araçlar hâlâ geçerli, ama 'Maden Ocağı inşa et' adımları artık")
	lines.append("simülasyonda GERÇEKTEN reddedilir — bir sonraki denge turunda ele")
	lines.append("alınmalı.")

	var mf := FileAccess.open(MD_OUT, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(lines))
		mf.close()
	print("")
	print("Yazildi: %s" % MD_OUT)
	quit(0)


func _fmt(tick: int) -> String:
	if tick < 0:
		return "ULAŞILAMADI"
	var seconds: float = float(tick) / float(GameConfig.TICKS_PER_SECOND)
	return "%.0f sn (%.1f dk)" % [seconds, seconds / ASSUMED_SPEED / 60.0]


func _print_result(interval: float, result: Dictionary) -> void:
	print("Tahsilat araligi %.0f sn: ilk gelistirme=%s, arastirma erisilebilir=%s, kuruldu=%s" % [
		interval, _fmt(result.first_upgrade_tick), _fmt(result.milestone_tick), _fmt(result.lab_built_tick)])


## --- Senaryo ------------------------------------------------------------------

func _run_scenario(collection_interval_seconds: float) -> Dictionary:
	var sim := FactorySim.new()
	var prog := ProgressionState.new()
	var collection_interval_ticks: int = maxi(1, roundi(
		collection_interval_seconds * ASSUMED_SPEED * float(GameConfig.TICKS_PER_SECOND)))

	# Kisa hatlar: baslangic parasiyla (1000 altin) TAMAMI karsilanir —
	# GameConfig'in kendi sozu ("ilk hatti kurmaya yetmeli") burada da gecerli,
	# hicbir tahsilat beklemeden kurulabiliyor.
	var farm: int = sim.add_station(BlockCatalog.FARM)
	var mill: int = sim.add_station(BlockCatalog.MILL)
	var bakery: int = sim.add_station(BlockCatalog.BAKERY)
	var granary: int = sim.add_station(BlockCatalog.GRANARY)
	var maden: int = sim.add_station(BlockCatalog.MADEN_OCAGI)
	var eritme: int = sim.add_station(BlockCatalog.ERITME)
	var sevkiyat: int = sim.add_station(BlockCatalog.SEVKIYAT)
	for cost: int in [
		BlockCatalog.FARM.build_cost, BlockCatalog.MILL.build_cost, BlockCatalog.BAKERY.build_cost,
		BlockCatalog.GRANARY.build_cost, BlockCatalog.MADEN_OCAGI.build_cost, BlockCatalog.ERITME.build_cost,
	]:
		prog.try_pay(cost, sim.revenue)

	sim.connect_stations(farm, 0, mill, 0)
	sim.connect_stations(mill, 0, bakery, 0)
	sim.connect_stations(bakery, 0, granary, 0)
	sim.connect_stations(maden, 0, eritme, 0)
	sim.connect_stations(eritme, 0, sevkiyat, 0)
	sim.set_worker(farm, true)
	sim.set_worker(mill, true)
	sim.set_worker(bakery, true)
	sim.set_worker(maden, true)
	sim.set_worker(eritme, true)

	var upgradeable_ids: Array = [maden, eritme, farm, mill, bakery]
	var first_upgrade_tick: int = -1
	var milestone_tick: int = -1
	var lab_built_tick: int = -1
	var lab_id: int = -1

	# Kisa hatlari kurduktan sonra ARTAN baslangic parasiyla zaten en ucuz
	# gelistirme karsilanabiliyor olabilir — oyuncu bunun icin ilk
	# tahsilati BEKLEMEZ. Dongu disinda bir kez deniyoruz ki "ilk
	# gelistirme" suresi yapay olarak tahsilat araligina baglanmasin.
	_try_buy_cheapest_upgrade(sim, prog, upgradeable_ids)
	if prog.upgrades_purchased > 0:
		first_upgrade_tick = 0
	if prog.is_block_available(BlockCatalog.ARGE_LAB, 0):
		milestone_tick = 0
		if prog.try_pay(BlockCatalog.ARGE_LAB.build_cost, sim.revenue):
			lab_id = sim.add_station(BlockCatalog.ARGE_LAB)
			lab_built_tick = 0

	var t: int = 0
	while t < MAX_TICKS and lab_id < 0:
		sim.tick()
		t += 1

		if t % collection_interval_ticks == 0:
			sim.collect_all()
			# Tahsilattan hemen sonra: karsilanabilecek EN UCUZ gelistirmeyi al.
			_try_buy_cheapest_upgrade(sim, prog, upgradeable_ids)
			if first_upgrade_tick < 0 and prog.upgrades_purchased > 0:
				first_upgrade_tick = t
			if milestone_tick < 0 and prog.is_block_available(BlockCatalog.ARGE_LAB, t):
				milestone_tick = t
			if milestone_tick >= 0 and lab_id < 0 and prog.try_pay(BlockCatalog.ARGE_LAB.build_cost, sim.revenue):
				lab_id = sim.add_station(BlockCatalog.ARGE_LAB)
				lab_built_tick = t
				break

	return {
		"first_upgrade_tick": first_upgrade_tick,
		"milestone_tick": milestone_tick,
		"lab_built_tick": lab_built_tick,
	}


func _try_buy_cheapest_upgrade(sim: FactorySim, prog: ProgressionState, ids: Array) -> void:
	var best_id: int = -1
	var best_cost: int = -1
	for id: int in ids:
		var station: SimStation = sim.get_station(id)
		if not ProgressionState.can_upgrade(station.type, station.level):
			continue
		var cost: int = ProgressionState.upgrade_cost(station.type, station.level)
		if best_id < 0 or cost < best_cost:
			best_id = id
			best_cost = cost
	if best_id < 0:
		return
	if prog.balance(sim.revenue) >= best_cost:
		prog.try_upgrade(sim.get_station(best_id), sim.revenue)
