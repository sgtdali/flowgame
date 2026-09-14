extends SceneTree

## Denge arama aracı: erken oyun ürün-maliyetli araştırma zinciri
## (Presleme -> Kalkan Zanaati -> Kask Zanaati -> Kask Bantlama).
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/balance_search.gd
##
## Paylaşılan mantık (Sandbox, aşama stratejileri) `tools/balance_lib.gd`'de
## yaşıyor — bu dosya yalnızca ARAMA/UYGULAMA akışını sürer. Yalnızca
## MEVCUT değerleri denetlemek için `tools/balance_audit.gd`'yi kullanın;
## o hiçbir değer önermez/uygulamaz.
##
## NE YAPAR: gerçek FactorySim + ProgressionState üzerinde üç oyuncu
## stratejisini (bölerek/dönüştürerek, hedefli yatırım, ayrı hat) simüle
## eder, araştırma miktarlarını dar, gerekçeli aralıklarda tarar, sonuçları
## JSON + okunabilir rapora yazar.
##
## ÖNEMLİ SINIR: Bu araç EKONOMİK TEŞVİKLERİ ölçer. Oyuncunun bunu EĞLENCELİ
## bulup bulmayacağını KANITLAMAZ; onu yalnızca elle oynanan playtest gösterir.

const JSON_OUT := "res://tools/balance_report.json"
const MD_OUT := "res://tools/balance_report.md"

var lib := BalanceLib.new()


func _initialize() -> void:
	print("")
	print("--- DENGE ARAMASI: erken oyun urun-maliyetli arastirma zinciri ---")
	print("")

	var stages: Array = lib.stage_defs()

	print("== 1/3: Mevcut degerlerle temel olcum ==")
	var baseline_report: Array = _measure_current_values(stages)
	_print_baseline_table(baseline_report)

	print("")
	print("== 2/3: Miktar taramasi ==")
	var chosen: Array = _search_quantities(stages)
	_print_choice_table(chosen)

	print("")
	print("== 3/3: Eylem-suresi etkisi (kurulumun 'bedava' olmadigini goster) ==")
	_print_action_time_effect(stages, chosen)

	_write_reports(stages, baseline_report, chosen)

	print("")
	if lib.fail_count > 0:
		print("SONUC: %d olcumde kilitlenme/gecersiz durum tespit edildi — rapora bakin." % lib.fail_count)
		quit(1)
		return
	print("SONUC: arama tamamlandi. Onerilen degerler ve gerekce: %s" % MD_OUT)
	quit(0)


## --- 1) Mevcut degerlerle sorunu goster -------------------------------------

func _measure_current_values(stages: Array) -> Array:
	var out: Array = []
	var running: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	for stage: Dictionary in stages:
		var qty: int = stage.node.cost_items[0].count
		var per_strategy: Dictionary = {}
		for strategy: String in ["minimum", "targeted", "separate"]:
			per_strategy[strategy] = lib.run_stage(running, stage, strategy, qty)
		running = per_strategy["minimum"]["_sandbox"]
		lib.reroute_lab_outputs_to_market(running)
		out.append({"stage": stage.name, "quantity": qty, "results": per_strategy})
	return out


func _print_baseline_table(report: Array) -> void:
	print("%-16s %8s %10s %10s %10s %10s" % [
		"ASAMA", "ADET", "STRATEJI", "SURE(sn)", "PARA", "ISCI"])
	for row: Dictionary in report:
		for strategy: String in ["minimum", "targeted", "separate"]:
			var r: Dictionary = row.results[strategy]
			print("%-16s %8d %10s %10.1f %10d %10d%s" % [
				row.stage, row.quantity, strategy, r.seconds_total,
				r.money_spent, r.workers_recruited,
				"  [KILITLENDI: %s]" % r.fail_reason if r.deadlocked else ""])


## --- 2) Miktar taramasi ------------------------------------------------------

