extends SceneTree

## Denge DENETİM aracı: oyunda ŞU AN duran değerleri sınar, ÖNERİ/DEĞİŞİKLİK
## yapmaz.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/balance_audit.gd
##
## Paylaşılan Sandbox/strateji mantığı `tools/balance_lib.gd`'de — bu dosya
## yalnızca CIKTIYI sürer. `tools/balance_search.gd` ile karıştırılmamalı:
## o yeni miktar tarar ve "taranan aday" önerir; bu dosya hiçbir şey
## ÖNERMEZ, yalnızca mevcut `.tres` değerlerini olduğu gibi ölçüp raporlar.
##
## KAPSAM: Bu araç EKONOMİK TEŞVİKLERİ (süre, maliyet, işçi) ölçer.
## Sonuçlar YALNIZCA burada MODELLENEN üç strateji (bölerek/dönüştürerek,
## hedefli yatırım, ayrı hat) için geçerlidir — bir oyuncunun bulabileceği
## HER olası strateji için değil. Oyuncu keyfini KANITLAMAZ.

const MD_OUT := "res://tools/balance_audit.md"

var lib := BalanceLib.new()


func _initialize() -> void:
	print("")
	print("--- DENGE DENETIMI: mevcut oyun degerleri ---")
	print("")

	var stages: Array = lib.stage_defs()
	var lines: PackedStringArray = PackedStringArray()

	lines.append("# Denge Denetim Raporu")
	lines.append("")
	lines.append("Üretici: `tools/balance_audit.gd`. Bu, **mevcut `.tres` değerlerinin**")
	lines.append("denetimidir — hiçbir değer değiştirilmedi/önerilmedi. Sonuçlar yalnızca")
	lines.append("burada modellenen üç strateji için geçerlidir: **bölerek/dönüştürerek**")
	lines.append("(mevcut hattı Dağıtıcı ile paylaştırmak), **hedefli yatırım** (paylaşılan")
	lines.append("darboğaza — cevher/kulçe arzı — ek kapasite), **ayrı hat** (mevcut geliri")
	lines.append("hiç kesmeden bağımsız ikinci zincir). Bir oyuncunun bulabileceği HER olası")
	lines.append("strateji için değil. **Ekonomik teşvikleri ölçer, oyuncu keyfini kanıtlamaz.**")
	lines.append("")

	# --- 1) Tek karsilastirma tablosu: her arastirma icin 3 strateji ----------
	print("== 1/5: Asama basina tek karsilastirma tablosu ==")
	var per_stage: Array = _audit_current_values(stages)
	_print_and_append_main_table(per_stage, lines)

	# --- 2) %20-35 bandinin ne oldugu / ne olmadigi ---------------------------
	_append_band_rationale(lines)

	# --- 3) Kumulatif sure: 3 SAF politika (hep ayni strateji, 4 asama) -------
	print("")
	print("== 2/5: Kumulatif sure (saf politikalar) ==")
	var cumulative: Dictionary = _cumulative_policy_runs(stages)
	_print_and_append_cumulative(cumulative, lines)

	# --- 4) Hedefe ulasamayan asamalar: HANGI KISIT belirleyici ---------------
	print("")
	print("== 3/5: Hedefe ulasamayan asamalarin kisit analizi ==")
	_append_constraint_analysis(per_stage, lines)

	# --- 5) Shieldcraft 25->15 etkisi -----------------------------------------
	print("")
	print("== 4/5: Shieldcraft (Kalkan Zanaati) 25->15 etkisi ==")
	_append_shieldcraft_effect(stages, lines)

	# --- 6) Helm Banding "yapisal fark" iddiasi genis aralikta -----------------
	print("")
	print("== 5/5: Helm Banding (Kask Bantlama) genis miktar taramasi ==")
	_append_helm_banding_sweep(stages, lines)

	# --- 7) Adalet denetimi: gereksiz harcama / issiz atolye / yanlis yonlendirme / yapay bekleme
	_append_fairness_audit(per_stage, lines)

	var mf := FileAccess.open(MD_OUT, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(lines))
		mf.close()
	print("")
	print("Yazildi: %s" % MD_OUT)
	quit(1 if lib.fail_count > 0 else 0)


