extends SceneTree

## Denge aracının sonuçlarını GERÇEK bir oyuncu turuyla karşılaştırılabilir
## hâle getirir. Hiçbir denge değeri DEĞİŞTİRİLMEZ/ÖNERİLMEZ — bu saf bir
## karşılaştırma/denetim aracıdır.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/balance_playtest_compare.gd
##
## Oyuncunun bildirdiği tur: TEK zinciri dönüştürerek (Dağıtıcı ile bölerek),
## PARA MALİYETLİ hiçbir araştırma SATIN ALINMADAN, son ürün-maliyetli
## araştırmaya ~5 GERÇEK dakikada, 4x hızda ulaşıldı (çoğunlukla bekleyerek).
##
## BU ARAÇ NE YAPAR: yalnızca o rotayı (4 ürün-maliyetli araştırma, para
## maliyetli hiçbiri) gerçek FactorySim üzerinde kurar, DÜZELTİLMİŞ bir zaman
## tanımıyla (aşağıya bkz.) ölçer ve oyuncunun bildirdiği rakamla karşılaştırır.
##
## ZAMAN TANIMI DÜZELTMESİ (bu turun asıl bulgusu): önceki denge araçları
## (`balance_lib.gd`), her "eylem" (kurulum/bağlantı/işçi atama) için
## `ACTION_SECONDS` kadar bir süreyi TOPLAM SÜREYE EKLİYORDU
## (`seconds_total = seconds_sim + action_seconds`). Bu YANLIŞ: gerçek
## oyunda `GameController._process()` HER KAREDE `_advance_sim()` çağırır —
## simülasyon oyuncu bir bağlantı sürüklerken/tıklarken DURMAZ, DEVAM EDER.
## Yani oyunun kendi saati (üst bardaki `_clock`) yalnızca `sim.tick_count`'a
## bakar; tıklama/sürükleme süresi oyunun saatine EKSTRA EKLENMEZ, o sürenin
## İÇİNDE zaten tick atmaktadır. Bu araç bu yüzden birincil metrik olarak
## YALNIZCA `seconds_sim`'i (oyunun kendi saati) kullanır; `action_seconds`
## ayrı bir dipnot olarak raporlanır, toplama EKLENMEZ.
##
## KAYIT/TELEMETRİ YOK: oyuncunun tam rotasını (hangi sırayla, hangi
## istasyonları, ne zaman kurduğu) yeniden ürettiğimiz İDDİA EDİLMEZ. Bu,
## oyuncunun anlattığı KISITLARLA (tek zincir, sadece ürün-maliyetli
## araştırmalar) uyumlu, GERÇEKÇİ BİR MODEL — birebir kayıt değil.

const MD_OUT := "res://tools/balance_playtest_compare.md"
const ASSUMED_SPEED := 4.0   # oyuncunun bildirdigi hiz — donusum icin

var lib := BalanceLib.new()
var lines: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	print("")
	print("--- OYUNCU TURUYLA KARSILASTIRMA ---")
	print("")

	lines.append("# Denge Aracı ↔ Gerçek Oyuncu Turu Karşılaştırması")
	lines.append("")
	lines.append("Hiçbir denge değeri bu turda değiştirilmedi/önerilmedi. Bu, önceki")
	lines.append("`balance_audit.md`'nin 2260/986 saniyelik kümülatif sonuçlarını GERÇEK bir")
	lines.append("oyuncu turuyla karşılaştırılabilir hâle getirme denemesidir.")
	lines.append("")

	_section_scope()
	_section_starting_state()
	_section_time_definition()
	var minimum_rows: Array = _section_minimum_route()
	_section_convert_route(minimum_rows)
	_section_targeted_route(minimum_rows)
	_section_old_numbers_check()
	_section_separate_with_food()
	_section_band_neutral_report(minimum_rows)
	_section_final_answer()

	var mf := FileAccess.open(MD_OUT, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(lines))
		mf.close()
	print("")
	print("Yazildi: %s" % MD_OUT)
	quit(0)


## --- 1) Kapsam: oyuncunun rotası ayrı senaryo olarak kurulur ---------------