func _search_quantities(stages: Array) -> Array:
	var chosen: Array = []
	var running_normal: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var running_lean: BalanceLib.Sandbox = lib.build_baseline(300, 1.0)

	for stage: Dictionary in stages:
		var best_qty: int = stage.candidates[0]
		var best_row: Dictionary = {}
		var picked: bool = false

		for qty: int in stage.candidates:
			var res_n: Dictionary = _evaluate_candidate(running_normal, stage, qty)
			var res_l: Dictionary = _evaluate_candidate(running_lean, stage, qty)
			var row: Dictionary = {"quantity": qty, "normal": res_n, "lean": res_l}

			var ok_normal: bool = not res_n.minimum.deadlocked and not res_n.targeted.deadlocked and not res_n.separate.deadlocked
			var ok_lean: bool = not res_l.minimum.deadlocked and not res_l.targeted.deadlocked and not res_l.separate.deadlocked
			if not (ok_normal and ok_lean):
				print("  [aday elendi] %s adet=%d: normal(min=%s targ=%s ayri=%s) lean(min=%s targ=%s ayri=%s)" % [
					stage.name, qty,
					res_n.minimum.fail_reason if res_n.minimum.deadlocked else "ok",
					res_n.targeted.fail_reason if res_n.targeted.deadlocked else "ok",
					res_n.separate.fail_reason if res_n.separate.deadlocked else "ok",
					res_l.minimum.fail_reason if res_l.minimum.deadlocked else "ok",
					res_l.targeted.fail_reason if res_l.targeted.deadlocked else "ok",
					res_l.separate.fail_reason if res_l.separate.deadlocked else "ok",
				])
				continue

			if stage.teaching:
				if best_row.is_empty():
					best_qty = qty; best_row = row
				if res_n.minimum.seconds_total <= 180.0 and res_l.minimum.seconds_total <= 180.0:
					best_qty = qty; best_row = row; picked = true
					break
			else:
				var save_n: float = lib.savings(res_n.minimum, res_n.targeted)
				var save_l: float = lib.savings(res_l.minimum, res_l.targeted)
				var in_band_n: bool = save_n >= BalanceLib.TARGET_SAVINGS_MIN and save_n <= BalanceLib.TARGET_SAVINGS_MAX
				var in_band_l: bool = save_l >= BalanceLib.TARGET_SAVINGS_MIN and save_l <= BalanceLib.TARGET_SAVINGS_MAX
				if in_band_n and in_band_l:
					best_qty = qty; best_row = row; picked = true
					break
				if save_n < BalanceLib.TARGET_SAVINGS_MIN and save_l < BalanceLib.TARGET_SAVINGS_MIN:
					best_qty = qty; best_row = row
				elif save_n > BalanceLib.TARGET_SAVINGS_MAX and save_l > BalanceLib.TARGET_SAVINGS_MAX:
					if best_row.is_empty() or not picked:
						best_qty = qty; best_row = row
					break
				elif not picked:
					best_qty = qty; best_row = row

		if best_row.is_empty():
			lib.fail_count += 1
			push_warning("Asama %s: hicbir aday gecerli/tamamlanan bir strateji uretmedi." % stage.name)
		elif not picked:
			push_warning("Asama %s: hicbir aday hedef banda girmedi, en buyuk test edilen aday (%d) kullanildi." % [
				stage.name, best_qty])

		chosen.append({
			"stage": stage.name, "quantity": best_qty, "candidates_tried": stage.candidates,
			"in_target_band": picked, "detail": best_row,
		})
		var advance_n: Dictionary = lib.run_stage(running_normal, stage, "minimum", best_qty)
		var advance_l: Dictionary = lib.run_stage(running_lean, stage, "minimum", best_qty)
		running_normal = advance_n["_sandbox"]
		running_lean = advance_l["_sandbox"]
		lib.reroute_lab_outputs_to_market(running_normal)
		lib.reroute_lab_outputs_to_market(running_lean)

	return chosen


func _evaluate_candidate(running: BalanceLib.Sandbox, stage: Dictionary, qty: int) -> Dictionary:
	return {
		"minimum": lib.run_stage(running, stage, "minimum", qty),
		"targeted": lib.run_stage(running, stage, "targeted", qty),
		"separate": lib.run_stage(running, stage, "separate", qty),
	}


func _print_choice_table(chosen: Array) -> void:
	print("%-16s %10s %8s %14s %14s" % [
		"ASAMA", "SECILEN", "BANTTA?", "HEDEFLI KAZANC", "AYRI HAT KAZANC"])
	for row: Dictionary in chosen:
		var d: Dictionary = row.detail
		var save_t: float = 0.0
		var save_s: float = 0.0
		if d.has("normal"):
			save_t = lib.savings(d.normal.minimum, d.normal.targeted)
			save_s = lib.savings(d.normal.minimum, d.normal.separate)
		print("%-16s %10d %8s %13.1f%% %13.1f%%" % [
			row.stage, row.quantity, "EVET" if row.in_target_band else "hayir (bkz. rapor)",
			save_t * 100.0, save_s * 100.0])


## --- 3) Eylem-suresi etkisi ---------------------------------------------------

func _print_action_time_effect(stages: Array, chosen: Array) -> void:
	var with_actions: BalanceLib.Sandbox = lib.build_baseline(0, 1.0)
	var without_actions: BalanceLib.Sandbox = lib.build_baseline(0, 0.0)
	var total_with: float = 0.0
	var total_without: float = 0.0
	for i in stages.size():
		var stage: Dictionary = stages[i]
		var qty: int = chosen[i].quantity
		var r1: Dictionary = lib.run_stage(with_actions, stage, "minimum", qty)
		var r2: Dictionary = lib.run_stage(without_actions, stage, "minimum", qty)
		with_actions = r1["_sandbox"]
		without_actions = r2["_sandbox"]
		lib.reroute_lab_outputs_to_market(with_actions)
		lib.reroute_lab_outputs_to_market(without_actions)
		total_with += r1.seconds_total
		total_without += r2.seconds_total
	print("Eylem suresi DAHIL toplam (MINIMUM strateji, secilen miktarlar): %.1f sn" % total_with)
	print("Eylem suresi HARIC (yalniz sim saniyesi)                        : %.1f sn" % total_without)
	if total_without > 0.0:
		print("Eylem suresinin payi: %.1f%%" % ((total_with - total_without) / total_with * 100.0))