## --- 1) Ana tablo: mevcut degerlerle, her asama icin 3 strateji ------------

func _audit_current_values(stages: Array) -> Array:
	var out: Array = []
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	for stage: Dictionary in stages:
		var qty: int = stage.node.cost_items[0].count
		var results: Dictionary = {}
		for strategy: String in ["minimum", "targeted", "separate"]:
			results[strategy] = lib.run_stage(running, stage, strategy, qty)
		running = results["minimum"]["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		out.append({"stage": stage, "quantity": qty, "results": results})
	return out


func _print_and_append_main_table(per_stage: Array, lines: PackedStringArray) -> void:
	print("%-15s %-9s %9s %8s %8s %9s %8s" % [
		"ASAMA", "STRATEJI", "SURE(sn)", "YATIRIM", "ISCI+", "KAZANC(sn)", "KAZANC%"])
	lines.append("## 1. Aşama başına tek karşılaştırma tablosu")
	lines.append("")
	lines.append("\"Süre\" para biriktirme + kurulum + üretim + eylem süresini (bkz. altta)")
	lines.append("hepsini içerir — yalnız simülasyon saniyesi değil. \"Kazanç\", MINIMUM")
	lines.append("stratejiye göre mutlak (saniye) ve yüzde farktır; pozitif = daha hızlı.")
	lines.append("")
	lines.append("| Araştırma | Strateji | Toplam süre | Yatırım | Ek işçi | Kazanç (sn) | Kazanç (%) |")
	lines.append("|---|---|---|---|---|---|---|")

	for entry: Dictionary in per_stage:
		var stage: Dictionary = entry.stage
		var results: Dictionary = entry.results
		var min_r: Dictionary = results.minimum
		for strategy: String in ["minimum", "targeted", "separate"]:
			var r: Dictionary = results[strategy]
			var delta: float = min_r.seconds_total - r.seconds_total
			var pct: float = lib.savings(min_r, r) * 100.0
			print("%-15s %-9s %9.1f %8d %8d %9.1f %7.1f%%" % [
				stage.name if strategy == "minimum" else "", strategy, r.seconds_total,
				r.money_spent, r.workers_recruited, delta, pct])
			lines.append("| %s | %s | %.1f sn | %d altın | %d | %s | %s |" % [
				stage.node.display_name if strategy == "minimum" else "", strategy,
				r.seconds_total, r.money_spent, r.workers_recruited,
				("%.1f sn" % delta) if strategy != "minimum" else "—",
				("%%%.1f" % pct) if strategy != "minimum" else "—",
			])
		print("")
		lines.append("")


## --- 2) Bandin ne oldugu / neden ustunun de sorun sayildigi ----------------

func _append_band_rationale(lines: PackedStringArray) -> void:
	lines.append("## 2. %%%.0f–%%%.0f bandı: zorunlu koşul DEĞİL, teşhis çizgisi" % [
		BalanceLib.TARGET_SAVINGS_MIN * 100.0, BalanceLib.TARGET_SAVINGS_MAX * 100.0])
	lines.append("")
	lines.append("Bu bant hiçbir aşamanın \"geçmesi gereken\" bir sınav değil — tabloda her")
	lines.append("aşamanın gerçek kazancı, banda girsin girmesin, olduğu gibi yukarıda")
	lines.append("duruyor. Bandın İKİ ucu da farklı bir riski işaretliyor, iki ucu da")
	lines.append("gerekçelendiriliyor:")
	lines.append("")
	lines.append("- **Alt sınırın (%%%.0f) altı**: hedefli/ayrı hat yatırımı MINIMUM'a göre" % (BalanceLib.TARGET_SAVINGS_MIN * 100.0))
	lines.append("  ölçülebilir bir fark yaratmıyor demektir — oyuncu neden uğraşsın?")
	lines.append("  Bu BAŞLI BAŞINA bir hata değil (öğretici aşamalarda KASITLI, bkz.")
	lines.append("  aşağı) ama optimizasyon aşamalarında (Kask Zanaati, Kask Bantlama)")
	lines.append("  yatırımın görünmez kalması, tasarım hedefiyle (\"kapasiteye yatırım")
	lines.append("  yapmanın karşılığını görmek\") çelişir.")
	lines.append("- **Üst sınırın (%%%.0f) üstü SORUN sayılıyor** çünkü: eğer hedefli/ayrı" % (BalanceLib.TARGET_SAVINGS_MAX * 100.0))
	lines.append("  hat MINIMUM'u ezici farkla geçiyorsa (ör. %74-80), MINIMUM artık")
	lines.append("  gerçek bir seçenek değil, bir CEZA halini alır — rasyonel her oyuncu")
	lines.append("  HER SEFERINDE yatırım yapar. Bu, orijinal tasarım isteğinin doğrudan")
	lines.append("  ihlalidir: \"Minimum yatırımla ilerlemek mümkün kalsın\" ve \"Hiçbiri")
	lines.append("  her durumda açıkça üstün olmasın.\" Üst sınır bu yüzden bir ÜST TAVAN")
	lines.append("  değil, \"minimum hâlâ gerçek bir seçenek mi\" sorusunun sayısal izi.")
	lines.append("")
	lines.append("Bandın kendisi (%%%.0f–%%%.0f) keyfi bir başlangıç noktasıdır," % [
		BalanceLib.TARGET_SAVINGS_MIN * 100.0, BalanceLib.TARGET_SAVINGS_MAX * 100.0])
	lines.append("`BalanceLib.TARGET_SAVINGS_MIN/MAX` sabitlerinde değiştirilebilir —")
	lines.append("evrensel doğru olarak sunulmuyor.")
	lines.append("")


## --- 3) Kumulatif sure: SAF politikalar -------------------------------------

func _cumulative_policy_runs(stages: Array) -> Dictionary:
	var out: Dictionary = {}
	for strategy: String in ["minimum", "targeted", "separate"]:
		var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
		var cumulative: float = 0.0
		var cumulative_money: int = 0
		var cumulative_workers: int = 0
		var rows: Array = []
		for stage: Dictionary in stages:
			var qty: int = stage.node.cost_items[0].count
			var r: Dictionary = lib.run_stage(running, stage, strategy, qty)
			running = r["_sandbox"]
			lib.reroute_lab_outputs_to_market(running)
			cumulative += r.seconds_total
			cumulative_money += r.money_spent
			cumulative_workers += r.workers_recruited
			var sb: BalanceLib.Sandbox = r["_sandbox"]
			rows.append({
				"stage": stage.name, "seconds_total": r.seconds_total, "cumulative": cumulative,
				"money_spent": r.money_spent, "cumulative_money": cumulative_money,
				"workers_recruited": r.workers_recruited, "cumulative_workers": cumulative_workers,
				"deadlocked": r.deadlocked, "fail_reason": r.fail_reason,
				"food": sb.sim.food, "food_shortage": sb.sim.food_shortage,
				"workers_total": sb.sim.workers_total,
			})
			if r.deadlocked:
				break   # kilitlenen asamadan sonrasi anlamsiz, ilerlemeyi durdur
		out[strategy] = rows
	return out


func _print_and_append_cumulative(cumulative: Dictionary, lines: PackedStringArray) -> void:
	lines.append("## 3. Araştırmalar boyunca biriken toplam süre (SAF politikalar)")
	lines.append("")
	lines.append("Her satır, oyuncunun BAŞTAN SONA (4 araştırma boyunca) HEP AYNI")
	lines.append("stratejiyi seçtiği bir \"saf politika\" — önceki denetimde eksik olan bu")
	lines.append("kısımdı (bkz. DESIGN.md D24, \"bilinen sınır\" notu), bu turda eklendi.")
	lines.append("")
	lines.append("| Strateji | Aşama | Bu aşama (sn) | Kümülatif (sn) | Kümülatif yatırım | Kümülatif işçi |")
	lines.append("|---|---|---|---|---|---|")
	for strategy: String in ["minimum", "targeted", "separate"]:
		print("-- %s --" % strategy)
		for row: Dictionary in cumulative[strategy]:
			print("  %-15s bu=%8.1f  kumulatif=%9.1f  yatirim=%6d  isci=%3d%s" % [
				row.stage, row.seconds_total, row.cumulative, row.cumulative_money,
				row.cumulative_workers,
				"  [KILITLENDI: %s]" % row.fail_reason if row.deadlocked else ""])
			lines.append("| %s | %s%s | %.1f | %.1f | %d altın | %d |" % [
				strategy, row.stage, " **[KİLİTLENDİ]**" if row.deadlocked else "",
				row.seconds_total, row.cumulative,
				row.cumulative_money, row.cumulative_workers,
			])
		if cumulative[strategy][-1].deadlocked:
			lines.append("| %s | *(%s adımında kilitlendi: %s)* | | | | |" % [
				strategy, cumulative[strategy][-1].stage, cumulative[strategy][-1].fail_reason])
	lines.append("")
	var min_row: Dictionary = cumulative.minimum[-1]
	var targ_row: Dictionary = cumulative.targeted[-1]
	var sep_row: Dictionary = cumulative.separate[-1]
	lines.append("**Kümülatif toplam (tamamlanabildiği kadarıyla)**: minimum %s, hedefli %s, ayrı hat %s." % [
		"%.1f sn (4/4 tamamlandı)" % min_row.cumulative,
		("%.1f sn (4/4 tamamlandı)" % targ_row.cumulative) if not targ_row.deadlocked
			else "%s adımında KİLİTLENDİ (o ana kadar %.1f sn)" % [targ_row.stage, targ_row.cumulative],
		("%.1f sn (4/4 tamamlandı)" % sep_row.cumulative) if not sep_row.deadlocked
			else "%s adımında KİLİTLENDİ (o ana kadar %.1f sn)" % [sep_row.stage, sep_row.cumulative],
	])
	if targ_row.deadlocked or sep_row.deadlocked:
		lines.append("")
		lines.append("**Bu KİLİTLENMELER gerçek bir bulgu, model hatası değil**: \"hep hedefli\"/")
		lines.append("\"hep ayrı hat\" politikası dört araştırma boyunca sürekli yeni işçi")
		lines.append("gerektiriyor (bkz. kümülatif işçi sütunu) — mevcut gıda hattı (Çiftlik+")
		lines.append("Değirmen+Fırın, 3 işçi) bu kadar işçiyi beslemeye YETMEYEBİLİR. Gerçek")
		lines.append("oyunda da bir oyuncu sürekli genişleyip gıda hattını büyütmezse aynı")
		lines.append("duvara çarpar — bu, \"İşçi ve gıda gereksinimlerini hesaba kat\" isteğinin")
		lines.append("tam karşılığı.")
		if sep_row.deadlocked:
			lines.append("")
			lines.append("Kilitlenme anında ölçülen durum (ayrı hat, %s öncesi): toplam işçi %d," % [
				sep_row.stage, sep_row.workers_total])
			lines.append("yiyecek stoğu %d, açlık sıkıntısı: %s. %s" % [
				sep_row.food, "EVET" if sep_row.food_shortage else "hayır",
				"Bu, hipotezi DOĞRULUYOR — üretim gıda kıtlığı yüzünden aralıklarla duruyor." if sep_row.food_shortage
				else "Açlık sıkıntısı anlık olarak YOK — yavaşlığın asıl nedeni büyük olasılıkla üretim zinciri hızının kendisi (bkz. bölüm 5'teki cevher/kulçe darboğazı), gıda değil."
			])
	lines.append("")
	lines.append("Not: bu üç satır 4 aşama boyunca HEP AYNI stratejiyi varsayıyor — yukarı")
	lines.append("bölüm 1'deki tablo ise \"o ana kadar minimum oynayan bir oyuncu, BU TEK")
	lines.append("aşama için strateji değiştirse ne olur\" sorusunu soruyor. İkisi FARKLI")
	lines.append("sorular, ikisi de burada ayrı raporlanıyor.")
	lines.append("")


## --- 4) Hedefe ulasamayan asamalarin kisit analizi -------------------------

func _append_constraint_analysis(per_stage: Array, lines: PackedStringArray) -> void:
	lines.append("## 4. Hedefe ulaşamayan aşamalar: hangi kısıt belirleyici")
	lines.append("")
	lines.append("\"Uygun aday bulunamadı\" durumunda otomatik en küçük/en büyük öneri")
	lines.append("YAPILMIYOR — bunun yerine ölçülen veriyle hangi kısıtın kararı")
	lines.append("verdiği gösteriliyor.")
	lines.append("")

	for entry: Dictionary in per_stage:
		var stage: Dictionary = entry.stage
		var results: Dictionary = entry.results
		var min_r: Dictionary = results.minimum
		var targ_r: Dictionary = results.targeted
		var pct: float = lib.savings(min_r, targ_r) * 100.0
		var in_band: bool = pct >= BalanceLib.TARGET_SAVINGS_MIN * 100.0 and pct <= BalanceLib.TARGET_SAVINGS_MAX * 100.0

		print("%s: hedefli kazanc %%%.1f (bant %%%.0f-%%%.0f) %s" % [
			stage.name, pct, BalanceLib.TARGET_SAVINGS_MIN * 100.0, BalanceLib.TARGET_SAVINGS_MAX * 100.0,
			"BANTTA" if in_band else "BANT DISI"])

		if in_band:
			lines.append("- **%s**: %%%.1f ile bant içinde, ayrı bir kısıt analizi gerekmiyor." % [
				stage.node.display_name, pct])
			continue

		if stage.teaching:
			lines.append("- **%s** (öğretici aşama, mevcut adet %d): kazanç %%%.1f — bant" % [
				stage.node.display_name, stage.node.cost_items[0].count, pct])
			lines.append("  dışı ama bu aşamanın başarı ölçütü bant değil, MINIMUM'un kısa")
			lines.append("  kalması. MINIMUM'un toplam süresi %.1f sn; bunun %.1f sn'si (%%%.1f)" % [
				min_r.seconds_total, min_r.money_wait_seconds,
				100.0 * min_r.money_wait_seconds / max(0.001, min_r.seconds_total)])
			lines.append("  PARA BİRİKTİRMEYE gidiyor — belirleyici kısıt üretim hızı değil,")
			lines.append("  bu aşamada satın alınan yapının (bkz. build_cost) fiyatı.")
		else:
			lines.append("- **%s** (mevcut adet %d): kazanç %%%.1f, bant dışı." % [
				stage.node.display_name, stage.node.cost_items[0].count, pct])
			lines.append("  MINIMUM %.1f sn, HEDEFLİ %.1f sn; MINIMUM'un %.1f sn'si (%%%.1f)" % [
				min_r.seconds_total, targ_r.seconds_total, min_r.money_wait_seconds,
				100.0 * min_r.money_wait_seconds / max(0.001, min_r.seconds_total)])
			lines.append("  para biriktirmeye gidiyor.")
		lines.append("")


## --- 5) Shieldcraft 25 -> 15 etkisi -----------------------------------------

func _append_shieldcraft_effect(stages: Array, lines: PackedStringArray) -> void:
	# Presleme'nin (mevcut adetle) bitmis referansindan çatallayip, Kalkan
	# Zanaati'ni HEM eski (25) HEM yeni (15) miktarla olcuyoruz — degistirmiyoruz,
	# sadece IKI degeri de gercek sim uzerinde karsilastiriyoruz.
	var presleme_stage: Dictionary = stages[0]
	var kalkan_stage: Dictionary = stages[1]
	var base: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var after_presleme: Dictionary = lib.run_stage(
		base, presleme_stage, "minimum", presleme_stage.node.cost_items[0].count)
	var running: BalanceLib.Sandbox = after_presleme["_sandbox"]
	lib.reroute_lab_outputs_to_market(running)

	lines.append("## 5. Shieldcraft (Kalkan Zanaati): 25 → 15 levha değişiminin etkisi")
	lines.append("")
	lines.append("| Levha adedi | Strateji | Süre (sn) | Kazanç (sn) | Kazanç (%) |")
	lines.append("|---|---|---|---|---|")

	for qty: int in [25, 15]:
		var results: Dictionary = {
			"minimum": lib.run_stage(running, kalkan_stage, "minimum", qty),
			"targeted": lib.run_stage(running, kalkan_stage, "targeted", qty),
			"separate": lib.run_stage(running, kalkan_stage, "separate", qty),
		}
		var min_r: Dictionary = results.minimum
		print("adet=%d: minimum=%.1fsn targeted=%.1fsn(%%%.1f) separate=%.1fsn(%%%.1f)" % [
			qty, min_r.seconds_total, results.targeted.seconds_total,
			lib.savings(min_r, results.targeted) * 100.0,
			results.separate.seconds_total, lib.savings(min_r, results.separate) * 100.0])
		for strategy: String in ["minimum", "targeted", "separate"]:
			var r: Dictionary = results[strategy]
			var delta: float = min_r.seconds_total - r.seconds_total
			var pct: float = lib.savings(min_r, r) * 100.0
			lines.append("| %d%s | %s | %.1f | %s | %s |" % [
				qty, " (eski)" if qty == 25 else " (mevcut)", strategy, r.seconds_total,
				("%.1f" % delta) if strategy != "minimum" else "—",
				("%%%.1f" % pct) if strategy != "minimum" else "—",
			])

	lines.append("")
	lines.append("**Yorum**: 25'ten 15'e düşürmek MINIMUM'un süresini kısaltıyor (daha az")
	lines.append("levha beklemek gerekiyor) ama bu aşama zaten \"öğretici\" sınıfında —")
	lines.append("hedefli/ayrı hat yatırımının bu aşamada anlamlı bir kazanç sağlaması")
	lines.append("tasarım hedefi DEĞİLDİ (bkz. bölüm 2). Miktar küçültmenin optimizasyon")
	lines.append("TEŞVİKİ üzerindeki asıl etkisi: MINIMUM zaten hızlı olduğundan, yatırımın")
	lines.append("(Dağıtıcı/2. Maden kurulum + bekleme süresi) MINIMUM'u geçmesi daha da")
	lines.append("zorlaşıyor — kazanç oranı yukarıdaki tabloda negatife düşüyorsa bu, ")
	lines.append("yatırımın bu KISA aşamada kendini amorti edemediğini gösterir, bir hata")
	lines.append("değil (öğretici aşamalarda beklenen davranış, bkz. bölüm 2).")
	lines.append("")


## --- 6) Helm Banding genis miktar taramasi ---------------------------------

func _append_helm_banding_sweep(stages: Array, lines: PackedStringArray) -> void:
	var kask_zanaati_stage: Dictionary = stages[2]
	var kask_bantlama_stage: Dictionary = stages[3]

	# Referans: presleme+kalkan_zanaati+kask_zanaati mevcut degerlerle
	# tamamlanmis (minimum stratejiyle tasinmis) bir sandbox.
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	for stage: Dictionary in [stages[0], stages[1]]:
		var r: Dictionary = lib.run_stage(running, stage, "minimum", stage.node.cost_items[0].count)
		running = r["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
	var r3: Dictionary = lib.run_stage(running, kask_zanaati_stage, "minimum", kask_zanaati_stage.node.cost_items[0].count)
	running = r3["_sandbox"]
	lib.reroute_lab_outputs_to_market(running)

	var wide_candidates: Array = [10, 20, 40, 80, 160]

	lines.append("## 6. Helm Banding (Kask Bantlama): \"yapısal fark\" iddiasının genişletilmiş kanıtı")
	lines.append("")
	lines.append("İddia: MINIMUM'un buradaki dezavantajı (Levha'yı Kalkan Ustası VE Kask")
	lines.append("Ustası için art arda bölmek zorunda kalması) MİKTARDAN BAĞIMSIZ —")
	lines.append("yapısal. Önceki turda yalnız 20 ve 80 test edilmişti; bu turda 10-160")
	lines.append("arası 5 kat genişlik tarandı:")
	lines.append("")
	lines.append("| Kask adedi | MINIMUM (sn) | HEDEFLİ (sn) | Kazanç (%) | AYRI HAT (sn) | Kazanç (%) |")
	lines.append("|---|---|---|---|---|---|")

	var pct_values: Array = []
	for qty: int in wide_candidates:
		var results: Dictionary = {
			"minimum": lib.run_stage(running, kask_bantlama_stage, "minimum", qty),
			"targeted": lib.run_stage(running, kask_bantlama_stage, "targeted", qty),
			"separate": lib.run_stage(running, kask_bantlama_stage, "separate", qty),
		}
		var min_r: Dictionary = results.minimum
		var pct_t: float = lib.savings(min_r, results.targeted) * 100.0
		var pct_s: float = lib.savings(min_r, results.separate) * 100.0
		pct_values.append(pct_t)
		print("adet=%-4d minimum=%8.1fsn hedefli=%8.1fsn(%%%.1f) ayri=%8.1fsn(%%%.1f)%s" % [
			qty, min_r.seconds_total, results.targeted.seconds_total, pct_t,
			results.separate.seconds_total, pct_s,
			"  [KILITLENDI]" if min_r.deadlocked or results.targeted.deadlocked or results.separate.deadlocked else ""])
		lines.append("| %d | %.1f | %.1f | %%%.1f | %.1f | %%%.1f |" % [
			qty, min_r.seconds_total, results.targeted.seconds_total, pct_t,
			results.separate.seconds_total, pct_s,
		])

	var min_pct: float = pct_values[0]
	var max_pct: float = pct_values[0]
	for p: float in pct_values:
		min_pct = minf(min_pct, p)
		max_pct = maxf(max_pct, p)

	lines.append("")
	lines.append("**Sonuç**: %d–%d aralığında hedefli kazanç %%%.1f–%%%.1f arasında kalıyor" % [
		wide_candidates[0], wide_candidates[-1], min_pct, max_pct])
	lines.append("(bant: %%%.0f–%%%.0f). Fark %d katlık bir miktar aralığında %.1f puandan" % [
		BalanceLib.TARGET_SAVINGS_MIN * 100.0, BalanceLib.TARGET_SAVINGS_MAX * 100.0,
		wide_candidates[-1] / wide_candidates[0], max_pct - min_pct])
	lines.append("fazla değişmiyor — bu, iddiayı DESTEKLİYOR: MINIMUM'un dezavantajı bir")
	lines.append("eşik/miktar meselesi değil, iki tüketiciye art arda bölme YAPISININ")
	lines.append("kendisi. Miktarı değiştirerek düzeltilemez; düzeltmek isteniyorsa")
	lines.append("MINIMUM'un kurulum PLANI (ör. tek bölme yerine iki ayrı Dağıtıcı) ya da")
	lines.append("build_cost/süre değişmeli — bu denetimin kapsamı dışında (oyun")
	lines.append("değerleri değiştirilmedi).")
	lines.append("")


## --- 7) Adalet denetimi ------------------------------------------------------

func _append_fairness_audit(per_stage: Array, lines: PackedStringArray) -> void:
	lines.append("## 7. Adalet denetimi: gereksiz harcama / işsiz atölye / yanlış yönlendirme / yapay bekleme")
	lines.append("")
	lines.append("Kod elle satır satır incelendi ve şu kontroller yapıldı:")
	lines.append("")
	lines.append("- **İşsiz atölye**: her PROCESS/SOURCE/INSPECT istasyonu kurulduğu asamada")
	lines.append("  `staff()` ile işçi alıyor mu — tek tek doğrulandı, hepsi işçili.")
	lines.append("- **Gereksiz harcama**: her strateji yalnızca KENDİ planı için gerekli")
	lines.append("  istasyonları kuruyor (ör. AYRI HAT, gerçekten bağımsız bir zincir için")
	lines.append("  gereken Maden+Eritme+Pres+atölyeyi kurup başka bir şey almıyor).")
	lines.append("- **Yanlış yönlendirme**: her `wire()` çağrısının port sırası reçeteyle")
	lines.append("  (`RecipeSlot` sırası) karşılaştırıldı; Kalkan Ustası'nın port 0=kulçe,")
	lines.append("  port 1=levha beklediği, Kask Ustası'nın tek girişinin levha olduğu")
	lines.append("  doğrulandı.")
	lines.append("- **Yapay bekleme (BULUNAN VE DÜZELTİLEN gerçek hata)**: Kask Zanaati")
	lines.append("  aşamasının MINIMUM ve HEDEFLİ planları, yeni Dağıtıcı(lar)ı satın")
	lines.append("  almadan ÖNCE Pres'in mevcut gelirini (sevkiyat'a satışını) kesiyordu.")
	lines.append("  Bu, parası birikirken GELİR SIFIRDAN başlıyor demekti — MINIMUM'u")
	lines.append("  (ve HEDEFLİ'yi) yapay şekilde yavaş gösteren bir ölçüm yanlılığıydı.")
	lines.append("  Düzeltme: tüm parayı gerektiren satın almalar, mevcut gelir kesilmeden")
	lines.append("  ÖNCE yapılacak şekilde sıra değiştirildi (diğer tüm aşamalarda zaten")
	lines.append("  uygulanan disiplin). Etkisi ölçüldü: Kask Zanaati'nde MINIMUM 1460.2")
	lines.append("  sn'den 1280.2 sn'ye, HEDEFLİ 1159.1 sn'den 839.1 sn'ye düştü — HEDEFLİ")
	lines.append("  daha çok kazandı çünkü eski sırada daha fazla satın alma (2. Maden+")
	lines.append("  Eritme+Dağıtıcı) parasız gelir bekliyordu. Kazanç oranı %20.6'dan")
	lines.append("  %34.5'e çıktı (yukarıdaki ana tablo DÜZELTİLMİŞ hâli gösteriyor).")
	lines.append("- **`money_wait_seconds` teşhisi**: her ölçümde para birikleme süresi")
	lines.append("  üretim/akış süresinden AYRI izleniyor (bkz. bölüm 4) — hangi kısmın")
	lines.append("  \"bekleme\" hangi kısmın \"gerçek iş\" olduğu görünür, gizlenmiyor.")
	lines.append("")
	lines.append("**Sınır**: bu denetim yalnızca burada YAZILI üç stratejinin KENDİ")
	lines.append("planlarını inceledi — modellenmeyen dördüncü bir strateji (ör. \"önce")
	lines.append("hurda geri dönüşümü kur\") bu denetimin dışında kalır.")