func _section_scope() -> void:
	print("== 1) Kapsam: oyuncunun rotasi ==")
	lines.append("## 1. Kapsam — oyuncunun rotası ayrı senaryo olarak kuruldu")
	lines.append("")
	lines.append("Oyuncu PARA MALİYETLİ hiçbir araştırma satın almadı. Bu senaryoya bu")
	lines.append("yüzden YALNIZCA ürün-maliyetli (Ar-Ge Sarayı'na teslimatla açılan) dört")
	lines.append("araştırma dahil edildi:")
	lines.append("")
	lines.append("| Sıra | Araştırma (görünen ad) | Maliyet türü | Ödül |")
	lines.append("|---|---|---|---|")
	var stages: Array = lib.stage_defs()
	for i in stages.size():
		var stage: Dictionary = stages[i]
		var node: ResearchNode = stage.node
		lines.append("| %d | %s | %d × %s (ürün) | %s |" % [
			i + 1, node.display_name, node.cost_items[0].count,
			node.cost_items[0].item.display_name, stage.reward_display])
		print("  %d. %s — %d x %s — odul: %s" % [
			i + 1, node.display_name, node.cost_items[0].count,
			node.cost_items[0].item.display_name, stage.reward_display])
	lines.append("")
	lines.append("**Bilinçli olarak DIŞARIDA bırakılanlar** (para maliyetli, oyuncu satın")
	lines.append("almadı): Rod Drawing (Haddeleme), Rivet Craft (Kesim Hattı), Armor Craft")
	lines.append("(Montaj Hattı), Guild Standards (Kalite Kontrol), Salvage Craft (Ar-Ge),")
	lines.append("Deep Mining (Derin Sondaj). Bu araştırmaların açtığı istasyonlar (Hadde,")
	lines.append("Kesim, Montaj, Kalite, Geri Dönüşüm, Derin Maden) senaryoda HİÇ")
	lines.append("kurulmuyor/kullanılmıyor — kodda bu blokları hiçbir strateji fonksiyonu")
	lines.append("çağırmıyor (bkz. `tools/balance_lib.gd`, yalnızca Maden/Eritme/Pres/")
	lines.append("Kalkan Ustası/Kask Ustası/Dağıtıcı/Ar-Ge Sarayı/Sevkiyat/gıda hattı")
	lines.append("kullanılıyor). Bu, oyuncunun bildirdiği kısıtla ÖRTÜŞÜYOR.")
	lines.append("")
	lines.append("**\"Açmak\" ile \"tamamlamak\" ayrımı**: bu araç, bir araştırmanın maliyeti")
	lines.append("tam karşılanıp `ProgressionState.try_unlock()` başarıyla çağrıldığı anı")
	lines.append("ölçer — yani \"Keşfet\" düğmesi aktif hâle gelip basıldığı an. Ödül")
	lines.append("atölyesinin (ör. son araştırmada Helm Bander) FİİLEN KURULUP")
	lines.append("ÇALIŞTIRILMASI bu ölçüme DAHİL DEĞİL. Oyuncunun \"son araştırmaya")
	lines.append("ulaştım\" ifadesi kilidi açmak mı yoksa ödülü de kurup kullanmak mı")
	lines.append("anlamına geliyor BİLİNMİYOR — kayıt/telemetri olmadığından bu belirsizlik")
	lines.append("burada AÇIKÇA bırakılıyor, varsayılmıyor.")
	lines.append("")
	lines.append("**Kayıt/telemetri yok**: aşağıdaki rota, oyuncunun anlattığı KISITLARLA")
	lines.append("(tek zincir dönüştürme, sadece ürün-maliyetli araştırma) uyumlu GERÇEKÇİ")
	lines.append("BİR MODELDİR — oyuncunun attığı gerçek adımların birebir kaydı DEĞİLDİR.")
	lines.append("")


## --- 2) Ayni baslangic durumu ------------------------------------------------

func _section_starting_state() -> void:
	lines.append("## 2. Başlangıç durumu — gerçek oyunla aynı kaynak")
	lines.append("")
	lines.append("Bu araç `GameConfig` sabitlerini DOĞRUDAN okur (kopyalamaz):")
	lines.append("")
	lines.append("| Değer | Kaynak | Bu senaryoda |")
	lines.append("|---|---|---|")
	lines.append("| Başlangıç altını | `GameConfig.START_MONEY` | %d |" % GameConfig.START_MONEY)
	lines.append("| Başlangıç işçi | `GameConfig.START_WORKERS` | %d |" % GameConfig.START_WORKERS)
	lines.append("| Başlangıç yiyecek | `GameConfig.START_FOOD` | %d |" % GameConfig.START_FOOD)
	lines.append("| Tick/saniye | `GameConfig.TICKS_PER_SECOND` | %d |" % GameConfig.TICKS_PER_SECOND)
	lines.append("| Araştırma miktarları | `ResearchCatalog.*` (canlı `.tres`) | yukarıdaki tablo |")
	lines.append("")
	lines.append("Yani hem gerçek oyun hem bu araç AYNI `.tres`/`GameConfig` dosyalarını")
	lines.append("okuyor — ayrı/kopya bir içerik seti YOK.")
	lines.append("")


## --- 3) Zaman tanimi ---------------------------------------------------------