## --- Raporlama ---------------------------------------------------------------

func _write_reports(stages: Array, baseline_report: Array, chosen: Array) -> void:
	var data: Dictionary = {
		"generated_by": "tools/balance_search.gd",
		"target_savings_band": [BalanceLib.TARGET_SAVINGS_MIN, BalanceLib.TARGET_SAVINGS_MAX],
		"action_seconds_model": BalanceLib.ACTION_SECONDS,
		"baseline_with_current_values": _serialize_report(baseline_report),
		"chosen_values": _serialize_chosen(chosen),
	}
	var f := FileAccess.open(JSON_OUT, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Denge Arama Raporu")
	lines.append("")
	lines.append("Uretici: `tools/balance_search.gd`. Bu rapor EKONOMIK TESVIKLERI olcer")
	lines.append("(hangi strateji ne kadar surede/paraya tamamlaniyor, kaynak nerede")
	lines.append("bekletiyor). Oyuncunun bunu eglenceli bulup bulmayacagini KANITLAMAZ —")
	lines.append("onu yalniz elle oynanan playtest gosterir.")
	lines.append("")
	lines.append("Hedef bant: hedefli/ayri hat yatirimi, MINIMUM stratejiye gore hazirlik")
	lines.append("dahil toplam surede **%%%.0f-%%%.0f** kazanc saglamali (degistirilebilir," % [
		BalanceLib.TARGET_SAVINGS_MIN * 100.0, BalanceLib.TARGET_SAVINGS_MAX * 100.0])
	lines.append("evrensel dogru degil — `BalanceLib.TARGET_SAVINGS_MIN/MAX`).")
	lines.append("")
	lines.append("Ayrintili, sayisal denetim icin (tum stratejilerin tek tabloda")
	lines.append("karsilastirilmasi, kumulatif sure, kilit nedeni analizi) bkz.")
	lines.append("`tools/balance_audit.gd` ve onun uretttigi `tools/balance_audit.md`.")
	lines.append("")
	lines.append("## Bu koşumda taranan adaylar")
	lines.append("")
	lines.append("| Asama | Mevcut | Taranan aday | Bantta mi? | Hedefli kazanc | Ayri hat kazanc |")
	lines.append("|---|---|---|---|---|---|")
	for i in stages.size():
		var stage: Dictionary = stages[i]
		var row: Dictionary = chosen[i]
		var d: Dictionary = row.detail
		var save_t: float = 0.0
		var save_s: float = 0.0
		if d.has("normal"):
			save_t = lib.savings(d.normal.minimum, d.normal.targeted) * 100.0
			save_s = lib.savings(d.normal.minimum, d.normal.separate) * 100.0
		lines.append("| %s (%s / %s → %s) | %d | %d | %s | %%%.1f | %%%.1f |" % [
			stage.name, stage.node.display_name, stage.label, stage.reward_display,
			stage.node.cost_items[0].count, row.quantity,
			"evet" if row.in_target_band else "hayir", save_t, save_s])
	lines.append("")
	lines.append("## Varsayimlar")
	lines.append("")
	lines.append("- Eylem suresi modeli (saniye/eylem): %s" % [BalanceLib.ACTION_SECONDS])
	lines.append("- Iki baslangic senaryosu test edildi: normal (1000 altin) ve az sermaye")
	lines.append("  (efektif 700 altin). Farkli hat kapasiteleri taranmadi — bilinen sinir.")
	lines.append("- Bu arac EKONOMIK TESVIKLERI dogrular; oyuncu KEYFINI degil.")
	lines.append("- Bu dosyadaki 'taranan aday' bir ONERI degil — hedef banda giren EN")
	lines.append("  KUCUK/uygun deger. 'En iyi deger' iddiasi degildir; detay icin")
	lines.append("  balance_audit.md'ye bakin.")

	var mf := FileAccess.open(MD_OUT, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(lines))
		mf.close()

	print("")
	print("Yazildi: %s, %s" % [JSON_OUT, MD_OUT])


func _serialize_report(report: Array) -> Array:
	var out: Array = []
	for row: Dictionary in report:
		var entry: Dictionary = {"stage": row.stage, "quantity": row.quantity, "results": {}}
		for strategy: String in row.results:
			entry.results[strategy] = _serialize_result(row.results[strategy])
		out.append(entry)
	return out


func _serialize_chosen(chosen: Array) -> Array:
	var out: Array = []
	for row: Dictionary in chosen:
		out.append({
			"stage": row.stage, "quantity": row.quantity,
			"candidates_tried": row.candidates_tried, "in_target_band": row.in_target_band,
		})
	return out


func _serialize_result(r: Dictionary) -> Dictionary:
	return {
		"completed": r.completed, "deadlocked": r.deadlocked,
		"ticks": r.ticks, "seconds_sim": r.seconds_sim,
		"action_seconds": r.action_seconds, "seconds_total": r.seconds_total,
		"money_spent": r.money_spent, "workers_recruited": r.workers_recruited,
		"starved_ticks": r.starved_ticks, "money_wait_seconds": r.money_wait_seconds,
	}
