extends SceneTree
## Player inventory: machines cost materials, are carried until placed and come back when
## picked up; outputs and depots are emptied into the inventory only by hand; hand crafting
## runs as a timed queue.

const Simulation = preload("res://sim/production_sim.gd")
var failures := 0

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		push_error(text)

func _initialize() -> void:
	var sim := Simulation.new()
	_check(sim.inventory.get("iron_plate", 0) == 30 and sim.machine_inventory.get("storage", 0) == 1, "Başlangıç kiti envanterde olmalı")

	# Placing uses a carried machine; without one nothing is placed.
	_check(sim.place_machine("press").is_empty(), "Envanterde olmayan makine yerleştirilmemeli")
	var depot := sim.place_machine("storage")
	_check(not depot.is_empty() and not sim.machine_inventory.has("storage"), "Yerleştirilen depo envanterden düşmeli")

	# Hand crafting: materials leave at once, the machine arrives after the craft time.
	_check(not sim.enqueue_craft("machine", "press"), "Boru olmadan pres el ile kuyruğa alınmamalı")
	_check(sim.enqueue_craft("machine", "smelter"), "Malzemesi olan fırın el ile kuyruğa alınmalı")
	_check(sim.inventory.iron_plate == 22 and sim.inventory.iron_rod == 16, "Kuyruğa alınca malzeme düşmeli")
	sim.advance(4.9)
	_check(not sim.machine_inventory.has("smelter"), "Süre dolmadan makine çıkmamalı")
	sim.advance(0.2)
	_check(sim.machine_inventory.get("smelter", 0) == 1 and sim.craft_queue.is_empty(), "Süre dolunca makine envantere gelmeli")
	_check(not sim.enqueue_craft("machine", "machine_shop"), "Kilitli makine el ile yapılmamalı")
	_check(not sim.enqueue_craft("recipe", "pig_iron"), "Fırın reçetesi el ile yapılmamalı")
	sim.inventory["pig_iron"] = 10
	_check(sim.enqueue_craft("recipe", "iron_plate"), "Haddehane reçetesi el ile yapılabilmeli")
	sim.cancel_craft(0)
	_check(sim.inventory.pig_iron == 10 and sim.craft_queue.is_empty(), "İptal edilen işin malzemesi geri gelmeli")
	# Build limit counts carried machines too.
	_check(not sim.enqueue_craft("machine", "copper_mine"), "Sınırı dolan maden el ile yapılmamalı")
	# The hand queue holds at most five different items; more of a queued item joins its run.
	for product in ["pig_iron", "steel_ingot", "iron_plate", "iron_rod", "steel_plate"]:
		sim.inventory[product] = 50
	for r_id in ["iron_plate", "iron_rod", "iron_pipe", "steel_plate", "steel_rod"]:
		_check(sim.enqueue_craft("recipe", r_id), "Kuyruğa %s alınabilmeli" % r_id)
	_check(not sim.enqueue_craft("recipe", "fastener") and not sim.can_craft("recipe", "fastener"), "Altıncı farklı öğe kuyruğa alınmamalı")
	_check(sim.enqueue_craft("recipe", "iron_plate"), "Kuyrukta olan öğeden bir tane daha alınabilmeli")
	var groups := sim.craft_queue_groups()
	_check(groups.size() == 5 and groups[0].id == "iron_plate" and groups[0].count == 2 and sim.craft_queue[1].id == "iron_plate", "Aynı öğe kuyrukta kendi grubuna eklenmeli")
	while not sim.craft_queue.is_empty():
		sim.cancel_craft(0)

	# Outputs stay on the card until taken.
	var mine := sim.place_machine("copper_mine")
	sim.advance(10.0)
	_check(not sim.inventory.has("copper_ore") and sim.machines[mine].output.copper_ore > 0, "Üretim kendiliğinden envantere geçmemeli")
	var taken := sim.take(mine, "copper_ore")
	_check(taken > 0 and sim.inventory.copper_ore == taken and sim.machines[mine].output.copper_ore == 0, "Karttan alınan ürün envantere geçmeli")

	# A depot gets a port per linked product, collects it and hands it over on demand.
	_check(sim.input_products(depot) == [sim.ANY], "Boş deponun tek genel girişi olmalı")
	_check(sim.add_link(mine, depot, 0, 0), "Maden depoya bağlanabilmeli")
	_check(sim.input_products(depot) == ["copper_ore", sim.ANY], "Bağlanan ürün depoda kendi girişini almalı")
	sim.advance(10.0)
	var stored: int = sim.machines[depot].input.copper_ore
	_check(stored > 0, "Depo gelen ürünü biriktirmeli")
	var copy := Simulation.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))), "Envanter ve depo kayda girmeli")
	_check(copy.inventory == sim.inventory and copy.machines[depot].input.copper_ore == stored, "Kayıttan sonra envanter ve depo korunmalı")
	sim.remove_link(mine, depot)
	_check(sim.input_products(depot) == ["copper_ore", sim.ANY], "Bağlantı kesilince dolu depo girişi kalmalı")
	var before: int = sim.inventory.copper_ore
	_check(sim.take(depot, "copper_ore") == stored and sim.inventory.copper_ore == before + stored, "Depodan alınan envantere geçmeli")
	_check(sim.input_products(depot) == [sim.ANY], "Boşalan ve bağlı olmayan depo girişi kalkmalı")

	# Picking up returns the machine and its buffers.
	sim.advance(3.0)
	var left: int = sim.machines[mine].output.copper_ore
	var ore: int = sim.inventory.copper_ore
	sim.pick_up_machine(mine)
	_check(sim.machine_inventory.get("copper_mine", 0) == 1 and sim.inventory.copper_ore == ore + left, "Silinen makine ve içindekiler envantere dönmeli")

	_quick_use()
	_empty_start()
	_hand_feeding()
	_machine_factory()
	_research_effects()

	if failures == 0:
		print("INVENTORY_TESTS_OK")
	quit(failures)