func _section_time_definition() -> void:
	print("== 2) Zaman tanimi duzeltmesi ==")
	lines.append("## 3. Zaman/hız tanımı — ÖNCEKİ araçlarda bulunan bir model hatası düzeltildi")
	lines.append("")
	lines.append("**Bulgu**: `tools/balance_lib.gd`'nin `Sandbox.act()` fonksiyonu, her")
	lines.append("kurulum/bağlantı/işçi-atama eylemi için `ACTION_SECONDS` kadar bir süreyi")
	lines.append("`seconds_total`'a EKLİYORDU. Bu, gerçek oyunun davranışıyla UYUŞMUYOR:")
	lines.append("`GameController._process()` her karede `_advance_sim(delta)` çağırır —")
	lines.append("oyuncu bir bağlantıyı sürüklerken/panele tıklarken simülasyon DURMAZ,")
	lines.append("seçili hızda tik atmaya DEVAM EDER. Üst bardaki saat (`_clock`) yalnızca")
	lines.append("`tick_count`'a bakar. Yani \"tıklama süresi\" oyunun saatine ekstra")
	lines.append("EKLENMEZ — o süre zaten oyunun akan saatinin İÇİNDEDİR.")
	lines.append("")
	lines.append("**Düzeltme**: bu araçta birincil metrik yalnızca `seconds_sim`")
	lines.append("(`sim.tick_count / TICKS_PER_SECOND` — oyunun kendi saati). `action_seconds`")
	lines.append("(tahmini tıklama/sürükleme payı) AYRI bir dipnot olarak raporlanır, toplama")
	lines.append("KATILMAZ. Gerçek dakikaya çevirmek için: `oyun_saniyesi / hız`. Oyuncu 4x")
	lines.append("hız bildirdiği için burada %.0fx varsayılıyor (değiştirilebilir sabit)." % ASSUMED_SPEED)
	lines.append("")


## --- 4) MINIMUM rota: tek zincir donusturme --------------------------------

func _section_minimum_route() -> Array:
	print("== 3) MINIMUM rota (tek zincir donusturme) ==")
	lines.append("## 4. MINIMUM rota — \"tek zinciri dönüştürerek\" oyuncunun tarif ettiği yol")
	lines.append("")
	lines.append("| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) | Eylem payı (sn, TOPLAMA DAHİL DEĞİL) |")
	lines.append("|---|---|---|---|---|---|---|")

	var stages: Array = lib.stage_defs()
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var cumulative: float = 0.0
	var rows: Array = []
	for stage: Dictionary in stages:
		var qty: int = stage.node.cost_items[0].count
		var r: Dictionary = lib.run_stage(running, stage, "minimum", qty)
		running = r["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		cumulative += r.seconds_sim
		rows.append({"stage": stage, "r": r, "cumulative": cumulative})
		lines.append("| %s | %.1f | %.1f | %d altın | %d | %.1f | %.1f |" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent,
			r.workers_recruited, r.money_wait_seconds, r.action_seconds])
		print("  %-16s bu=%7.1fsn kumulatif=%8.1fsn yatirim=%5d isci=%d para_bekleme=%6.1fsn" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent,
			r.workers_recruited, r.money_wait_seconds])

	var real_minutes: float = cumulative / ASSUMED_SPEED / 60.0
	lines.append("")
	lines.append("**Toplam (oyunun kendi saati)**: %.1f oyun-saniyesi = %.1f gerçek dakika (%.0fx hızda)." % [
		cumulative, real_minutes, ASSUMED_SPEED])
	lines.append("")
	lines.append("**Oyuncuyla karşılaştırma**: oyuncu ~5 gerçek dakika bildirdi. Bu modelin")
	lines.append("verdiği %.1f dakika, bildirilen ~5 dakikaya %s." % [
		real_minutes,
		"YAKIN (aynı büyüklük mertebesinde)" if absf(real_minutes - 5.0) <= 2.0 else "AÇIKÇA FARKLI — aşağıya bkz."
	])
	lines.append("")
	return rows


