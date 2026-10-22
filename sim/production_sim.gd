extends RefCounted
## UI'dan bağımsız, sabit adımlı üretim ve araştırma simülasyonu.
## K-005 (iş/hız çevrimi), K-006 (otomatik eşit paylaşım) ve K-007 (24 ürün + 9 araştırma) kurallarını yürütür.
## Araştırma: laboratuvarlar sabit ürünleri tüketip kademe puanı üretir; puanlar depoda
## birikir ve aktif araştırma fiyatı kadarını depodan çeker.

const STEP := 0.05
const EPSILON := 0.000001
## Placeholder input port of an "auto" machine whose recipe is not settled yet.
const ANY := "*"
## Port types for ANY ports start here (one per machine kind).
const ANY_PORT_BASE := 1000
var catalog: Dictionary
var machines: Dictionary = {}
var links: Array = []
var cursors: Dictionary = {}
var unlocked_machines: Array = []
var unlocked_recipes: Array = []
var completed_researches: Array = []
## tech_id -> {tier: points already spent on it}
var research_progress: Dictionary = {}
## tier -> stored points not yet spent
var research_points: Dictionary = {}
var active_research := "A-01"
var sandbox_mode := false
var elapsed := 0.0
var next_id := 1
var accumulator := 0.0
## kind -> "fixed" (one recipe), "auto" (recipe follows the linked inputs) or
## "choose" (several recipes share the same inputs, so the player picks the product).
var recipe_modes: Dictionary = {}

func _init() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype.json"))
	for m_kind in catalog.get("initial_unlocked_machines", []):
		unlocked_machines.append(str(m_kind))
	for r_id in catalog.get("initial_unlocked_recipes", []):
		unlocked_recipes.append(str(r_id))
	for tech_id in catalog.get("researches", {}):
		research_progress[str(tech_id)] = {}
	for tier in catalog.get("research_tiers", []):
		research_points[str(tier.id)] = 0
	for kind in catalog.machines:
		var allowed: Array = catalog.machines[kind].get("recipes", [catalog.machines[kind].recipe])
		var mode := "fixed"
		if allowed.size() > 1:
			mode = "auto"
			var seen := {}
			for r_id in allowed:
				var key := _input_key(str(r_id))
				if seen.has(key):
					mode = "choose"
				seen[key] = true
		recipe_modes[str(kind)] = mode

func _input_key(recipe_id: String) -> String:
	var keys: Array = catalog.recipes[recipe_id].inputs.keys()
	keys.sort()
	return ",".join(PackedStringArray(keys))

func recipe_mode(kind: String) -> String:
	return str(recipe_modes.get(kind, "fixed"))

## Products currently linked into `id`, in link order, without repeats.
func linked_inputs(id: String) -> Array:
	var products: Array = []
	for link in links:
		if link.to == id and not (link.product in products):
			products.append(link.product)
	return products

## Unlocked recipes of an auto machine that use every product in `products`.
func candidate_recipes(id: String, products: Array) -> Array:
	var spec: Dictionary = catalog.machines[machines[id].kind]
	var result: Array = []
	for r_var in spec.get("recipes", [spec.recipe]):
		var r_id := str(r_var)
		if not is_recipe_unlocked(r_id):
			continue
		var fits := true
		for product in products:
			if not catalog.recipes[r_id].inputs.has(product):
				fits = false
				break
		if fits:
			result.append(r_id)
	return result

## Auto machines settle on the first recipe that matches what is linked into them.
func _resolve_recipe(id: String) -> void:
	if not machines.has(id) or recipe_mode(machines[id].kind) != "auto":
		return
	var candidates := candidate_recipes(id, linked_inputs(id))
	if not candidates.is_empty() and not (machines[id].recipe in candidates):
		set_recipe(id, str(candidates[0]))

func any_port_type(kind: String) -> int:
	return ANY_PORT_BASE + catalog.machines.keys().find(kind)

## Every product some recipe of `kind` consumes: what its ANY port may accept.
func recipe_input_union(kind: String) -> Array:
	var spec: Dictionary = catalog.machines[kind]
	var products: Array = []
	for r_id in spec.get("recipes", [spec.recipe]):
		for product in catalog.recipes[r_id].inputs:
			if not (product in products):
				products.append(product)
	return products

func product_name(product: String) -> String:
	return "Herhangi bir girdi" if product == ANY else str(catalog.products[product].name)

func product_color(product: String) -> Color:
	return Color("7f99aa") if product == ANY else Color(catalog.products[product].color)

