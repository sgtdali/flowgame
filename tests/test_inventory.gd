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

	if failures == 0:
		print("INVENTORY_TESTS_OK")
	quit(failures)