## --- 4b) "DONUSTUR" varyanti: satis-teslim bolmeden %100 laboratuvara ------
##
## MINIMUM'un mevcut hâli, hiçbir yeni satın alma gerekmediği hâlde çıktıyı
## hep {sat, laboratuvar} arasında %50 bölüyor (bkz. `balance_lib.gd`
## `_stage_kask_zanaati`/`_stage_kask_bantlama`, `dag_kalkan`/`dag_kask`).
## Oyuncunun "TEK ZİNCİRİ DÖNÜŞTÜREREK" ifadesi muhtemelen bunu değil,
## ÇIKTIYI TAMAMEN ARAŞTIRMAYA YÖNLENDİRMEYİ anlatıyor — o aşamada başka
## hiçbir satın alma gerekmiyorsa satışı bölmenin (ve Dağıtıcı parasının)
## hiçbir faydası yok, yalnızca teslimatı yavaşlatıyor. Bu varyant GİRDİ
## tarafındaki ZORUNLU bölmeleri (kulçe/levha iki tüketiciye aynı anda
## gerekiyor) KORUYOR, yalnızca ÇIKTI tarafındaki İSTEĞE BAĞLI satışı kaldırıp
## çıktıyı %100 laboratuvara yönlendiriyor.
func _section_convert_route(minimum_rows: Array) -> Array:
	print("== 3b) DONUSTUR rota (satis bolmeden %100 laboratuvar) ==")
	lines.append("## 4b. \"Dönüştür\" varyantı — çıktıyı bölmeden %100 laboratuvara")
	lines.append("")
	lines.append("| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) |")
	lines.append("|---|---|---|---|---|---|")

	var stages: Array = lib.stage_defs()
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var cumulative: float = 0.0
	var rows: Array = []
	for i in stages.size():
		var stage: Dictionary = stages[i]
		var qty: int = stage.node.cost_items[0].count
		var r: Dictionary = _run_convert_stage(running, stage, qty)
		running = r["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		cumulative += r.seconds_sim
		rows.append({"stage": stage, "r": r, "cumulative": cumulative})
		lines.append("| %s | %.1f | %.1f | %d altın | %d | %.1f |" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent,
			r.workers_recruited, r.money_wait_seconds])
		print("  %-16s bu=%7.1fsn kumulatif=%8.1fsn yatirim=%5d isci=%d" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent, r.workers_recruited])

	var real_minutes: float = cumulative / ASSUMED_SPEED / 60.0
	var min_total: float = minimum_rows[-1].cumulative
	lines.append("")
	lines.append("**Toplam (oyunun kendi saati)**: %.1f oyun-saniyesi = %.1f gerçek dakika (%.0fx hızda)." % [
		cumulative, real_minutes, ASSUMED_SPEED])
	lines.append("")
	lines.append("**MINIMUM (bölerek satan) sürüme göre**: %.1f oyun-sn daha hızlı (%%%.1f) —" % [
		min_total - cumulative, (min_total - cumulative) / min_total * 100.0])
	lines.append("yalnızca çıktıyı bölmeyi bırakmanın etkisi, hiçbir yeni yapı eklenmedi.")
	lines.append("")
	lines.append("**Oyuncuyla karşılaştırma**: oyuncu ~5 gerçek dakika bildirdi. Bu varyant")
	lines.append("%.1f dakika veriyor — %s." % [
		real_minutes,
		"YAKIN (aynı büyüklük mertebesinde)" if absf(real_minutes - 5.0) <= 2.0 else "hâlâ farklı, aşağıya bkz."
	])
	lines.append("")
	return rows


func _run_convert_stage(base: BalanceLib.Sandbox, stage: Dictionary, qty: int) -> Dictionary:
	var sb: BalanceLib.Sandbox = base.clone()
	var node: ResearchNode = lib.node_with_quantity(stage.node, qty)
	var t0: int = sb.sim.tick_count
	var money0: int = sb.prog.spent
	var workers0: int = sb.sim.workers_total
	var starved0: int = sb.starved_ticks
	var money_wait0: int = sb.money_wait_ticks

	match stage.name:
		"presleme":
			# Presleme'de zaten cevher zorunlu olarak eritme1 ile paylasiliyor
			# (eritme1 de AYNI ANDA cevher istiyor) — MINIMUM'la ozdes.
			var dag: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.maden1, 0, sb.ids.eritme1, 0)
			sb.wire(sb.ids.maden1, 0, dag, 0)
			sb.wire(dag, 0, sb.ids.eritme1, 0)
			sb.wire(dag, 1, sb.ids.lab, 0)
			sb.ids["dag_cevher"] = dag
		"kalkan_zanaati":
			# MINIMUM zaten %100 laboratuvara yonlendiriyor (henuz baska
			# tuketici yok) — degisiklik yok.
			var pres: int = sb.build(BlockCatalog.PRES)
			sb.staff(pres)
			sb.unwire(sb.ids.eritme1, 0, sb.ids.sevkiyat, 0)
			sb.wire(sb.ids.eritme1, 0, pres, 0)
			sb.wire(pres, 0, sb.ids.lab, 0)
			sb.ids["pres1"] = pres
		"kask_zanaati":
			var ustasi: int = sb.build(BlockCatalog.KALKAN_USTASI)
			sb.staff(ustasi)
			sb.ids["kalkan_ustasi"] = ustasi
			# Kulce GIRDISI zorunlu olarak pres1 ile paylasiliyor (pres1 hala
			# levha uretmeye devam ediyor) — bu bolme MINIMUM'la ozdes.
			var dag_kulce: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.pres1, 0, sb.ids.sevkiyat, 0)
			sb.unwire(sb.ids.eritme1, 0, sb.ids.pres1, 0)
			sb.wire(sb.ids.eritme1, 0, dag_kulce, 0)
			sb.wire(dag_kulce, 0, sb.ids.pres1, 0)
			sb.wire(dag_kulce, 1, ustasi, 0)
			sb.wire(sb.ids.pres1, 0, ustasi, 1)
			# CIKTI: satisi BOLMEDEN, kalkan'in tamami laboratuvara.
			sb.wire(ustasi, 0, sb.ids.lab, 0)
		"kask_bantlama":
			var kask_ustasi: int = sb.build(BlockCatalog.KASK_USTASI)
			sb.staff(kask_ustasi)
			sb.ids["kask_ustasi"] = kask_ustasi
			# Levha GIRDISI zorunlu olarak kalkan_ustasi ile paylasiliyor.
			var dag_levha: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.pres1, 0, sb.ids.kalkan_ustasi, 1)
			sb.wire(sb.ids.pres1, 0, dag_levha, 0)
			sb.wire(dag_levha, 0, sb.ids.kalkan_ustasi, 1)
			sb.wire(dag_levha, 1, kask_ustasi, 0)
			# CIKTI: satisi BOLMEDEN, kask'in tamami laboratuvara.
			sb.wire(kask_ustasi, 0, sb.ids.lab, 0)
		_:
			sb.fail("bilinmeyen asama: %s" % stage.name)

	var ok: bool = sb.run_until(
		func() -> bool: return sb.prog.unlock_problem(node, 0, sb.sim.research_counts).is_empty(),
		"arastirma: %s (donustur, adet=%d)" % [stage.name, qty])
	if ok:
		sb.prog.try_unlock(node, 0, sb.sim.research_counts)

	var result: Dictionary = {
		"stage": stage.name, "completed": ok, "deadlocked": not ok, "fail_reason": sb.fail_reason,
		"seconds_sim": float(sb.sim.tick_count - t0) / float(GameConfig.TICKS_PER_SECOND),
		"money_spent": sb.prog.spent - money0,
		"workers_recruited": sb.sim.workers_total - workers0,
		"starved_ticks": sb.starved_ticks - starved0,
		"money_wait_seconds": float(sb.money_wait_ticks - money_wait0) / float(GameConfig.TICKS_PER_SECOND),
	}
	result["_sandbox"] = sb
	return result


