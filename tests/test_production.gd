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
	_build_limits()
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
	_check(sim.catalog.products.size() >= 24, "Katalogda en az 24 ürün bulunmalı")
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
	_check(producible.size() >= 11, "Başlangıçta (Kademe 0) temel ürünler üretilebilir olmalı")
	var order := ["A-01", "A-02", "A-03", "A-04", "A-05", "A-06", "A-07", "A-08", "A-09"]
	for tech_id in order:
		_check(sim.can_research(tech_id), "%s araştırması ön koşul sırasıyla açılabilir olmalı" % tech_id)
		# Every tier the research is priced in needs an unlocked lab whose inputs can be made.
		var inputs_ready := true
		for tier in sim.catalog.researches[tech_id].cost:
			var lab_ready := false
			for m_kind in sim.unlocked_machines:
				var recipe: Dictionary = sim.catalog.recipes[sim.catalog.machines[m_kind].recipe]
				if recipe.get("research_points", {}).has(tier):
					lab_ready = recipe.inputs.keys().all(func(p: String) -> bool: return producible.has(p))
			if not lab_ready:
				inputs_ready = false
		_check(inputs_ready, "%s araştırmasının puanlarını üreten laboratuvar önceden beslenebilir olmalı (kilitlenme olmamalı)" % tech_id)
		sim._complete_research(tech_id)
		update_producible.call()
	_check(producible.size() == sim.catalog.products.size(), "9 araştırma tamamlandığında tüm ürünler üretilebilir olmalı")

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
	# Çok girdili reçete ve alternatif yöntem testi (Çelik fırını + Ergitme fırını + Dökümhane)
	var steel_f := sim.add_machine("steel_furnace", "steel_ingot")
	sim.machines[steel_f].input.iron_ore = 2
	sim.advance(5.0)
	_check(sim.machines[steel_f].input.iron_ore == 2 and sim.machines[steel_f].completed == 0, "Kömür eksikse demir cevheri tek başına tüketilmemeli")
	sim.machines[steel_f].input.coal = 1
	sim.advance(4.1)
	_check(sim.machines[steel_f].output.steel_ingot == 2, "Çelik fırını 2 demir cevheri + 1 kömür ile 2 çelik külçe üretmeli")
	var smelter := sim.add_machine("smelter", "pig_iron")
	sim.machines[smelter].input.iron_ore = 2
	sim.advance(3.0)
	_check(sim.machines[smelter].output.pig_iron == 2, "Ergitme fırını 2 demir cevheri ile 2 pik demir üretmeli")
	var foundry := sim.add_machine("foundry", "gear_cast")
	sim.add_link(smelter, foundry)
	sim.advance(3.05)
	_check(sim.machines[foundry].output.cast_iron_gear == 1, "Dökümhane pik demirden döküm dişli üretmeli")

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
	# Otomatik reçeteli makineler yalnız açık reçetelere bağlanır; bu test araştırmayı atlar.
	sim.unlocked_recipes.append_array(["gearbox", "steel_from_scrap"])
	var cnc := sim.add_machine("cnc", "gear_cnc")
	var furnace := sim.add_machine("steel_furnace", "steel_from_scrap")
	var gearbox_asm := sim.add_machine("assembler", "gearbox")
	_check(sim.add_link(cnc, gearbox_asm, 0, 0), "CNC 0. çıkış portu (dişli) montaj istasyonuna bağlanmalı")
	_check(sim.add_link(cnc, furnace, 1, 0), "CNC 1. çıkış portu (metal talaşı) çelik fırınına bağlanmalı")
	sim.machines[cnc].input.steel_rod = 4
	sim.machines[furnace].input.coal = 1
	sim.advance(14.0)
	_check(sim.machines[gearbox_asm].input.gear == 2, "Üretilen 2 dişli montaj istasyonuna gitmeli")
	_check(sim.machines[furnace].output.steel_ingot == 1, "Üretilen 2 metal talaşı + 1 kömür çelik fırınında 1 çelik külçeye geri kazanılmalı")

func _research_progression() -> void:
	var sim := Simulation.new()
	var lab := sim.add_machine("lab_1")
	var mill := sim.add_machine("rolling_mill", "steel_plate")
	_check(sim.add_link(mill, lab), "Laboratuvar 1 çelik levhayı kabul etmeli")
	# Points made while no research can use them stay in the store.
	sim.active_research = "A-04"
	sim.machines[lab].input.steel_plate = 6
	sim.machines[lab].input.fastener = 6
	sim.advance(20.0)
	_check(sim.research_points.k1 == 6, "Laboratuvar 1 her levha + bağlantı elemanı için 1 K1 puanı üretmeli")
	_check(sim.research_progress["A-04"].is_empty(), "Ön koşulu eksik araştırma puan harcamamalı")
	_check(sim.set_active_research("A-01"), "A-01 seçilebilmeli")
	sim.advance(0.05)
	_check(sim.research_progress["A-01"].k1 == 6 and sim.research_points.k1 == 0, "Aktif araştırma depodaki puanı çekmeli")
	sim.research_points.k1 = 100
	sim.advance(0.05)
	_check("A-01" in sim.completed_researches and sim.research_points.k1 == 76, "Fiyat dolunca araştırma bitmeli, artan puan depoda kalmalı")
	_check(sim.is_machine_unlocked("cnc") and sim.is_machine_unlocked("lathe"), "A-01 bitince Torna ve CNC açılmalı")
	_check(sim.set_active_research("A-04"), "A-01 sonrası A-04 seçilebilmeli")
	sim.advance(0.05)
	_check(sim.research_progress["A-04"].k1 == 60 and not ("A-04" in sim.completed_researches), "Eksik K2 varken araştırma bitmemeli")
	sim.research_points.k2 = 30
	sim.advance(0.05)
	_check("A-04" in sim.completed_researches, "K1 ve K2 fiyatı dolunca A-04 bitmeli")
	_check(sim.links.size() == 1, "Araştırma değişince laboratuvar bağlantıları silinmemeli")

func _build_limits() -> void:
	var sim := Simulation.new()
	for kind in ["iron_mine", "copper_mine", "coal_mine", "quartz_quarry"]:
		_check(sim.build_limit(kind) == 1, "%s başlangıçta 1 adetle sınırlı olmalı" % kind)
	var mine := sim.add_machine("iron_mine")
	_check(not mine.is_empty() and not sim.can_build("iron_mine"), "Sınır dolunca maden kurulamaz görünmeli")
	_check(sim.add_machine("iron_mine").is_empty() and sim.built_count("iron_mine") == 1, "Sınırı dolan maden ikinci kez eklenmemeli")
	_check(sim.build_limit("smelter") == -1 and sim.can_build("smelter"), "Sınırsız makineler etkilenmemeli")
	sim.remove_machine(mine)
	_check(sim.can_build("iron_mine"), "Maden silinince yeniden kurulabilmeli")
	sim.unlock_all()
	sim.add_machine("iron_mine")
	_check(not sim.add_machine("iron_mine").is_empty(), "Serbest modda sınır olmamalı")

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
	sim.research_points.k1 = 12
	sim.research_progress["A-01"] = {"k1": 5}
	var research_copy := Simulation.new()
	_check(research_copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))), "Puan deposu ve ilerleme kayda girmeli")
	_check(research_copy.research_points.k1 == 12 and research_copy.research_progress["A-01"].k1 == 5, "Kayıttan sonra puan deposu ve ilerleme korunmalı")
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
