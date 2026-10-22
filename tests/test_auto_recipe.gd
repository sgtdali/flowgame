extends SceneTree
## Recipe selection rules: "auto" machines follow what is linked into them, "choose"
## machines (same inputs, different products) keep the recipe the player picked.

const Simulation = preload("res://sim/production_sim.gd")
var failures := 0

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		push_error(text)

func _initialize() -> void:
	var sim := Simulation.new()
	sim.unlock_all()
	for kind in ["smelter", "steel_furnace", "press", "wire_winder", "assembler"]:
		_check(sim.recipe_mode(kind) == "auto", "%s girdisine göre reçete seçmeli" % kind)
	for kind in ["rolling_mill", "cnc", "foundry"]:
		_check(sim.recipe_mode(kind) == "choose", "%s aynı girdiden farklı ürün yaptığı için seçimli olmalı" % kind)
	_check(sim.recipe_mode("iron_mine") == "fixed" and sim.recipe_mode("lab") == "fixed", "Tek reçeteli makineler ve laboratuvar sabit kalmalı")

	var smelter := sim.add_machine("smelter")
	_check(sim.input_products(smelter) == [sim.ANY], "Boş fırında tek genel giriş olmalı")
	var copper_mine := sim.add_machine("copper_mine")
	_check(sim.add_link(copper_mine, smelter, 0, 0), "Bakır cevheri genel girişe bağlanmalı")
	_check(sim.machines[smelter].recipe == "copper_ingot", "Bakır cevheri gelince fırın bakır külçe üretmeli")
	_check(sim.input_products(smelter) == ["copper_ore"], "Reçete belli olunca girişler reçeteden gelmeli")
	sim.remove_link(copper_mine, smelter, 0, 0)
	_check(sim.input_products(smelter) == [sim.ANY] and sim.machines[smelter].recipe == "copper_ingot", "Bağlantı kopunca genel giriş dönmeli, son reçete korunmalı")

	var coal_mine := sim.add_machine("coal_mine")
	_check(sim.add_link(coal_mine, smelter, 0, 0), "Kömür genel girişe bağlanmalı")
	_check(sim.machines[smelter].recipe == "pig_iron", "Kömür gelince fırın pik demire geçmeli")
	_check(sim.input_products(smelter) == ["iron_ore", "coal"], "Pik demir reçetesi demir cevheri ve kömür girişi açmalı")
	var quartz := sim.add_machine("quartz_quarry")
	_check(not sim.add_link(quartz, smelter), "Kömürle uyuşmayan kuvars bağlanmamalı")
	var iron_mine := sim.add_machine("iron_mine")
	_check(sim.add_link(iron_mine, smelter, 0, 0), "Demir cevheri kendi girişine bağlanmalı")
	sim.machines[smelter].input = {"iron_ore": 2, "coal": 1}
	sim.links.clear()
	sim.advance(3.1)
	_check(sim.machines[smelter].output.get("pig_iron", 0) == 2, "Otomatik seçilen reçete üretmeli")

	# Steel furnace: pig iron fits both recipes, so the open input stays until coal or scrap.
	var furnace := sim.add_machine("steel_furnace")
	var pig_source := sim.add_machine("smelter", "pig_iron")
	_check(sim.add_link(pig_source, furnace, 0, 0), "Pik demir çelik fırınına bağlanmalı")
	_check(sim.input_products(furnace) == ["pig_iron", sim.ANY], "Belirsizken bağlı ürün ve genel giriş görünmeli")
	_check(sim.add_link(coal_mine, furnace, 0, 1), "Kömür kalan genel girişe bağlanmalı")
	_check(sim.machines[furnace].recipe == "steel_ingot" and sim.input_products(furnace) == ["pig_iron", "coal"], "Pik demir + kömür çelik külçe reçetesini seçmeli")

	# Choose machines keep their recipe whatever is linked.
	var cnc := sim.add_machine("cnc", "bearing")
	var mill := sim.add_machine("rolling_mill", "steel_rod")
	_check(sim.add_link(mill, cnc, 0, 0) and sim.machines[cnc].recipe == "bearing", "Seçimli makinenin reçetesi bağlantıyla değişmemeli")

	# Locked recipes are never picked automatically.
	var fresh := Simulation.new()
	var locked_asm := fresh.add_machine("assembler")
	var lathe := fresh.add_machine("lathe")
	_check(not fresh.add_link(lathe, locked_asm), "Kilitli reçeteye götüren bağlantı kurulmamalı")

	if failures == 0:
		print("AUTO_RECIPE_TESTS_OK")
	quit(failures)
