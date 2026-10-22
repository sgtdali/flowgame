extends SceneTree

const Simulation = preload("res://sim/production_sim.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	_catalog_and_reachability()
	_timing()
	_inputs_and_blocking()
	_sharing_and_byproducts()
	_research_progression()
	_save_resume()
	_conservation()
	if failures.is_empty():
		print("PRODUCTION_TESTS_OK: %d kontrol geçti" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _catalog_and_reachability() -> void:
	var sim := Simulation.new()
	_check(sim.catalog.products.size() == 24, "Katalogda tam 24 ürün bulunmalı")
	_check(sim.catalog.researches.size() == 9, "Katalogda tam 9 araştırma (A-01 – A-09) bulunmalı")
	# Kademe 0'dan başlayarak 9 araştırmanın tamamının kilitlenmeden (deadlock olmadan)
	# yalnızca o an açık makine/reçetelerle üretilebilen ürünlerle açılabildiğini doğrula.
	var producible := {}
	var update_producible := func() -> void:
		var changed := true
		while changed:
			changed = false
			for m_kind in sim.unlocked_machines:
				var m_spec: Dictionary = sim.catalog.machines[m_kind]
				for r_id in m_spec.get("recipes", [m_spec.recipe]):
					if not sim.is_recipe_unlocked(str(r_id)):
						continue
					var r_spec: Dictionary = sim.catalog.recipes[r_id]
					var can_make := true
					for in_p in r_spec.inputs:
						if not producible.has(in_p):
							can_make = false
							break
					if can_make:
						for out_p in r_spec.outputs:
							if not producible.has(out_p):
								producible[out_p] = true
								changed = true
	update_producible.call()
	_check(producible.size() == 11, "Başlangıçta (Kademe 0) 4 hammadde + 7 temel ürün (toplam 11 ürün) üretilebilir olmalı")
	var order := ["A-01", "A-02", "A-03", "A-04", "A-05", "A-06", "A-07", "A-08", "A-09"]
	for tech_id in order:
		_check(sim.can_research(tech_id), "%s araştırması ön koşul sırasıyla açılabilir olmalı" % tech_id)
		var r_recipe: Dictionary = sim.catalog.recipes[sim.catalog.researches[tech_id].recipe]
		var inputs_ready := true
		for in_p in r_recipe.inputs:
			if not producible.has(in_p):
				inputs_ready = false
		_check(inputs_ready, "%s araştırmasının tüm girdileri önceden üretilebilir olmalı (kilitlenme olmamalı)" % tech_id)
		sim._complete_research(tech_id)
		update_producible.call()
	_check(producible.size() == 24, "9 araştırma tamamlandığında 24 ürünün tamamı üretilebilir olmalı")

func _timing() -> void:
	var sim := Simulation.new()
	var cnc := sim.add_machine("cnc", "gear_cnc")
	sim.machines[cnc].input.steel_rod = 2
	sim.advance(4.95)
	_check(sim.machines[cnc].completed == 0, "5 saniyeden önce dişli oluşmamalı")
	_check(sim.machines[cnc].input.steel_rod == 0, "Girdiler başlangıçta tüketilmeli")
	sim.advance(0.05)
	_check(sim.machines[cnc].completed == 1 and sim.machines[cnc].output.gear == 1 and sim.machines[cnc].output.metal_scrap == 1, "100/20=5 saniyede 1 dişli + 1 metal talaşı üretilmeli")
	var fast := Simulation.new()
	var fast_id := fast.add_machine("cnc", "gear_cnc")
	fast.machines[fast_id].speed = 40.0
	fast.machines[fast_id].input.steel_rod = 2
	fast.advance(2.5)
	_check(fast.machines[fast_id].completed == 1, "100/40=2.5 saniye")
	var sliced := Simulation.new()
	var sliced_id := sliced.add_machine("cnc", "gear_cnc")
	sliced.machines[sliced_id].input.steel_rod = 2
	for i in range(300):
		sliced.advance(1.0 / 60.0)
	_check(sliced.machines[sliced_id].completed == 1, "Kare süresi dilimlemesi üretimi değiştirmemeli")
	_check(is_equal_approx(sliced.elapsed, 5.0), "Sabit adım saati 5 saniye olmalı")

func _inputs_and_blocking() -> void:
	var sim := Simulation.new()
	var id := sim.add_machine("cnc", "gear_cnc")
	sim.machines[id].input.steel_rod = 1
	sim.advance(10.0)
	_check(sim.machines[id].input.steel_rod == 1 and sim.machines[id].completed == 0, "Eksik girdi tüketilmemeli")
	sim.machines[id].input.steel_rod = 2
	sim.machines[id].output.gear = 10
	sim.advance(5.0)
	_check(sim.machines[id].input.steel_rod == 2 and not sim.machines[id].running, "Dolu çıkışta yeni iş başlamamalı")
	sim.machines[id].output.gear = 0
	sim.advance(1.0)
	sim.machines[id].enabled = false
	sim.advance(4.0)
	_check(sim.machines[id].completed == 1, "Durdurulan makine başlamış işi tamamlamalı")
	sim.machines[id].input.steel_rod = 8
	sim.advance(10.0)
	_check(sim.machines[id].completed == 1, "Durdurulan makine yeni iş başlatmamalı")
	# Çok girdili reçete ve alternatif yöntem testi (Ergitme fırını + Dökümhane)
	var smelter := sim.add_machine("smelter", "pig_iron")
	sim.machines[smelter].input.iron_ore = 2
	sim.advance(5.0)
	_check(sim.machines[smelter].input.iron_ore == 2 and sim.machines[smelter].completed == 0, "Kömür eksikse demir cevheri tek başına tüketilmemeli")
	sim.machines[smelter].input.coal = 1
	sim.advance(3.0)
	_check(sim.machines[smelter].output.pig_iron == 2, "Ergitme fırını 2 demir cevheri + 1 kömür ile 2 pik demir üretmeli")
	var foundry := sim.add_machine("foundry", "gear_cast")
	sim.add_link(smelter, foundry)
	sim.advance(3.05)
	_check(sim.machines[foundry].output.gear == 1, "Dökümhane pik demirden alternatif yöntemle dişli üretmeli")

func _sharing_and_byproducts() -> void:
	var sim := Simulation.new()
	var mill := sim.add_machine("rolling_mill", "steel_rod")
	var press_a := sim.add_machine("press", "fastener")
	var press_b := sim.add_machine("press", "fastener")
	sim.machines[press_a].enabled = false
	sim.machines[press_b].enabled = false
	_check(sim.add_link(mill, press_a) and sim.add_link(mill, press_b), "Uyumlu iki bağlantı kurulmalı")
	_check(not sim.add_link(mill, press_a), "Aynı hat iki kez kurulmamalı")
	_check(not sim.add_link(mill, mill), "Kendine bağlantı reddedilmeli")
	var iron_mine := sim.add_machine("iron_mine")
	_check(not sim.add_link(iron_mine, press_a), "Yanlış ürün bağlantısı reddedilmeli")
	for i in range(20):
		sim.machines[mill].output.steel_rod = 1
		sim.advance(0.05)
		sim.machines[press_a].input.steel_rod = 0
		sim.machines[press_b].input.steel_rod = 0
	_check(sim.machines[press_a].received == 10 and sim.machines[press_b].received == 10, "Tek tek gelen 20 ürün 10/10 paylaşılmalı")
	sim.machines[press_a].input.steel_rod = 12
	sim.machines[mill].output.steel_rod = 3
	sim.advance(0.05)
	_check(sim.machines[press_a].received == 10 and sim.machines[press_b].received == 13, "Dolu alıcının bütün payı diğerine gitmeli")
	sim.machines[press_b].input.steel_rod = 12
	sim.machines[mill].output.steel_rod = 2
	sim.advance(0.05)
	_check(sim.machines[mill].output.steel_rod == 2, "İki alıcı doluysa ürün çıkışta kalmalı")
	sim.remove_machine(press_a)
	sim.machines[press_b].input.steel_rod = 0
	sim.advance(0.05)
	_check(sim.machines[press_b].received == 15, "Alıcı silindikten sonra kalan hat çalışmalı")
	# Yan ürün (Metal Talaşı) geri kazanım bağlantısı testi
	var cnc := sim.add_machine("cnc", "gear_cnc")
	var furnace := sim.add_machine("steel_furnace", "steel_from_scrap")
	var gearbox_asm := sim.add_machine("assembler", "gearbox")
	_check(sim.add_link(cnc, gearbox_asm, 0, 0), "CNC 0. çıkış portu (dişli) montaj istasyonuna bağlanmalı")
	_check(sim.add_link(cnc, furnace, 1, 0), "CNC 1. çıkış portu (metal talaşı) çelik fırınına bağlanmalı")
	sim.machines[cnc].input.steel_rod = 4
	sim.machines[furnace].input.pig_iron = 1
	sim.advance(14.0)
	_check(sim.machines[gearbox_asm].input.gear == 2, "Üretilen 2 dişli montaj istasyonuna gitmeli")
	_check(sim.machines[furnace].output.steel_ingot == 2, "Üretilen 2 metal talaşı + 1 pik demir çelik fırınında 2 çelik külçeye geri kazanılmalı")

func _research_progression() -> void:
	var sim := Simulation.new()
	var lab1 := sim.add_machine("lab")
	var lab2 := sim.add_machine("lab")
	# A-01 için 7/8 deney tamamlanmış olsun; 2 laboratuvarın ikisi de malzeme alsa bile
	# yalnızca 1 deney başlamalı (Simülasyon İlkeleri: fazla deney başlamamalı).
	sim.research_progress["A-01"] = 7
	for id in [lab1, lab2]:
		sim.machines[id].input.steel_plate = 2
		sim.machines[id].input.steel_rod = 2
		sim.machines[id].input.fastener = 4
	sim.advance(1.0)
	var running_count := (1 if sim.machines[lab1].running else 0) + (1 if sim.machines[lab2].running else 0)
	_check(running_count == 1, "Kalan 1 deney için iki laboratuvar aynı anda fazladan deney başlatmamalı")
	# Araştırma değiştirildiğinde çalışan deney bitmeli ve A-01'e yazılmalı
	_check(sim.set_active_research("A-02"), "Aktif araştırma A-02'ye değiştirilebilmeli")
	sim.advance(5.0)
	_check("A-01" in sim.completed_researches, "Başlamış A-01 deneyi tamamlanıp A-01'i bitirmeli")
	_check(sim.is_machine_unlocked("cnc") and sim.is_machine_unlocked("lathe"), "A-01 bitince Torna ve CNC açılmalı")
	_check(sim.machines[lab1].recipe == "research_A-02" and sim.machines[lab2].recipe == "research_A-02", "Deney bitince laboratuvarlar yeni aktif araştırmaya (A-02) geçmeli")

func _save_resume() -> void:
	var sim := Simulation.new()
	var id := sim.add_machine("cnc", "gear_cnc")
	sim.machines[id].input.steel_rod = 8
	sim.advance(2.15)
	var restored := Simulation.new()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(sim.snapshot()))
	_check(restored.restore(parsed), "Yarım çevrimli JSON kaydı yüklenmeli")
	_check(is_equal_approx(restored.machines[id].remaining, sim.machines[id].remaining), "Kalan iş korunmalı")
	sim.advance(12.0)
	restored.advance(12.0)
	_check(restored.machines[id].output == sim.machines[id].output, "Kayıttan devam ürün miktarını değiştirmemeli")
	_check(is_equal_approx(restored.machines[id].remaining, sim.machines[id].remaining), "Kayıttan devam iş zamanını değiştirmemeli")
	var broken := restored.snapshot()
	broken.machines[id].input.steel_rod = -1
	var before: String = JSON.stringify(restored.snapshot())
	_check(not restored.restore(broken), "Negatif stoklu kayıt reddedilmeli")
	_check(before == JSON.stringify(restored.snapshot()), "Geçersiz kayıt mevcut ağı değiştirmemeli")

func _conservation() -> void:
	var sim := Simulation.new()
	var mill := sim.add_machine("rolling_mill", "steel_rod")
	var cnc := sim.add_machine("cnc", "gear_cnc")
	var disposal := sim.add_machine("scrap_disposal")
	var a := sim.add_machine("assembler", "gearbox")
	var b := sim.add_machine("assembler", "gearbox")
	sim.machines[mill].input.steel_ingot = 10
	sim.add_link(mill, cnc)
	sim.add_link(cnc, disposal, 1, 0)
	sim.add_link(cnc, a, 0, 0)
	sim.add_link(cnc, b, 0, 0)
	sim.advance(120.0)
	var m_cnc: Dictionary = sim.machines[cnc]
	var used_rods := 2 * (int(m_cnc.completed) + (1 if m_cnc.running else 0))
	var produced_rods := 2 * int(sim.machines[mill].completed)
	_check(produced_rods == int(sim.machines[mill].output.steel_rod) + int(m_cnc.input.steel_rod) + used_rods, "Ağda çelik çubuk kaybolmamalı veya çoğalmamalı")
	var accounted: int = int(m_cnc.output.gear) + int(sim.machines[a].input.gear) + int(sim.machines[b].input.gear)
	_check(int(m_cnc.completed) == accounted, "Üretilen dişli sayısı toplam stokla birebir eşleşmeli")
	_check(absi(int(sim.machines[a].received) - int(sim.machines[b].received)) <= 1, "Eşit kabulde uzun dönem fark en çok bir ürün olmalı")
	var copy := Simulation.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))), "Bağlantı ve paylaşım sırası kayıtla yüklenmeli")
	sim.machines[mill].input.steel_ingot = 4
	copy.machines[mill].input.steel_ingot = 4
	sim.advance(30.0)
	copy.advance(30.0)
	_check(copy.machines[a].received == sim.machines[a].received and copy.machines[b].received == sim.machines[b].received, "Yükleme paylaşım sırasını sıfırlamamalı")