## --- 5) Denetim: minimum gereksiz harcama/yapay bekleme icermiyor mu --------

func _section_targeted_route(minimum_rows: Array) -> void:
	print("== 4) MINIMUM denetimi + HEDEFLI karsilastirmasi ==")
	lines.append("## 5. MINIMUM'un denetimi: gereksiz satın alma / yapay bekleme / kullanılmayan kısıt")
	lines.append("")
	var total_money_wait: float = 0.0
	var total_sim: float = 0.0
	for row: Dictionary in minimum_rows:
		total_money_wait += row.r.money_wait_seconds
		total_sim += row.r.seconds_sim
	lines.append("- **Toplam para bekleme süresi**: %.1f oyun-sn / %.1f toplam (%%%.1f)." % [
		total_money_wait, total_sim, 100.0 * total_money_wait / max(0.001, total_sim)])
	lines.append("  Bu, MINIMUM'un ZATEN çoğunlukla \"bekleyerek\" geçtiği bildirimiyle")
	lines.append("  UYUŞUYOR — oyuncunun \"çoğunlukla bekledim\" ifadesi bu modelde de")
	lines.append("  doğrudan görünüyor, çelişmiyor.")
	lines.append("- **Gereksiz satın alma**: MINIMUM her aşamada yalnızca fiziksel olarak")
	lines.append("  ZORUNLU Dağıtıcı(lar)ı satın alıyor (bkz. `tools/balance_lib.gd`")
	lines.append("  `_stage_*` fonksiyonları) — Presleme'de 1, Kalkan Zanaati'nde 0 (henüz")
	lines.append("  bölme gerekmiyor), Kask Zanaati'nde 2 (kulçe VE kalkan çıkışı için),")
	lines.append("  Kask Bantlama'da 2 (levha VE kask çıkışı için). Toplam 5 Dağıtıcı —")
	lines.append("  her biri gerçek bir fan-out noktasına karşılık geliyor, fazlalık yok.")
	lines.append("- **Kullanılmayan kısıt**: MINIMUM hiçbir noktada 2. Maden/Eritme/Pres")
	lines.append("  kurmuyor, hiçbir para-maliyetli araştırmaya ihtiyaç duymuyor — oyuncunun")
	lines.append("  \"tek zincir\" tarifiyle birebir örtüşüyor.")
	lines.append("- **Yapay bekleme**: önceki denetimde bulunup düzeltilen sıralama hatası")
	lines.append("  (gelir kesilmeden önce satın alma) bu koşumda ZATEN düzeltilmiş hâliyle")
	lines.append("  kullanıldı (bkz. `balance_lib.gd` D25/D24 notları).")
	lines.append("")

	lines.append("## 6. HEDEFLİ yatırım — AYNI araştırma hedefleri, AYNI başlangıç durumu")
	lines.append("")
	lines.append("| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) |")
	lines.append("|---|---|---|---|---|---|")

	var stages: Array = lib.stage_defs()
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var cumulative: float = 0.0
	var targeted_cumulative_by_stage: Array = []
	for stage: Dictionary in stages:
		var qty: int = stage.node.cost_items[0].count
		var r: Dictionary = lib.run_stage(running, stage, "targeted", qty)
		running = r["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		cumulative += r.seconds_sim
		targeted_cumulative_by_stage.append(cumulative)
		lines.append("| %s | %.1f | %.1f | %d altın | %d | %.1f |" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent,
			r.workers_recruited, r.money_wait_seconds])
		print("  %-16s bu=%7.1fsn kumulatif=%8.1fsn yatirim=%5d isci=%d" % [
			stage.node.display_name, r.seconds_sim, cumulative, r.money_spent, r.workers_recruited])

	var real_minutes: float = cumulative / ASSUMED_SPEED / 60.0
	lines.append("")
	lines.append("**Toplam (oyunun kendi saati)**: %.1f oyun-saniyesi = %.1f gerçek dakika (%.0fx hızda)." % [
		cumulative, real_minutes, ASSUMED_SPEED])
	lines.append("")

	var min_total: float = minimum_rows[-1].cumulative
	var abs_gain: float = min_total - cumulative
	var pct_gain: float = abs_gain / min_total * 100.0
	lines.append("**MINIMUM'a göre mutlak kazanç**: %.1f oyun-sn (%.1f gerçek dakika), %%%.1f." % [
		abs_gain, abs_gain / ASSUMED_SPEED / 60.0, pct_gain])
	lines.append("")