func port_type(id: String, product: String) -> int:
	return any_port_type(str(machines[id].kind)) if product == ANY else product_port_type(product)

## Changes whenever a machine's ports change, so the UI knows to rebuild its card.
func port_signature(id: String) -> String:
	return "%s|%s|%s" % [machines[id].recipe, ",".join(PackedStringArray(input_products(id))), ",".join(PackedStringArray(output_products(id)))]

func is_machine_unlocked(kind: String) -> bool:
	return sandbox_mode or kind in unlocked_machines

func is_recipe_unlocked(recipe_id: String) -> bool:
	return sandbox_mode or recipe_id in unlocked_recipes

func unlock_all() -> void:
	sandbox_mode = true
	for kind in catalog.machines:
		if not (str(kind) in unlocked_machines):
			unlocked_machines.append(str(kind))
	for r_id in catalog.recipes:
		if not (str(r_id) in unlocked_recipes):
			unlocked_recipes.append(str(r_id))

func can_research(tech_id: String) -> bool:
	if not catalog.researches.has(tech_id) or tech_id in completed_researches:
		return false
	for prereq in catalog.researches[tech_id].prerequisites:
		if not (str(prereq) in completed_researches):
			return false
	return true

func set_active_research(tech_id: String) -> bool:
	if not can_research(tech_id):
		return false
	active_research = tech_id
	return true

## Share of the research cost already paid, 0..1.
func research_fraction(tech_id: String) -> float:
	var cost: Dictionary = catalog.researches[tech_id].cost
	var total := 0
	var paid := 0
	for tier in cost:
		total += int(cost[tier])
		paid += mini(int(research_progress[tech_id].get(tier, 0)), int(cost[tier]))
	return 1.0 if total == 0 else float(paid) / float(total)

func is_lab(kind: String) -> bool:
	return catalog.recipes[catalog.machines[kind].recipe].has("research_points")

func add_machine(kind: String, recipe_override: String = "") -> String:
	if not catalog.machines.has(kind):
		return ""
	var id := "machine_%d" % next_id
	next_id += 1
	var spec: Dictionary = catalog.machines[kind]
	var recipe_id: String = str(spec.recipe)
	if not recipe_override.is_empty() and recipe_override in spec.get("recipes", [spec.recipe]):
		recipe_id = recipe_override
	var recipe: Dictionary = catalog.recipes[recipe_id]
	var inputs := {}
	var outputs := {}
	for product in recipe.inputs:
		inputs[product] = 0
	for product in recipe.outputs:
		outputs[product] = 0
	machines[id] = {
		"kind": kind, "recipe": recipe_id, "speed": float(spec.speed),
		"enabled": true, "running": false, "remaining": 0.0,
		"input": inputs, "output": outputs, "completed": 0,
		"received": 0, "status": "Hazır", "position": [0.0, 0.0]
	}
	return id

func set_recipe(id: String, recipe_id: String) -> bool:
	if not machines.has(id):
		return false
	var machine: Dictionary = machines[id]
	var spec: Dictionary = catalog.machines[machine.kind]
	var allowed: Array = spec.get("recipes", [spec.recipe])
	if not (recipe_id in allowed) or not catalog.recipes.has(recipe_id):
		return false
	if machine.recipe == recipe_id:
		return true
	var new_recipe: Dictionary = catalog.recipes[recipe_id]
	var new_inputs := {}
	var new_outputs := {}
	for product in new_recipe.inputs:
		new_inputs[product] = mini(int(machine.input.get(product, 0)), int(spec.input_capacity))
	for product in new_recipe.outputs:
		new_outputs[product] = mini(int(machine.output.get(product, 0)), int(spec.output_capacity))
	machine.recipe = recipe_id
	machine.running = false
	machine.remaining = 0.0
	machine.input = new_inputs
	machine.output = new_outputs
	machine.status = "Hazır" if machine.enabled else "Durduruldu"
	links = links.filter(func(link: Dictionary) -> bool:
		if link.from == id and not new_recipe.outputs.has(link.product):
			return false
		if link.to == id and not new_recipe.inputs.has(link.product):
			return false
		return true)
	return true

func clear_outputs(id: String) -> void:
	if not machines.has(id):
		return
	for product in machines[id].output:
		machines[id].output[product] = 0

func recipe_for(id: String) -> Dictionary:
	return catalog.recipes[machines[id].recipe]