## The game starts on an empty canvas with only the starting kit. It must not be a dead end:
## the iron kit pays for the mines and the furnace, and its steel plates and fasteners for lab 1.
func _empty_start() -> void:
	var sim := Simulation.new()
	_check(sim.machines.is_empty(), "Yeni oyunda tuval boş olmalı")
	for kind in ["iron_mine", "coal_mine", "smelter"]:
		_check(sim.enqueue_craft("machine", kind), "Başlangıç kiti %s üretmeye yetmeli" % kind)
	sim.advance(20.5)
	var iron := sim.place_machine("iron_mine")
	var coal := sim.place_machine("coal_mine")
	var furnace := sim.place_machine("smelter", "steel_ingot")
	_check(not "" in [iron, coal, furnace], "Üretilen çelik hattı yerleştirilebilmeli")
	sim.add_link(coal, furnace)
	sim.add_link(iron, furnace)
	sim.advance(120.0)
	var ingots := sim.take(furnace, "steel_ingot")
	_check(ingots >= 8, "Çelik hattı külçe vermeli (%d)" % ingots)
	# Ingots → plates and rods by hand; rods → fasteners by hand.
	for i in range(6):
		sim.enqueue_craft("recipe", "steel_plate")
	for i in range(2):
		sim.enqueue_craft("recipe", "steel_rod")
	sim.advance(60.0)
	for i in range(3):
		sim.enqueue_craft("recipe", "fastener")
	sim.advance(30.0)
	_check(sim.enqueue_craft("machine", "lab_1"), "Elde yapılan levha ve bağlantı elemanıyla Laboratuvar 1 üretilebilmeli")