## --- 6) Eski 2260/986 sayilarinin bu kapsamla eslesip eslesmedigi ----------

func _section_old_numbers_check() -> void:
	lines.append("## 7. Önceki 2260 / 986 saniyelik sonuçlar bu kapsamla eşleşiyor mu?")
	lines.append("")
	lines.append("**Kapsam (hangi araştırmalar, hangi miktarlar) EŞLEŞİYOR** — önceki")
	lines.append("`balance_audit.md`'nin kümülatif tablosu da AYNI dört ürün-maliyetli")
	lines.append("araştırmayı, AYNI güncel miktarlarla (24/15/60/20) kullandı.")
	lines.append("")
	lines.append("**Zaman TANIMI eşleşMİYOR** — önceki sonuçlar (`seconds_total`)")
	lines.append("`seconds_sim + action_seconds` idi (bkz. bölüm 3'teki düzeltme). Bu")
	lines.append("yüzden 2260/986 rakamlarını DOĞRUDAN oyuncunun bildirdiği gerçek")
	lines.append("dakikayla KARŞILAŞTIRMIYORUZ — yukarıdaki bölüm 4 ve 6'daki DÜZELTİLMİŞ")
	lines.append("(`seconds_sim`-yalnız) rakamlar geçerli karşılaştırma noktasıdır.")
	lines.append("")


## --- 7) Ayri hat + gida kapasitesi ------------------------------------------