func input_products(id: String) -> Array:
	var recipe_inputs: Array = recipe_for(id).inputs.keys()
	if recipe_mode(machines[id].kind) != "auto":
		return recipe_inputs
	# Until the links pin down one recipe, show what is linked plus an open ANY port.
	var linked := linked_inputs(id)
	if candidate_recipes(id, linked).size() == 1 and not linked.is_empty():
		return recipe_inputs
	return linked + [ANY]

func output_products(id: String) -> Array:
	return recipe_for(id).outputs.keys()

func output_product(id: String) -> String:
	var products: Array = output_products(id)
	return "" if products.is_empty() else str(products[0])

func input_product(id: String) -> String:
	var products: Array = input_products(id)
	return "" if products.is_empty() else str(products[0])

func product_port_type(product: String) -> int:
	var keys: Array = catalog.products.keys()
	var idx: int = keys.find(product)
	return maxi(idx, 0)

func unlock_tech_for_machine(kind: String) -> String:
	for tech_id in catalog.get("researches", {}):
		if kind in catalog.researches[tech_id].get("unlock_machines", []):
			return str(tech_id)
	return ""

func unlock_tech_for_recipe(recipe_id: String) -> String:
	for tech_id in catalog.get("researches", {}):
		if recipe_id in catalog.researches[tech_id].get("unlock_recipes", []):
			return str(tech_id)
	return ""

func producers_for(product: String) -> Array:
	var list: Array = []
	for kind in catalog.machines:
		var m_spec: Dictionary = catalog.machines[kind]
		for r_var in m_spec.get("recipes", [m_spec.recipe]):
			var r_id := str(r_var)
			var r_spec: Dictionary = catalog.recipes[r_id]
			if not r_spec.outputs.has(product):
				continue
			# Metal talaşı yan ürünse yalnız metal_scrap arandığında göster
			var outs: Array = r_spec.outputs.keys()
			if product != "metal_scrap" and outs[0] != product:
				continue
			var in_parts: PackedStringArray = []
			for in_p in r_spec.inputs:
				in_parts.append("%d %s" % [int(r_spec.inputs[in_p]), catalog.products[in_p].name.to_lower()])
			var inputs_str := "Hammadde çıkarımı" if in_parts.is_empty() else " + ".join(in_parts)
			var m_unlocked := is_machine_unlocked(str(kind))
			var r_unlocked := is_recipe_unlocked(r_id)
			var req_tech := unlock_tech_for_recipe(r_id)
			if req_tech.is_empty():
				req_tech = unlock_tech_for_machine(str(kind))
			list.append({
				"kind": str(kind),
				"machine_name": str(m_spec.name),
				"recipe": r_id,
				"recipe_name": str(r_spec.get("name", r_id)),
				"inputs_text": inputs_str,
				"output_amount": int(r_spec.outputs[product]),
				"unlocked": m_unlocked and r_unlocked,
				"unlock_tech": req_tech
			})
	return list

func machine_outputs_summary(kind: String) -> String:
	if not catalog.machines.has(kind):
		return ""
	if is_lab(kind):
		return "Araştırma puanı üretir"
	if kind == "project_hub":
		return "Ana proje parçalarını tüketir"
	if kind == "scrap_disposal":
		return "Fazla metal talaşını eritir"
	var m_spec: Dictionary = catalog.machines[kind]
	var names: PackedStringArray = []
	for r_var in m_spec.get("recipes", [m_spec.recipe]):
		var r_spec: Dictionary = catalog.recipes[str(r_var)]
		var outs: Array = r_spec.outputs.keys()
		if outs.is_empty():
			continue
		var primary := str(outs[0])
		var p_name: String = str(catalog.products[primary].name)
		if not (p_name in names):
			names.append(p_name)
	return "Üretir: " + " · ".join(names) if not names.is_empty() else str(m_spec.get("role", ""))

func product_tooltip(product: String) -> String:
	if not catalog.products.has(product):
		return ""
	var p_name: String = str(catalog.products[product].name)
	var producers := producers_for(product)
	if producers.is_empty():
		if product == "metal_scrap":
			return "Metal talaşı (Yan ürün)\nTorna ve CNC tezgâhında işleme sırasında yan ürün olarak çıkar.\nÇelik fırınında Çelik külçeye geri kazanılır."
		return p_name
	var lines: PackedStringArray = ["%s — Nerede üretilir?" % p_name]
	for info in producers:
		var lock_tag := "" if info.unlocked else " [Kilitli: %s]" % info.unlock_tech
		lines.append("• %s: %s → %d %s%s" % [info.machine_name, info.inputs_text, info.output_amount, p_name.to_lower(), lock_tag])
	lines.append("(Karta tıklayıp sağ panelden tek tıkla üretici makine kurup bağlayabilirsin)")
	return "\n".join(lines)