## Products dropped from the inventory onto a machine's input run it without a network.
func _hand_feeding() -> void:
	var sim := Simulation.new()
	sim.inventory["iron_ore"] = 20
	sim.inventory["coal"] = 3
	sim.unlock_all()
	var smelter := sim.place_machine("smelter", "pig_iron")
	_check(sim.can_deposit(smelter, "steel_plate") == 0, "Fırın almadığı ürünü kabul etmemeli")
	# Only what fits leaves the inventory.
	_check(sim.deposit(smelter, "iron_ore") == 12 and sim.inventory.iron_ore == 8, "Sığdığı kadar cevher konmalı (kapasite 12)")
	_check(sim.can_deposit(smelter, "copper_ore") == 0, "Pik demir reçetesine bakır cevheri konmamalı")
	var sf := sim.place_machine("smelter", "steel_ingot"); _check(sim.deposit(sf, "coal", 1) == 1 and sim.inventory.coal == 2, "İstenen adet kadar konmalı")
	sim.advance(3.1)
	_check(sim.machines[smelter].output.get("pig_iron", 0) == 2, "Elle beslenen fırın bağlantısız çalışmalı")
	var depot := sim.place_machine("storage")
	_check(sim.deposit(depot, "coal") == 2 and sim.machines[depot].input.coal == 2, "Depo her ürünü almalı")
	_check(sim.deposit(depot, "coal") == 0, "Envanterde olmayan ürün konamamalı")
	# Auto machine: the dropped product chooses the recipe.
	sim.inventory["steel_rod"] = 2
	var winder := sim.place_machine("wire_winder")
	_check(sim.deposit(winder, "steel_rod") == 2 and sim.machines[winder].recipe == "coil", "Konan çubuk tel sarımı bobine çevirmeli")

## The machine factory builds machines from their build cost. Finished machines wait in its
## output (or a linked depot) and become carried machines when taken.
func _machine_factory() -> void:
	var sim := Simulation.new()
	_check(sim.catalog.recipes.has("build__rolling_mill") and not sim.catalog.recipes.has("build__iron_mine"), "Fabrika sınırsız makineleri yapmalı, sınırlı madenleri yapmamalı")
	_check(sim.recipe_mode("machine_factory") == "choose", "Fabrikada makineyi oyuncu seçmeli")
	_check(sim.is_recipe_unlocked("build__rolling_mill") and not sim.is_recipe_unlocked("build__machine_shop"), "Fabrika yalnızca açık makineleri yapmalı")
	var factory := sim.add_machine("machine_factory", "build__rolling_mill")
	sim.machines[factory].input = {"iron_plate": 8, "iron_rod": 6}
	sim.advance(2.6)
	_check(sim.machines[factory].output.get("machine_item__rolling_mill", 0) == 1, "Fabrika kurulum bedelinden makine üretmeli")
	var before := int(sim.machine_inventory.get("rolling_mill", 0))
	_check(sim.take(factory, "machine_item__rolling_mill") == 1 and sim.machine_inventory.get("rolling_mill", 0) == before + 1 and not sim.inventory.has("machine_item__rolling_mill"), "Alınan makine envantere makine olarak geçmeli")
	var depot := sim.add_machine("storage")
	_check(sim.add_link(factory, depot), "Fabrika depoya bağlanabilmeli")
	sim.machines[factory].input = {"iron_plate": 8, "iron_rod": 6}
	sim.advance(3.0)
	_check(sim.machines[depot].input.get("machine_item__rolling_mill", 0) == 1, "Üretilen makine bağlı depoda birikmeli")
	_check(sim.take(depot, "machine_item__rolling_mill") == 1 and sim.machine_inventory.rolling_mill == before + 2, "Depodan alınan makine envantere geçmeli")
	var copy := Simulation.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))), "Fabrikalı ağ kayda girmeli")

