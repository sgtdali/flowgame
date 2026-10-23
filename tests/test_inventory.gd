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
	_check(sim.inventory.get("steel_plate", 0) == 20 and sim.machine_inventory.get("storage", 0) == 1, "Başlangıç kiti envanterde olmalı")

	# Placing uses a carried machine; without one nothing is placed.
	_check(sim.place_machine("press").is_empty(), "Envanterde olmayan makine yerleştirilmemeli")
	var depot := sim.place_machine("storage")
	_check(not depot.is_empty() and not sim.machine_inventory.has("storage"), "Yerleştirilen depo envanterden düşmeli")

	# Hand crafting: materials leave at once, the machine arrives after the craft time.
	_check(sim.enqueue_craft("machine", "press"), "Malzemesi olan pres el ile kuyruğa alınmalı")
	_check(sim.inventory.steel_plate == 15 and sim.inventory.fastener == 6, "Kuyruğa alınca malzeme düşmeli")
	sim.advance(4.9)
	_check(not sim.machine_inventory.has("press"), "Süre dolmadan makine çıkmamalı")
	sim.advance(0.2)
	_check(sim.machine_inventory.get("press", 0) == 1 and sim.craft_queue.is_empty(), "Süre dolunca makine envantere gelmeli")
	_check(not sim.enqueue_craft("machine", "cnc"), "Kilitli makine el ile yapılmamalı")
	_check(not sim.enqueue_craft("recipe", "pig_iron"), "Fırın reçetesi el ile yapılmamalı")
	_check(sim.enqueue_craft("recipe", "steel_plate"), "Haddehane reçetesi el ile yapılabilmeli")
	sim.cancel_craft(0)
	_check(sim.inventory.steel_ingot == 10 and sim.craft_queue.is_empty(), "İptal edilen işin malzemesi geri gelmeli")
	# Build limit counts carried machines too.
	_check(not sim.enqueue_craft("machine", "copper_mine"), "Sınırı dolan maden el ile yapılmamalı")

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

	if failures == 0:
		print("INVENTORY_TESTS_OK")
	quit(failures)

## The game starts on an empty canvas with only the starting kit. It must not be a dead end:
## the kit pays for the steel line, and its ingots, hand-rolled and pressed, pay for lab 1.
func _empty_start() -> void:
	var sim := Simulation.new()
	_check(sim.machines.is_empty(), "Yeni oyunda tuval boş olmalı")
	for kind in ["iron_mine", "coal_mine", "smelter", "steel_furnace"]:
		_check(sim.enqueue_craft("machine", kind), "Başlangıç kiti %s üretmeye yetmeli" % kind)
	sim.advance(20.5)
	var iron := sim.place_machine("iron_mine")
	var coal := sim.place_machine("coal_mine")
	var smelter := sim.place_machine("smelter")
	var furnace := sim.place_machine("steel_furnace")
	_check(not "" in [iron, coal, smelter, furnace], "Üretilen çelik hattı yerleştirilebilmeli")
	sim.add_link(iron, smelter)
	sim.add_link(coal, smelter)
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
	var sf := sim.place_machine("steel_furnace", "steel_ingot"); _check(sim.deposit(sf, "coal", 1) == 1 and sim.inventory.coal == 2, "İstenen adet kadar konmalı")
	sim.advance(3.1)
	_check(sim.machines[smelter].output.get("pig_iron", 0) == 2, "Elle beslenen fırın bağlantısız çalışmalı")
	var depot := sim.place_machine("storage")
	_check(sim.deposit(depot, "coal") == 2 and sim.machines[depot].input.coal == 2, "Depo her ürünü almalı")
	_check(sim.deposit(depot, "coal") == 0, "Envanterde olmayan ürün konamamalı")
	# Auto machine: the dropped product chooses the recipe.
	sim.inventory["steel_rod"] = 2
	var winder := sim.place_machine("wire_winder")
	_check(sim.deposit(winder, "steel_rod") == 2 and sim.machines[winder].recipe == "coil", "Konan çubuk tel sarımı bobine çevirmeli")

## Quick-use bar: ten pinned keys sharing the inventory's counts.
func _quick_use() -> void:
	var sim := Simulation.new()
	_check(sim.hotbar.size() == 10, "Hızlı erişim 10 yuva olmalı")
	_check(sim.hotbar.slice(0, 6) == ["machine:copper_mine", "machine:quartz_quarry", "machine:storage", "product:steel_ingot", "product:steel_plate", "product:fastener"] and sim.hotbar[6] == "", "Başlangıç kiti hızlı erişime dizilmeli")
	# A placed machine keeps its slot at zero.
	sim.place_machine("storage")
	_check(sim.hotbar[2] == "machine:storage" and sim.carried_count("machine:storage") == 0, "Sayısı sıfırlanan öğe yuvasında kalmalı")
	# Moving swaps; unpinning frees the slot; an unpinned item does not come back by itself.
	_check(sim.pin("product:fastener", 0) and sim.hotbar[0] == "product:fastener" and sim.hotbar[5] == "machine:copper_mine", "Dolu yuvaya taşıma yer değiştirmeli")
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