func add_link(from: String, to: String, from_port: int = -1, to_port: int = -1) -> bool:
	if from == to or not machines.has(from) or not machines.has(to):
		return false
	var outs: Array = output_products(from)
	var ins: Array = input_products(to)
	if outs.is_empty() or ins.is_empty():
		return false
	var product := ""
	if from_port >= 0 and to_port >= 0:
		if from_port >= outs.size() or to_port >= ins.size():
			return false
		var out_p := str(outs[from_port])
		var in_p := str(ins[to_port])
		if out_p != in_p and not (in_p == ANY and accepts_new_input(to, out_p)):
			return false
		product = out_p
	else:
		for out_p in outs:
			if out_p in ins or (ANY in ins and accepts_new_input(to, str(out_p))):
				var already := false
				for link in links:
					if link.from == from and link.to == to and link.product == str(out_p):
						already = true
						break
				if not already:
					product = str(out_p)
					break
		if product.is_empty():
			return false
	for link in links:
		if link.from == from and link.to == to and link.product == product:
			return false
	links.append({"from": from, "to": to, "product": product, "transferred": 0})
	_resolve_recipe(to)
	return true

## Whether an auto machine could still take `product` given what is already linked.
func accepts_new_input(id: String, product: String) -> bool:
	var linked := linked_inputs(id)
	if not (product in linked):
		linked.append(product)
	return not candidate_recipes(id, linked).is_empty()

func is_input_linked(id: String, product: String) -> bool:
	for link in links:
		if link.to == id and link.product == product:
			return true
	return false

func remove_link(from: String, to: String, from_port: int = -1, _to_port: int = -1) -> void:
	if from_port >= 0 and machines.has(from):
		var outs: Array = output_products(from)
		if from_port < outs.size():
			var product := str(outs[from_port])
			links = links.filter(func(link: Dictionary) -> bool:
				return not (link.from == from and link.to == to and link.product == product))
			return
	links = links.filter(func(link: Dictionary) -> bool: return not (link.from == from and link.to == to))

func remove_machine(id: String) -> void:
	links = links.filter(func(link: Dictionary) -> bool: return link.from != id and link.to != id)
	machines.erase(id)
	for key in cursors.keys():
		if str(key).begins_with(id + ":") or cursors[key] == id:
			cursors.erase(key)

func advance(seconds: float) -> void:
	accumulator += maxf(seconds, 0.0)
	while accumulator + EPSILON >= STEP:
		accumulator = maxf(0.0, accumulator - STEP)
		_tick()
	if accumulator < EPSILON:
		accumulator = 0.0

func _tick() -> void:
	_transfer()
	for id in machines:
		_process_machine(id, STEP)
	_transfer()
	_spend_points()
	elapsed += STEP

## The active research draws what it still needs from the point store.
func _spend_points() -> void:
	if not can_research(active_research):
		return
	var cost: Dictionary = catalog.researches[active_research].cost
	var progress: Dictionary = research_progress[active_research]
	var done := true
	for tier in cost:
		var missing := int(cost[tier]) - int(progress.get(tier, 0))
		var take := mini(missing, int(research_points.get(tier, 0)))
		if take > 0:
			progress[tier] = int(progress.get(tier, 0)) + take
			research_points[tier] -= take
		if int(progress.get(tier, 0)) < int(cost[tier]):
			done = false
	if done:
		_complete_research(active_research)

func _complete_research(tech_id: String) -> void:
	if tech_id in completed_researches or not catalog.researches.has(tech_id):
		return
	completed_researches.append(tech_id)
	var spec: Dictionary = catalog.researches[tech_id]
	for m_kind in spec.get("unlock_machines", []):
		if not (str(m_kind) in unlocked_machines):
			unlocked_machines.append(str(m_kind))
	for r_id in spec.get("unlock_recipes", []):
		if not (str(r_id) in unlocked_recipes):
			unlocked_recipes.append(str(r_id))

