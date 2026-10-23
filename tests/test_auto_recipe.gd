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
	for kind in ["press", "wire_winder", "assembler"]:
		_check(sim.recipe_mode(kind) == "auto", "%s girdisine göre reçete seçmeli" % kind)
	for kind in ["rolling_mill", "cnc", "foundry"]:
		_check(sim.recipe_mode(kind) == "choose", "%s aynı girdiden farklı ürün yaptığı için seçimli olmalı" % kind)
	# Furnaces are chosen by the player (catalog "recipe_mode"), although their inputs differ.
	for kind in ["smelter", "steel_furnace"]:
		_check(sim.recipe_mode(kind) == "choose", "%s reçetesi oyuncu tarafından seçilmeli" % kind)
	_check(sim.recipe_mode("iron_mine") == "fixed" and sim.recipe_mode("lab_1") == "fixed", "Tek reçeteli makineler ve laboratuvar sabit kalmalı")

	var smelter := sim.add_machine("smelter", "copper_ingot")
	_check(sim.input_products(smelter) == ["copper_ore"], "Seçilen reçetenin girişleri görünmeli")
	var iron_mine := sim.add_machine("iron_mine")
	_check(not sim.add_link(iron_mine, smelter), "Seçili reçeteye uymayan cevher bağlanmamalı")
	_check(sim.set_recipe(smelter, "pig_iron") and sim.input_products(smelter) == ["iron_ore"], "Reçete değişince girişler değişmeli")

	# Wire winder: the linked product picks the recipe; the last one stays when the link goes.
	var winder := sim.add_machine("wire_winder")
	_check(sim.input_products(winder) == [sim.ANY], "Boş tel sarımda tek genel giriş olmalı")
	var copper := sim.add_machine("smelter", "copper_ingot")
	_check(sim.add_link(copper, winder, 0, 0), "Bakır külçe genel girişe bağlanmalı")
	_check(sim.machines[winder].recipe == "copper_wire" and sim.input_products(winder) == ["copper_ingot"], "Bakır külçe gelince bakır tel reçetesi seçilmeli")
	sim.remove_link(copper, winder, 0, 0)
	_check(sim.input_products(winder) == [sim.ANY] and sim.machines[winder].recipe == "copper_wire", "Bağlantı kopunca genel giriş dönmeli, son reçete korunmalı")
	var rods := sim.add_machine("rolling_mill", "steel_rod")
	_check(sim.add_link(rods, winder, 0, 0), "Çelik çubuk genel girişe bağlanmalı")
	_check(sim.machines[winder].recipe == "coil" and sim.input_products(winder) == ["copper_wire", "steel_rod"], "Çubuk gelince bobin reçetesi seçilmeli")
	_check(not sim.add_link(copper, winder), "Bobinle uyuşmayan bakır külçe bağlanmamalı")
	sim.machines[winder].input = {"copper_wire": 2, "steel_rod": 1}
	sim.links.clear()
	sim.advance(4.1)
	_check(sim.machines[winder].output.get("coil", 0) == 1, "Otomatik seçilen reçete üretmeli")

	# Assembler: a shaft fits several recipes, so the open input stays until the next product.
	var asm := sim.add_machine("assembler")
	var lathe_src := sim.add_machine("lathe")
	_check(sim.add_link(lathe_src, asm, 0, 0), "Mil montaja bağlanmalı")
	_check(sim.input_products(asm) == ["shaft", sim.ANY], "Belirsizken bağlı ürün ve genel giriş görünmeli")
	var coils := sim.add_machine("wire_winder", "coil")
	_check(sim.add_link(coils, asm, 0, 1), "Bobin kalan genel girişe bağlanmalı")
	_check(sim.machines[asm].recipe == "electric_motor", "Mil + bobin elektrik motoru reçetesini seçmeli")

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