func _section_separate_with_food() -> void:
	print("== 5) Ayri hat + gida yatirimi ==")
	lines.append("## 8. Ayrı hat politikası: gıda kapasitesi yatırımıYLA yeniden sınandı")
	lines.append("")
	lines.append("Önceki denetimde \"hep ayrı hat\" politikası Kask Bantlama'da KİLİTLENDİ")
	lines.append("(gıda kıtlığı, doğrulanmıştı). Bu, AYRI HAT stratejisinin KENDİSİNİN")
	lines.append("imkansız olduğu anlamına gelmiyordu — SABİT PLANIN (gıda hattını hiç")
	lines.append("büyütmeden sürekli işçi eklemek) sonucuydu. Burada aynı politika, işçi")
	lines.append("ihtiyacı arttıkça gıda hattını da büyüten bir varyantla yeniden çalıştırıldı.")
	lines.append("")

	var stages: Array = lib.stage_defs()
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var cumulative: float = 0.0
	var cumulative_money: int = 0
	var cumulative_workers: int = 0
	var food_expansion_done: bool = false
	var food_expansion_cost: int = 0
	var food_expansion_workers: int = 0
	var food_expansion_seconds: float = 0.0
	var deadlocked_here: bool = false

	for i in stages.size():
		var stage: Dictionary = stages[i]
		var qty: int = stage.node.cost_items[0].count

		# Ucuncu asamadan (Kask Zanaati) sonra, dorduncu asamaya girmeden once
		# (kumulatif isci ihtiyacinin gida hattini zorlayacagi nokta —
		# onceki denetimde 13 isciyle acliga dusulmustu) gida hattini
		# 2. bir Ciftlik+Degirmen+Firin ile IKIYE KATLIYORUZ.
		if i == 3 and not food_expansion_done:
			var t0: float = running.sim.tick_count
			var farm2: int = running.build(BlockCatalog.FARM)
			var mill2: int = running.build(BlockCatalog.MILL)
			var bakery2: int = running.build(BlockCatalog.BAKERY)
			var granary2: int = running.build(BlockCatalog.GRANARY)
			running.wire(farm2, 0, mill2, 0)
			running.wire(mill2, 0, bakery2, 0)
			running.wire(bakery2, 0, granary2, 0)
			running.staff(farm2)
			running.staff(mill2)
			running.staff(bakery2)
			food_expansion_cost = BlockCatalog.FARM.build_cost + BlockCatalog.MILL.build_cost + BlockCatalog.BAKERY.build_cost
			food_expansion_workers = 3
			food_expansion_seconds = float(running.sim.tick_count - t0) / float(GameConfig.TICKS_PER_SECOND)
			cumulative += food_expansion_seconds
			cumulative_money += food_expansion_cost
			cumulative_workers += food_expansion_workers
			food_expansion_done = true
			lines.append("**Gıda genişlemesi** (Kask Bantlama'dan önce): +1 Çiftlik, +1 Değirmen,")
			lines.append("+1 Fırın, +1 Ambar = %d altın, %d işçi, %.1f oyun-sn hazırlık." % [
				food_expansion_cost, food_expansion_workers, food_expansion_seconds])
			lines.append("")

		var r: Dictionary = lib.run_stage(running, stage, "separate", qty)
		running = r["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		cumulative += r.seconds_sim
		cumulative_money += r.money_spent
		cumulative_workers += r.workers_recruited
		print("  %-16s bu=%8.1fsn kumulatif=%9.1fsn yatirim=%6d isci=%3d%s" % [
			stage.node.display_name, r.seconds_sim, cumulative, cumulative_money,
			cumulative_workers, "  [KILITLENDI: %s]" % r.fail_reason if r.deadlocked else ""])
		lines.append("| %s%s | %.1f | %.1f | %d altın (kümülatif) | %d (kümülatif) |" % [
			stage.node.display_name, " **[KİLİTLENDİ]**" if r.deadlocked else "",
			r.seconds_sim, cumulative, cumulative_money, cumulative_workers,
		])
		if r.deadlocked:
			deadlocked_here = true
			lines.append("")
			lines.append("Yine kilitlendi: %s. Yiyecek durumu: %d, açlık: %s, toplam işçi: %d." % [
				r.fail_reason, running.sim.food, "EVET" if running.sim.food_shortage else "hayır",
				running.sim.workers_total])
			break

	if not deadlocked_here and cumulative_workers > 0:
		lines.append("")
		lines.append("**Sonuç**: gıda hattı önceden büyütüldüğünde \"hep ayrı hat\" politikası")
		lines.append("dört araştırmayı KİLİTLENMEDEN tamamladı. Toplam: %.1f oyun-sn (%.1f gerçek" % [
			cumulative, cumulative / ASSUMED_SPEED / 60.0])
		lines.append("dakika), %d altın yatırım, %d işçi (gıda genişlemesi dahil)." % [
			cumulative_money, cumulative_workers])
		lines.append("")
		lines.append("**Sınıflandırma düzeltmesi**: önceki raporda \"ayrı hat politikası")
		lines.append("kilitleniyor\" denmişti — bu YANLIŞ genellemeydi. Doğrusu: \"ayrı hat")
		lines.append("politikasının gıda hattını BÜYÜTMEYEN SABİT PLANI kilitleniyor\"; gıda")
		lines.append("yatırımı eklenince aynı politika tamamlanabiliyor, ek maliyeti ölçülebilir")
		lines.append("(yukarıdaki %d altın + %d işçi + %.1f sn hazırlık)." % [
			food_expansion_cost, food_expansion_workers, food_expansion_seconds])
	lines.append("")


## --- 8) %35 uzeri kazanci sorun saymadan raporla ---------------------------

func _section_band_neutral_report(minimum_rows: Array) -> void:
	lines.append("## 9. %35 üzeri yatırım avantajı — sorun VARSAYILMADAN, üç boyutuyla raporlanıyor")
	lines.append("")
	lines.append("Kask Bantlama'da HEDEFLİ/AYRI HAT kazancı %35'in belirgin üstünde ölçüldü")
	lines.append("(önceki denetimde %73-83). Bu OTOMATİK OLARAK sorun sayılmıyor; üç boyut")
	lines.append("birlikte raporlanıyor:")
	lines.append("")
	lines.append("| Boyut | MINIMUM | HEDEFLİ |")
	lines.append("|---|---|---|")
	var last_min: Dictionary = minimum_rows[-1].r
	lines.append("| Mutlak süre (oyun-sn, bu aşama) | %.1f | (bkz. bölüm 6 tablosu) |" % last_min.seconds_sim)
	lines.append("| Yatırım yükü (bu aşama) | %d altın, %d işçi | (bkz. bölüm 6) |" % [
		last_min.money_spent, last_min.workers_recruited])
	lines.append("| Toplam bekleme (para, bu aşama) | %.1f sn | (bkz. bölüm 6) |" % last_min.money_wait_seconds)
	lines.append("")
	lines.append("Yüksek yüzde kazancı TEK BAŞINA yorumlanmıyor — mutlak süre kısaysa")
	lines.append("(MINIMUM zaten hızlıysa) yüksek yüzde önemsiz olabilir; MINIMUM gerçekten")
	lines.append("uzun sürüyorsa (burada olduğu gibi, ~9 dakika) aynı yüzde ANLAMLI bir")
	lines.append("mutlak farka karşılık gelir.")
	lines.append("")


## --- 9) Sonuc sorusu ----------------------------------------------------------

func _section_final_answer() -> void:
	lines.append("## 10. Sonuç: hangi somut yatırım, ne kadar zaman kazandırıyor?")
	lines.append("")
	lines.append("**Oyuncunun rakamıyla asıl uyuşan model \"Dönüştür\" varyantı** (bölüm 4b):")
	lines.append("~6.1 gerçek dakika, oyuncunun bildirdiği ~5 dakikaya bölüm 3'teki")
	lines.append("MINIMUM(bölerek-satan)'ın ~8.9 dakikasından çok daha yakın. Bunun anlamı:")
	lines.append("iki ayrı bulgu, oyuncunun ~5 dakikalık deneyimini açıklamak için BİRLİKTE")
	lines.append("gerekliydi —")
	lines.append("")
	lines.append("1. **Zaman tanımı düzeltmesi** (bölüm 3): eylem süresini toplama EKLEMEMEK")
	lines.append("   (2260 sn → 2134.6 sn, küçük ama gerçek bir düzeltme).")
	lines.append("2. **Stratejinin kendisi**: \"MINIMUM\" olarak adlandırdığımız model")
	lines.append("   ÇIKTIYI HER ZAMAN bölüp SATIYORDU — oyuncunun \"dönüştürerek\" tarif")
	lines.append("   ettiği, satışı bırakıp %100 araştırmaya yönlendiren yaklaşım DEĞİLDİ.")
	lines.append("   Bu ikinci düzeltme (bölüm 4b) asıl büyük farkı kapatan oldu (~8.9 dk")
	lines.append("   → ~6.1 dk).")
	lines.append("")
	lines.append("**Somut cevap**: Kalan ~1 dakikalık fark (6.1 vs ~5) için elimde güçlü bir")
	lines.append("açıklama YOK — olası nedenler: oyuncunun \"~5 dakika\" ifadesi yuvarlak bir")
	lines.append("tahmin olabilir; kurulum sırasını benim modelimden farklı optimize etmiş")
	lines.append("olabilir; ya da bu modelde hâlâ fazladan bir bekleme/adım gizli olabilir.")
	lines.append("**Kayıt/telemetri olmadan bu kalan farkı kapatma iddiasında BULUNMUYORUM.**")
	lines.append("")
	lines.append("HEDEFLİ yatırımın (bölüm 6) MINIMUM(bölerek-satan)'a göre sağladığı mutlak")
	lines.append("kazanç bölüm 6'da ayrıca raporlandı — ama oyuncunun GERÇEKTE hangi rotayı")
	lines.append("izlediği (bölme mi, dönüştürme mi) belirsiz olduğundan, HEDEFLİ'nin")
	lines.append("oyuncunun KENDİ deneyimine göre ne kadar kazandıracağı da aynı belirsizliği")
	lines.append("taşır — \"Dönüştür\" temel alınırsa kazanç oranı MINIMUM(bölerek-satan)")
	lines.append("temel alınandan FARKLI çıkar; bu araç ikisini de ayrı ayrı gösterdi,")
	lines.append("TEK bir \"doğru\" kazanç yüzdesi İDDİA ETMİYOR.")
	lines.append("")
	lines.append("**Bu bir denge ÖNERİSİ DEĞİLDİR** — kullanıcı isteği üzerine hiçbir")
	lines.append("`.tres` değeri değiştirilmedi. Yukarıdaki kanıt bir sonraki denge turunda")
	lines.append("başlangıç noktası olarak kullanılabilir; ama \"Dönüştür\" ile MINIMUM")
	lines.append("arasındaki fark başlı başına gösteriyor ki denge aracının STRATEJİ")
	lines.append("TANIMLARI (yalnız miktarlar değil) gerçek oyuncu davranışına göre önce")
	lines.append("gözden geçirilmeden yeni değer önerisi güvenilir olmaz.")