func _start(id: String) -> bool:
	var machine: Dictionary = machines[id]
	if not machine.enabled:
		machine.status = "Durduruldu"
		return false
	var recipe: Dictionary = recipe_for(id)
	var spec: Dictionary = catalog.machines[machine.kind]
	for product in recipe.inputs:
		if int(machine.input.get(product, 0)) < int(recipe.inputs[product]):
			machine.status = "Girdi bekliyor"
			return false
	for product in recipe.outputs:
		if int(machine.output.get(product, 0)) + int(recipe.outputs[product]) > int(spec.output_capacity):
			machine.status = "Çıkış tamponu dolu"
			return false
	for product in recipe.inputs:
		machine.input[product] -= int(recipe.inputs[product])
	machine.running = true
	machine.remaining = float(recipe.work)
	machine.status = "İşleniyor"
	return true

func _process_machine(id: String, delta: float) -> void:
	var machine: Dictionary = machines[id]
	var budget := delta
	while budget > EPSILON:
		if not machine.running and not _start(id):
			return
		var recipe: Dictionary = recipe_for(id)
		var duration := minf(budget, float(machine.remaining) / float(machine.speed))
		machine.remaining = maxf(0.0, float(machine.remaining) - duration * float(machine.speed))
		budget -= duration
		if float(machine.remaining) <= EPSILON:
			for product in recipe.outputs:
				machine.output[product] += int(recipe.outputs[product])
			machine.completed += 1
			machine.running = false
			machine.remaining = 0.0
			for tier in recipe.get("research_points", {}):
				research_points[tier] = int(research_points.get(tier, 0)) + int(recipe.research_points[tier])
			machine.status = "Çevrim tamamlandı"

func _transfer() -> void:
	# K-006: Her üretici çıkışındaki her ürün kendi adil sırasıyla dağıtılır.
	for source in machines:
		for prod_var in output_products(source):
			var product := str(prod_var)
			var targets: Array = []
			for link in links:
				if link.from == source and link.product == product:
					targets.append(link.to)
			targets.sort()
			if targets.is_empty():
				continue
			var key: String = source + ":" + product
			var last_index: int = targets.find(cursors.get(key, ""))
			while int(machines[source].output.get(product, 0)) > 0:
				var moved := false
				for offset in range(1, targets.size() + 1):
					var index := (last_index + offset) % targets.size()
					var target: String = targets[index]
					var spec: Dictionary = catalog.machines[machines[target].kind]
					if not machines[target].input.has(product):
						continue
					if int(machines[target].input[product]) >= int(spec.input_capacity):
						continue
					machines[source].output[product] -= 1
					machines[target].input[product] += 1
					machines[target].received += 1
					for link in links:
						if link.from == source and link.to == target and link.product == product:
							link.transferred += 1
					cursors[key] = target
					last_index = index
					moved = true
					break
				if not moved:
					break