## Upgrade researches change numbers instead of opening things: mine limits, machine and
## hand speed, buffer and depot sizes. Their effects survive a save.
func _research_effects() -> void:
	var sim := Simulation.new()
	_check(sim.build_limit("iron_mine") == 1, "Demir madeni başta 1 adet olmalı")
	sim._complete_research("MD-01")
	_check(sim.build_limit("iron_mine") == 2 and sim.build_limit("coal_mine") == 1, "Demir Madeni II yalnız demir madeni sınırını artırmalı")
	var furnace := sim.add_machine("smelter", "pig_iron")
	_check(is_equal_approx(sim.effective_speed(furnace), 20.0), "Araştırmasız fırın hızı 20 olmalı")
	sim._complete_research("VR-02")
	_check(is_equal_approx(sim.effective_speed(furnace), 25.0), "Fırın Verimi I fırını %25 hızlandırmalı")
	sim.machines[furnace].input.iron_ore = 2
	sim.advance(2.45)
	_check(sim.machines[furnace].output.get("pig_iron", 0) == 2, "Hızlanan fırın 60/25 = 2.4 sn'de üretmeli")
	_check(sim.capacity("smelter", "input") == 12 and sim.capacity("storage", "input") == 100, "Araştırmasız kapasiteler katalogdaki gibi olmalı")
	sim._complete_research("LJ-02")
	sim._complete_research("LJ-01")
	_check(sim.capacity("smelter", "input") == 18 and sim.capacity("storage", "input") == 200, "Tampon %50, depo +100 büyümeli")
	sim.machines[furnace].input.iron_ore = 18
	var copy := Simulation.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))) and copy.build_limit("iron_mine") == 2 and copy.capacity("smelter", "input") == 18, "Araştırma etkileri ve büyük tampon kayıttan dönmeli")
	sim._complete_research("VR-01")
	sim.enqueue_craft("machine", "storage")
	sim.advance(3.4)
	_check(sim.machine_inventory.get("storage", 0) == 2, "El Becerisi el üretimini %50 hızlandırmalı (5 sn → 3.3 sn)")

## Quick-use bar: ten pinned keys sharing the inventory's counts.
func _quick_use() -> void:
	var sim := Simulation.new()
	_check(sim.hotbar.size() == 10, "Hızlı erişim 10 yuva olmalı")
	_check(sim.hotbar.slice(0, 7) == ["machine:copper_mine", "machine:quartz_quarry", "machine:storage", "product:iron_plate", "product:iron_rod", "product:steel_plate", "product:fastener"] and sim.hotbar[7] == "", "Başlangıç kiti hızlı erişime dizilmeli")
	# A placed machine keeps its slot at zero.
	sim.place_machine("storage")
	_check(sim.hotbar[2] == "machine:storage" and sim.carried_count("machine:storage") == 0, "Sayısı sıfırlanan öğe yuvasında kalmalı")
	# Moving swaps; unpinning frees the slot; an unpinned item does not come back by itself.
	_check(sim.pin("product:fastener", 0) and sim.hotbar[0] == "product:fastener" and sim.hotbar[6] == "machine:copper_mine", "Dolu yuvaya taşıma yer değiştirmeli")
	sim.unpin(0)
	_check(sim.hotbar[0] == "" and not ("product:fastener" in sim.hotbar), "Çıkarılan öğe yuvayı boşaltmalı")
	sim.inventory.fastener += 1
	_check(not ("product:fastener" in sim.hotbar), "Elde olan öğe çıkarıldıktan sonra kendiliğinden geri gelmemeli")
	# Something newly carried takes the first free slot.
	var mine := sim.place_machine("copper_mine")
	sim.advance(5.0)
	sim.take(mine, "copper_ore")
	_check(sim.hotbar[0] == "product:copper_ore", "Yeni gelen öğe ilk boş yuvaya girmeli")
	_check(not sim.pin("product:not_a_product"), "Bilinmeyen öğe sabitlenmemeli")
	for p in ["steel_rod", "gear", "bearing", "copper_wire", "coil"]:
		sim.pin("product:" + p)
	_check(not ("" in sim.hotbar) and not sim.pin("product:circuit_board"), "Dolu çubuğa yeni öğe sabitlenmemeli")
	var copy := Simulation.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(sim.snapshot()))) and copy.hotbar == sim.hotbar, "Hızlı erişim kayda girmeli")
	var old_save: Dictionary = sim.snapshot()
	old_save.erase("hotbar")
	_check(copy.restore(old_save), "Hızlı erişimi olmayan eski kayıt yüklenebilmeli")
	var broken: Dictionary = sim.snapshot()
	broken.hotbar = ["product:nope", "", "", "", "", "", "", "", "", ""]
	_check(not copy.restore(broken), "Bozuk hızlı erişim kaydı reddedilmeli")