func snapshot() -> Dictionary:
	return {
		"version": 3,
		"machines": machines.duplicate(true),
		"links": links.duplicate(true),
		"cursors": cursors.duplicate(true),
		"unlocked_machines": unlocked_machines.duplicate(),
		"unlocked_recipes": unlocked_recipes.duplicate(),
		"completed_researches": completed_researches.duplicate(),
		"research_progress": research_progress.duplicate(true),
		"research_points": research_points.duplicate(),
		"active_research": active_research,
		"sandbox_mode": sandbox_mode,
		"elapsed": elapsed,
		"next_id": next_id,
		"accumulator": accumulator
	}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 3 or not data.get("machines") is Dictionary or not data.get("links") is Array:
		return false
	for id in data.machines:
		var m: Variant = data.machines[id]
		if not m is Dictionary or not catalog.machines.has(m.get("kind", "")):
			return false
		var kind_str: String = str(m.kind)
		var spec: Dictionary = catalog.machines[kind_str]
		var r_id: String = str(m.get("recipe", spec.recipe))
		if not (r_id in spec.get("recipes", [spec.recipe])) or not catalog.recipes.has(r_id):
			return false
		for field in ["input", "output"]:
			if not m.get(field) is Dictionary:
				return false
		for field in ["speed", "remaining", "completed", "received"]:
			if not (m.get(field) is float or m.get(field) is int) or not is_finite(float(m[field])) or float(m[field]) < 0:
				return false
		if float(m.speed) <= 0 or not m.get("enabled") is bool or not m.get("running") is bool:
			return false
		if not m.get("status") is String:
			return false
		for field in ["completed", "received"]:
			if float(m[field]) != floorf(float(m[field])):
				return false
		var recipe: Dictionary = catalog.recipes[r_id]
		if float(m.remaining) > float(recipe.work):
			return false
		if bool(m.running) != (float(m.remaining) > 0.0):
			return false
		for field in ["input", "output"]:
			var products: Dictionary = recipe.inputs if field == "input" else recipe.outputs
			var cap: int = int(spec[field + "_capacity"])
			if m[field].size() != products.size():
				return false
			for product in products:
				var count: Variant = m[field].get(product)
				if not (count is float or count is int) or not is_finite(float(count)) or float(count) != floorf(float(count)) or float(count) < 0 or float(count) > cap:
					return false
		if m.running:
			for product in recipe.outputs:
				if int(m.output[product]) + int(recipe.outputs[product]) > int(spec.output_capacity):
					return false
		var pos: Variant = m.get("position")
		if not pos is Array or pos.size() != 2:
			return false
		for coord in pos:
			if not (coord is float or coord is int) or not is_finite(float(coord)):
				return false
	var seen := {}
	for link in data.links:
		if not link is Dictionary or not data.machines.has(link.get("from")) or not data.machines.has(link.get("to")):
			return false
		var prod_str: String = str(link.get("product", ""))
		var key: String = "%s:%s:%s" % [str(link.from), str(link.to), prod_str]
		if seen.has(key) or link.from == link.to:
			return false
		seen[key] = true
		var from_m: Dictionary = data.machines[link.from]
		var to_m: Dictionary = data.machines[link.to]
		var from_recipe: Dictionary = catalog.recipes[str(from_m.get("recipe", catalog.machines[from_m.kind].recipe))]
		var to_recipe: Dictionary = catalog.recipes[str(to_m.get("recipe", catalog.machines[to_m.kind].recipe))]
		if not from_recipe.outputs.has(prod_str) or not to_recipe.inputs.has(prod_str):
			return false
		if not (link.get("transferred") is float or link.get("transferred") is int) or float(link.transferred) < 0:
			return false
		if not is_finite(float(link.transferred)) or float(link.transferred) != floorf(float(link.transferred)):
			return false
	if not data.get("cursors") is Dictionary:
		return false
	for key in data.cursors:
		if not key is String or not data.cursors[key] is String:
			return false
	for field in ["elapsed", "accumulator", "next_id"]:
		if not (data.get(field) is float or data.get(field) is int) or not is_finite(float(data[field])) or float(data[field]) < 0:
			return false
	if float(data.accumulator) >= STEP or float(data.next_id) != floorf(float(data.next_id)) or float(data.next_id) < 1:
		return false
	for id in data.machines:
		if not str(id).begins_with("machine_") or int(str(id).trim_prefix("machine_")) >= int(data.next_id):
			return false
	if not data.get("research_progress") is Dictionary or not data.get("completed_researches") is Array:
		return false
	if not data.get("unlocked_machines") is Array or not data.get("unlocked_recipes") is Array:
		return false
	if not data.get("research_points") is Dictionary:
		return false
	for tech_id in data.research_progress:
		if not catalog.researches.has(tech_id) or not data.research_progress[tech_id] is Dictionary:
			return false
		for tier in data.research_progress[tech_id]:
			if not _whole_count(data.research_progress[tech_id][tier]):
				return false
	for tier in data.research_points:
		if not _whole_count(data.research_points[tier]):
			return false
	machines = data.machines.duplicate(true)
	links = data.links.duplicate(true)
	for machine in machines.values():
		machine.completed = int(machine.completed)
		machine.received = int(machine.received)
		machine.recipe = str(machine.get("recipe", catalog.machines[machine.kind].recipe))
		for field in ["input", "output"]:
			for product in machine[field]:
				machine[field][product] = int(machine[field][product])
	for link in links:
		link.transferred = int(link.transferred)
	cursors = data.cursors.duplicate(true)
	unlocked_machines.clear()
	for m_kind in data.unlocked_machines:
		unlocked_machines.append(str(m_kind))
	unlocked_recipes.clear()
	for r_id in data.unlocked_recipes:
		unlocked_recipes.append(str(r_id))
	completed_researches.clear()
	for tech_id in data.completed_researches:
		completed_researches.append(str(tech_id))
	research_progress.clear()
	for tech_id in catalog.researches:
		research_progress[str(tech_id)] = {}
		for tier in data.research_progress.get(tech_id, {}):
			research_progress[str(tech_id)][str(tier)] = int(data.research_progress[tech_id][tier])
	for tier in research_points:
		research_points[tier] = int(data.research_points.get(tier, 0))
	active_research = str(data.get("active_research", "A-01"))
	sandbox_mode = bool(data.get("sandbox_mode", false))
	elapsed = float(data.elapsed)
	accumulator = float(data.accumulator)
	next_id = int(data.next_id)
	return true

func _whole_count(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) == floorf(float(value))
