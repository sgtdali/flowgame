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
## Machine items made by a machine factory: product id prefix and recipe id prefix.
const MACHINE_ITEM := "machine_item__"
const MACHINE_RECIPE := "build__"
## Products travel along a link with a length: canvas px per second, and the least room
## between two items on the line (an 8 px item plus a gap). Items sit at whole px.
const LINK_SPEED := 60.0
const LINK_GAP := 10
var catalog: Dictionary
## The bounded map (data/map.json): its rect in canvas px and the ore deposits. A mine stands
## only on a free deposit of its kind, one per deposit, so the deposits are its build limit.
var map_rect := Rect2()
var deposit_size := Vector2()
## deposit id -> {"kind": mine kind, "rect": Rect2 in canvas px}
var deposits: Dictionary = {}
## Trees, bushes and rocky hills on the map, top-left corners in canvas px; only drawn, they block nothing.
var trees := PackedVector2Array()
## Each tree's size: 0 small, 1 normal, 2 large.
var tree_sizes := PackedByteArray()
var bushes := PackedVector2Array()
var hills := PackedVector2Array()
## The river's center line, every ~40 px: [x, y, water half width] in canvas px. Only drawn,
## like the trees.
var river: Array = []
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
var active_research := "MK-01"
var sandbox_mode := false
var elapsed := 0.0
var next_id := 1
var accumulator := 0.0
## kind -> "fixed" (one recipe), "auto" (recipe follows the linked inputs) or
## "choose" (several recipes share the same inputs, so the player picks the product).
var recipe_modes: Dictionary = {}
## product -> count the player carries
var inventory: Dictionary = {}
## machine kind -> machines the player carries but has not placed
var machine_inventory: Dictionary = {}
## Hand crafting, front first: {"type": "machine" or "recipe", "id": kind or recipe id, "remaining": work}
var craft_queue: Array = []
const CRAFT_QUEUE_KINDS := 5
## Work units per second of hand crafting; machines are faster.
var hand_speed := 10.0
## Quick-use bar: HOTBAR_SIZE pinned inventory keys ("machine:<kind>", "product:<id>" or "").
## It shares the inventory's counts; a pinned slot stays put even while its count is zero.
## Research effects of the completed researches, see _bonuses_for().
var _bonus: Dictionary = {}
const HOTBAR_SIZE := 10
var hotbar: Array = []

func _init() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/prototype.json"))
	_load_map()
	_add_machine_recipes()
	hand_speed = float(catalog.get("hand_speed", hand_speed))
	var kit: Dictionary = catalog.get("starting_inventory", {})
	for product in kit.get("products", {}):
		inventory[str(product)] = int(kit.products[product])
	for kind in kit.get("machines", {}):
		machine_inventory[str(kind)] = int(kit.machines[kind])
	hotbar.resize(HOTBAR_SIZE)
	hotbar.fill("")
	for key in carried_keys():
		pin(key)
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
		# The catalog can force a mode: furnaces are chosen by the player although their
		# recipes take different inputs.
		mode = str(catalog.machines[kind].get("recipe_mode", mode))
		recipe_modes[str(kind)] = mode

func _load_map() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	map_rect = Rect2(data.rect[0], data.rect[1], data.rect[2], data.rect[3])
	deposit_size = Vector2(data.deposit_size[0], data.deposit_size[1])
	for d in data.deposits:
		deposits[str(d.id)] = {"kind": str(d.kind), "rect": Rect2(Vector2(d.pos[0], d.pos[1]), deposit_size)}
	for t in data.get("trees", []):
		trees.append(Vector2(t[0], t[1]))
		tree_sizes.append(int(t[2]) if t.size() > 2 else 1)
	for b in data.get("bushes", []):
		bushes.append(Vector2(b[0], b[1]))
	for h in data.get("hills", []):
		hills.append(Vector2(h[0], h[1]))
	river = data.get("river", [])

## Whether this machine kind is built on deposits (the mines).
func uses_deposits(kind: String) -> bool:
	for d in deposits.values():
		if d.kind == kind:
			return true
	return false

## The machine standing on deposit `deposit_id`, or "".
func deposit_owner(deposit_id: String) -> String:
	for id in machines:
		if str(machines[id].get("deposit", "")) == deposit_id:
			return id
	return ""

## Free deposits for `kind`, nearest to `near` (canvas px) first.
func free_deposits(kind: String, near := Vector2.ZERO) -> Array:
	var taken := {}
	for machine in machines.values():
		taken[str(machine.get("deposit", ""))] = true
	var free: Array = []
	for d_id in deposits:
		if deposits[d_id].kind == kind and not taken.has(d_id):
			free.append(d_id)
	free.sort_custom(func(a: String, b: String) -> bool:
		return deposits[a].rect.get_center().distance_squared_to(near) < deposits[b].rect.get_center().distance_squared_to(near))
	return free

## Moves a mine to another free deposit of its kind.
func move_to_deposit(id: String, deposit_id: String) -> bool:
	if not machines.has(id) or not deposits.has(deposit_id) or deposits[deposit_id].kind != machines[id].kind:
		return false
	var owner := deposit_owner(deposit_id)
	if not owner.is_empty() and owner != id:
		return false
	machines[id].deposit = deposit_id
	return true

## Machines that build machines ("builds_machines" in the catalog) get one recipe per
## machine kind: its build cost in, one machine item out. The item is a product of its own
## (MACHINE_ITEM + kind) so it can wait in the output and travel to a depot; taken into the
## inventory it becomes a carried machine. Kinds with a build limit (mines) are left out.
func _add_machine_recipes() -> void:
	var kinds: Array = []
	for kind in catalog.machines:
		if int(catalog.machines[kind].get("build_limit", -1)) < 0:
			kinds.append(str(kind))
	for maker in catalog.machines:
		var spec: Dictionary = catalog.machines[maker]
		if not spec.get("builds_machines", false):
			continue
		var list: Array = []
		for kind: String in kinds:
			var item: String = MACHINE_ITEM + kind
			catalog.products[item] = {"name": str(catalog.machines[kind].name), "tier": 0, "color": str(catalog.machines[kind].get("color", "7fa6c4")), "machine": kind}
			catalog.recipes[MACHINE_RECIPE + kind] = {"name": str(catalog.machines[kind].name), "inputs": catalog.machines[kind].get("build_cost", {}).duplicate(), "outputs": {item: 1}, "work": float(catalog.get("machine_build_work", 50.0)), "builds": kind}
			list.append(MACHINE_RECIPE + kind)
		spec.recipes = list
		spec.recipe = list[0]

## The machine kind a machine item stands for, or "" for an ordinary product.
func machine_of_item(product: String) -> String:
	return product.trim_prefix(MACHINE_ITEM) if product.begins_with(MACHINE_ITEM) else ""

## Moves `count` of `product` into the inventory; machine items become carried machines.
func _receive(product: String, count: int) -> void:
	var kind := machine_of_item(product)
	if kind.is_empty():
		_add_items(product, count)
		return
	for i in range(count):
		_add_machine_item(kind)

func _input_key(recipe_id: String) -> String:
	var keys: Array = catalog.recipes[recipe_id].inputs.keys()
	keys.sort()
	return ",".join(PackedStringArray(keys))

func recipe_mode(kind: String) -> String:
	return str(recipe_modes.get(kind, "fixed"))

## Products fed into a machine: linked in, or put in by hand from the inventory and still
## there. Auto machines pick their recipe from these.
func linked_inputs(id: String) -> Array:
	var products: Array = []
	for link in links:
		if link.to == id and not (link.product in products):
			products.append(link.product)
	if not is_storage(str(machines[id].kind)):
		for product in machines[id].input:
			if int(machines[id].input[product]) > 0 and not (product in products):
				products.append(product)
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
	if is_storage(kind):
		return catalog.products.keys()
	var spec: Dictionary = catalog.machines[kind]
	var products: Array = []
	for r_id in spec.get("recipes", [spec.recipe]):
		for product in catalog.recipes[r_id].inputs:
			if not (product in products):
				products.append(product)
	return products

func product_name(product: String) -> String:
	return "Any input" if product == ANY else str(catalog.products[product].name)

func product_color(product: String) -> Color:
	return Color("7f99aa") if product == ANY else Color(catalog.products[product].color)

func port_type(id: String, product: String) -> int:
	return any_port_type(str(machines[id].kind)) if product == ANY else product_port_type(product)

## Changes whenever a machine's ports change, so the UI knows to rebuild its card.
func port_signature(id: String) -> String:
	return "%s|%s|%s" % [machines[id].recipe, ",".join(PackedStringArray(input_products(id))), ",".join(PackedStringArray(output_products(id)))]

func is_machine_unlocked(kind: String) -> bool:
	return sandbox_mode or kind in unlocked_machines

## How many of this kind may stand at once; -1 means no limit. Mines: one per deposit, also
## in sandbox mode. Research raises the other limits.
func build_limit(kind: String) -> int:
	if uses_deposits(kind):
		var count := 0
		for d in deposits.values():
			if d.kind == kind:
				count += 1
		return count
	if sandbox_mode:
		return -1
	var limit := int(catalog.machines[kind].get("build_limit", -1))
	return limit if limit < 0 else limit + int(bonus("build_limit", kind))

## Research effects ("effects" in a research) summed by "type:kind", or "type:" for the
## ones that apply everywhere: build_limit (count), speed / hand_speed / buffer (share
## added, 0.25 = +25%), storage (flat depot capacity).
func _bonuses_for(techs: Array) -> Dictionary:
	var sums := {}
	for tech_id in techs:
		for effect in catalog.researches.get(str(tech_id), {}).get("effects", []):
			var kinds: Array = effect.get("machines", [""])
			for kind in kinds:
				var key := "%s:%s" % [str(effect.type), str(kind)]
				sums[key] = float(sums.get(key, 0.0)) + float(effect.add)
	return sums

func _refresh_bonuses() -> void:
	_bonus = _bonuses_for(completed_researches)

func bonus(type: String, kind: String = "") -> float:
	return float(_bonus.get("%s:%s" % [type, kind], 0.0))

## Work per second a placed machine really does: its own speed plus research bonuses.
func effective_speed(id: String) -> float:
	var machine: Dictionary = machines[id]
	return float(machine.speed) * (1.0 + bonus("speed", str(machine.kind)))

## A machine's input or output buffer size after research ("input" / "output").
func capacity(kind: String, field: String, saved: Variant = null) -> int:
	var bonuses: Dictionary = _bonus if saved == null else saved
	var base := int(catalog.machines[kind][field + "_capacity"])
	if is_storage(kind):
		return base + int(bonuses.get("storage:", 0.0)) if field == "input" else base
	return int(round(base * (1.0 + float(bonuses.get("buffer:", 0.0)))))

func built_count(kind: String) -> int:
	var count := 0
	for machine in machines.values():
		if machine.kind == kind:
			count += 1
	return count

func can_build(kind: String) -> bool:
	if not catalog.machines.has(kind) or not is_machine_unlocked(kind):
		return false
	var limit := build_limit(kind)
	return limit < 0 or built_count(kind) < limit

## A depot keeps whatever is linked into it and makes nothing.
func is_storage(kind: String) -> bool:
	return bool(catalog.machines[kind].get("storage", false))

func _add_items(product: String, count: int) -> void:
	if count > 0:
		if int(inventory.get(product, 0)) == 0:
			pin("product:" + product)
		inventory[product] = int(inventory.get(product, 0)) + count

## A machine coming into the inventory; like products, a new kind takes a free quick-use slot.
func _add_machine_item(kind: String) -> void:
	if int(machine_inventory.get(kind, 0)) == 0:
		pin("machine:" + kind)
	machine_inventory[kind] = int(machine_inventory.get(kind, 0)) + 1

func _take_items(product: String, count: int) -> void:
	inventory[product] = int(inventory.get(product, 0)) - count
	if int(inventory[product]) <= 0:
		inventory.erase(product)

## How many of `product` the player can put into machine `id` by hand: what they carry,
## up to the free input space. 0 when the machine does not take it. Auto machines take
## anything that still leaves them a recipe; depots take every product.
func can_deposit(id: String, product: String) -> int:
	if not machines.has(id) or not catalog.products.has(product):
		return 0
	var machine: Dictionary = machines[id]
	var kind := str(machine.kind)
	if not is_storage(kind) and not recipe_for(id).inputs.has(product):
		if recipe_mode(kind) != "auto" or not accepts_new_input(id, product):
			return 0
	var space := capacity(kind, "input") - int(machine.input.get(product, 0))
	return clampi(mini(space, int(inventory.get(product, 0))), 0, space)

## Puts up to `count` (-1: as many as fit) of `product` from the inventory into machine
## `id`'s input. An auto machine switches to a recipe that uses it. Returns how many moved.
func deposit(id: String, product: String, count: int = -1) -> int:
	var amount := can_deposit(id, product)
	if count >= 0:
		amount = mini(amount, count)
	if amount <= 0:
		return 0
	var machine: Dictionary = machines[id]
	if not is_storage(str(machine.kind)) and not recipe_for(id).inputs.has(product):
		var wanted := linked_inputs(id)
		wanted.append(product)
		set_recipe(id, str(candidate_recipes(id, wanted)[0]))
	machine.input[product] = int(machine.input.get(product, 0)) + amount
	_take_items(product, amount)
	return amount

## Whether the player carries one of `kind` to place (sandbox mode needs none).
func can_place(kind: String) -> bool:
	return can_build(kind) and (sandbox_mode or int(machine_inventory.get(kind, 0)) > 0)

## Puts a carried machine on the canvas; a mine on `deposit_id` (or the first free deposit).
func place_machine(kind: String, recipe_override: String = "", deposit_id: String = "") -> String:
	if not can_place(kind):
		return ""
	var id := add_machine(kind, recipe_override, deposit_id)
	if not id.is_empty() and not sandbox_mode:
		machine_inventory[kind] = int(machine_inventory[kind]) - 1
		if int(machine_inventory[kind]) <= 0:
			machine_inventory.erase(kind)
	return id

## Takes a machine off the canvas; it and everything in its buffers go to the inventory.
func pick_up_machine(id: String) -> void:
	if not machines.has(id):
		return
	var machine: Dictionary = machines[id]
	for field in ["input", "output"]:
		for product in machine[field]:
			_receive(str(product), int(machine[field][product]))
	_add_machine_item(str(machine.kind))
	remove_machine(id)

## Moves what a machine has made (or what a depot holds) of `product` into the inventory.
func take(id: String, product: String) -> int:
	if not machines.has(id):
		return 0
	var storage := is_storage(str(machines[id].kind))
	var buffer: Dictionary = machines[id].input if storage else machines[id].output
	var count := int(buffer.get(product, 0))
	if count <= 0:
		return 0
	buffer[product] = 0
	_receive(product, count)
	if storage and not is_input_linked(id, product):
		buffer.erase(product)
	return count

func take_all(id: String) -> int:
	if not machines.has(id):
		return 0
	var buffer: Dictionary = machines[id].input if is_storage(str(machines[id].kind)) else machines[id].output
	var total := 0
	for product in buffer.keys():
		total += take(id, str(product))
	return total

## Recipes the player may make by hand: those of machines marked "handcraft".
func handcraft_recipes() -> Array:
	var list: Array = []
	for kind in catalog.machines:
		var spec: Dictionary = catalog.machines[kind]
		if not spec.get("handcraft", false):
			continue
		for r_var in spec.get("recipes", [spec.recipe]):
			if not (str(r_var) in list):
				list.append(str(r_var))
	return list

func craft_inputs(type: String, id: String) -> Dictionary:
	return catalog.machines[id].get("build_cost", {}) if type == "machine" else catalog.recipes[id].inputs

func craft_work(type: String, id: String) -> float:
	return float(catalog.get("machine_build_work", 50.0)) if type == "machine" else float(catalog.recipes[id].work)

func is_craft_unlocked(type: String, id: String) -> bool:
	if type == "machine":
		return is_machine_unlocked(id)
	return is_recipe_unlocked(id) and id in handcraft_recipes()

## Placed, carried and queued machines of `kind`: crafting stops at the build limit.
func machine_total(kind: String) -> int:
	var total := built_count(kind) + int(machine_inventory.get(kind, 0))
	for job in craft_queue:
		if job.type == "machine" and job.id == kind:
			total += 1
	return total

func can_craft(type: String, id: String) -> bool:
	if not is_craft_unlocked(type, id):
		return false
	if type == "machine":
		var limit := build_limit(id)
		if limit >= 0 and machine_total(id) >= limit:
			return false
	if not queue_has_room(type, id):
		return false
	var inputs := craft_inputs(type, id)
	for product in inputs:
		if int(inventory.get(product, 0)) < int(inputs[product]):
			return false
	return true

## The hand queue holds at most CRAFT_QUEUE_KINDS different items; more of an item already
## queued always fits.
func queue_has_room(type: String, id: String) -> bool:
	var groups := craft_queue_groups()
	for group in groups:
		if group.type == type and group.id == id:
			return true
	return groups.size() < CRAFT_QUEUE_KINDS

## The queue as runs of the same item: {type, id, count, first (index of its first job)}.
func craft_queue_groups() -> Array:
	var groups: Array = []
	for i in range(craft_queue.size()):
		var job: Dictionary = craft_queue[i]
		if not groups.is_empty() and groups[-1].type == job.type and groups[-1].id == job.id:
			groups[-1].count += 1
		else:
			groups.append({"type": str(job.type), "id": str(job.id), "count": 1, "first": i})
	return groups

## Materials leave the inventory when the job is queued and come back if it is cancelled.
func enqueue_craft(type: String, id: String) -> bool:
	if not can_craft(type, id):
		return false
	var inputs := craft_inputs(type, id)
	for product in inputs:
		_take_items(str(product), int(inputs[product]))
	# More of a queued item joins its run, so each item stays in one place in the queue.
	var at := craft_queue.size()
	for i in range(craft_queue.size()):
		if craft_queue[i].type == type and craft_queue[i].id == id:
			at = i + 1
	craft_queue.insert(at, {"type": type, "id": id, "remaining": craft_work(type, id)})
	return true

func cancel_craft(index: int) -> void:
	if index < 0 or index >= craft_queue.size():
		return
	var job: Dictionary = craft_queue[index]
	var inputs := craft_inputs(str(job.type), str(job.id))
	for product in inputs:
		_add_items(str(product), int(inputs[product]))
	craft_queue.remove_at(index)

func _craft(delta: float) -> void:
	var budget := delta * hand_speed * (1.0 + bonus("hand_speed"))
	while budget > EPSILON and not craft_queue.is_empty():
		var job: Dictionary = craft_queue[0]
		var used := minf(budget, float(job.remaining))
		job.remaining = float(job.remaining) - used
		budget -= used
		if float(job.remaining) > EPSILON:
			return
		craft_queue.pop_front()
		if job.type == "machine":
			_add_machine_item(str(job.id))
		else:
			var outputs: Dictionary = catalog.recipes[job.id].outputs
			for product in outputs:
				_add_items(str(product), int(outputs[product]))

func is_recipe_unlocked(recipe_id: String) -> bool:
	var builds := str(catalog.recipes.get(recipe_id, {}).get("builds", ""))
	if not builds.is_empty():
		return is_machine_unlocked(builds)
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

func add_machine(kind: String, recipe_override: String = "", deposit_id: String = "") -> String:
	if not catalog.machines.has(kind):
		return ""
	var limit := build_limit(kind)
	if limit >= 0 and built_count(kind) >= limit:
		return ""
	if uses_deposits(kind):
		var free := free_deposits(kind)
		if deposit_id.is_empty() and not free.is_empty():
			deposit_id = free[0]
		if not deposit_id in free:
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
		"received": 0, "status": "Ready", "position": [0.0, 0.0]
	}
	if not deposit_id.is_empty():
		machines[id].deposit = deposit_id
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
		new_inputs[product] = mini(int(machine.input.get(product, 0)), capacity(str(machine.kind), "input"))
	for product in new_recipe.outputs:
		new_outputs[product] = mini(int(machine.output.get(product, 0)), capacity(str(machine.kind), "output"))
	machine.recipe = recipe_id
	machine.running = false
	machine.remaining = 0.0
	machine.input = new_inputs
	machine.output = new_outputs
	machine.status = "Ready" if machine.enabled else "Stopped"
	_drop_links(func(link: Dictionary) -> bool:
		return (link.from == id and not new_recipe.outputs.has(link.product)) \
			or (link.to == id and not new_recipe.inputs.has(link.product)))
	return true

func clear_outputs(id: String) -> void:
	if not machines.has(id):
		return
	for product in machines[id].output:
		machines[id].output[product] = 0

func recipe_for(id: String) -> Dictionary:
	return catalog.recipes[machines[id].recipe]

func input_products(id: String) -> Array:
	# A depot has a port for each product it holds or is fed, plus an open one.
	if is_storage(str(machines[id].kind)):
		return machines[id].input.keys() + [ANY]
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
			var inputs_str := "Raw extraction" if in_parts.is_empty() else " + ".join(in_parts)
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
				"unlock_tech": req_tech,
				"at_limit": m_unlocked and not can_build(str(kind))
			})
	return list

func machine_outputs_summary(kind: String) -> String:
	if not catalog.machines.has(kind):
		return ""
	if is_lab(kind):
		return "Makes research points"
	if kind == "project_hub":
		return "Consumes main project parts"
	if kind == "scrap_disposal":
		return "Melts surplus metal scrap"
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
	return "Makes: " + " · ".join(names) if not names.is_empty() else str(m_spec.get("role", ""))

func product_tooltip(product: String) -> String:
	if not catalog.products.has(product):
		return ""
	var p_name: String = str(catalog.products[product].name)
	var producers := producers_for(product)
	if producers.is_empty():
		if product == "metal_scrap":
			return "Metal Scrap (by-product)\nComes off machining in the Machine Shop.\nThe Smelter recovers it into Steel Ingot."
		return p_name
	var lines: PackedStringArray = ["%s — where is it made?" % p_name]
	for info in producers:
		var lock_tag := "" if info.unlocked else " [Kilitli: %s]" % info.unlock_tech
		lines.append("• %s: %s → %d %s%s" % [info.machine_name, info.inputs_text, info.output_amount, p_name.to_lower(), lock_tag])
	lines.append("(Click a card to build and link a supplier in one click)")
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
	# length 0 hands items over at once; the canvas sets the drawn length, see set_link_length().
	# items: distances of the products on the way from the source, front first.
	links.append({"from": from, "to": to, "product": product, "transferred": 0, "length": 0, "items": []})
	if is_storage(str(machines[to].kind)) and not machines[to].input.has(product):
		machines[to].input[product] = 0
	_resolve_recipe(to)
	return true

## Whether an auto machine could still take `product` given what is already linked.
func accepts_new_input(id: String, product: String) -> bool:
	if is_storage(str(machines[id].kind)):
		return catalog.products.has(product)
	var linked := linked_inputs(id)
	if not (product in linked):
		linked.append(product)
	return not candidate_recipes(id, linked).is_empty()

func is_input_linked(id: String, product: String) -> bool:
	for link in links:
		if link.to == id and link.product == product:
			return true
	return false

func is_output_linked(id: String, product: String) -> bool:
	for link in links:
		if link.from == id and link.product == product:
			return true
	return false

func remove_link(from: String, to: String, from_port: int = -1, _to_port: int = -1) -> void:
	if from_port >= 0 and machines.has(from):
		var outs: Array = output_products(from)
		if from_port < outs.size():
			var product := str(outs[from_port])
			_drop_links(func(link: Dictionary) -> bool:
				return link.from == from and link.to == to and link.product == product)
			_drop_empty_storage_ports(to)
			return
	_drop_links(func(link: Dictionary) -> bool: return link.from == from and link.to == to)
	_drop_empty_storage_ports(to)

## Removes the links `doomed` picks; products still on the way go back to their source.
func _drop_links(doomed: Callable) -> void:
	var kept: Array = []
	for link in links:
		if not doomed.call(link):
			kept.append(link)
			continue
		_return_items(link)
	links = kept

## Puts a link's products on the way back into its source's output, up to the output
## capacity; what does not fit is lost.
func _return_items(link: Dictionary) -> void:
	var source: Dictionary = machines.get(link.from, {})
	if not link.items.is_empty() and source.has("output") and source.output.has(link.product):
		var room := capacity(str(source.kind), "output") - int(source.output[link.product])
		source.output[link.product] += clampi(link.items.size(), 0, maxi(room, 0))
	link.items.clear()

## The drawn length of a link in canvas px. Products on the way keep their share of the route.
func set_link_length(from: String, to: String, product: String, length: float) -> void:
	var new_length := maxi(roundi(length), 0)
	for link in links:
		if link.from != from or link.to != to or link.product != product or int(link.length) == new_length:
			continue
		if new_length == 0:
			_return_items(link)
		elif int(link.length) > 0:
			var scale := float(new_length) / float(link.length)
			var ahead := new_length + LINK_GAP
			for i in link.items.size():
				# Rescaled, but never closer than LINK_GAP to the item in front.
				ahead = mini(roundi(link.items[i] * scale), ahead - LINK_GAP)
				link.items[i] = maxi(ahead, 0)
		link.length = new_length

## A depot forgets products it no longer holds or receives.
func _drop_empty_storage_ports(id: String) -> void:
	if not machines.has(id) or not is_storage(str(machines[id].kind)):
		return
	for product in machines[id].input.keys():
		if int(machines[id].input[product]) == 0 and not is_input_linked(id, str(product)):
			machines[id].input.erase(product)

func remove_machine(id: String) -> void:
	var fed: Array = []
	for link in links:
		if link.from == id:
			fed.append(link.to)
	_drop_links(func(link: Dictionary) -> bool: return link.from == id or link.to == id)
	machines.erase(id)
	for target in fed:
		_drop_empty_storage_ports(target)
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
	_move_links(STEP)
	_transfer()
	for id in machines:
		if not is_storage(str(machines[id].kind)):
			_process_machine(id, STEP)
	_transfer()
	_spend_points()
	_craft(STEP)
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
	_refresh_bonuses()

func _start(id: String) -> bool:
	var machine: Dictionary = machines[id]
	if not machine.enabled:
		machine.status = "Stopped"
		return false
	var recipe: Dictionary = recipe_for(id)
	var spec: Dictionary = catalog.machines[machine.kind]
	for product in recipe.inputs:
		if int(machine.input.get(product, 0)) < int(recipe.inputs[product]):
			machine.status = "Waiting for input"
			return false
	for product in recipe.outputs:
		if int(machine.output.get(product, 0)) + int(recipe.outputs[product]) > capacity(str(machine.kind), "output"):
			machine.status = "Output buffer full"
			return false
	for product in recipe.inputs:
		machine.input[product] -= int(recipe.inputs[product])
	machine.running = true
	machine.remaining = float(recipe.work)
	machine.status = "Working"
	return true

func _process_machine(id: String, delta: float) -> void:
	var machine: Dictionary = machines[id]
	var budget := delta
	while budget > EPSILON:
		if not machine.running and not _start(id):
			return
		var recipe: Dictionary = recipe_for(id)
		var speed := effective_speed(id)
		var duration := minf(budget, float(machine.remaining) / speed)
		machine.remaining = maxf(0.0, float(machine.remaining) - duration * speed)
		budget -= duration
		if float(machine.remaining) <= EPSILON:
			for product in recipe.outputs:
				machine.output[product] += int(recipe.outputs[product])
			machine.completed += 1
			machine.running = false
			machine.remaining = 0.0
			for tier in recipe.get("research_points", {}):
				research_points[tier] = int(research_points.get(tier, 0)) + int(recipe.research_points[tier])
			machine.status = "Cycle complete"

## Moves the products along the links. The front one waits at the end until the target has
## room; the others queue behind it, LINK_GAP apart.
func _move_links(delta: float) -> void:
	var step := roundi(LINK_SPEED * delta)
	for link in links:
		if link.items.is_empty():
			continue
		var length := int(link.length)
		var target: Dictionary = machines[link.to]
		while not link.items.is_empty() and int(link.items[0]) >= length \
				and target.input.has(link.product) \
				and int(target.input[link.product]) < capacity(str(target.kind), "input"):
			link.items.pop_front()
			_deliver(link)
		var ahead := length + LINK_GAP
		for i in link.items.size():
			ahead = mini(int(link.items[i]) + step, ahead - LINK_GAP)
			link.items[i] = mini(ahead, length)
			ahead = int(link.items[i])

func _deliver(link: Dictionary) -> void:
	var target: Dictionary = machines[link.to]
	target.input[link.product] += 1
	target.received += 1
	link.transferred += 1

func _transfer() -> void:
	# K-006: Her üretici çıkışındaki her ürün kendi adil sırasıyla dağıtılır.
	for source in machines:
		for prod_var in output_products(source):
			var product := str(prod_var)
			var targets: Array = []
			var by_target := {}
			for link in links:
				if link.from == source and link.product == product:
					targets.append(link.to)
					by_target[link.to] = link
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
					if not machines[target].input.has(product):
						continue
					var link: Dictionary = by_target[target]
					if int(link.length) > 0:
						# A line with a length takes the product on when its entry is clear.
						if not link.items.is_empty() and int(link.items.back()) < LINK_GAP:
							continue
						machines[source].output[product] -= 1
						link.items.append(0)
					else:
						if int(machines[target].input[product]) >= capacity(str(machines[target].kind), "input"):
							continue
						machines[source].output[product] -= 1
						_deliver(link)
					cursors[key] = target
					last_index = index
					moved = true
					break
				if not moved:
					break

## Everything the player carries, machines first, in catalog order.
func carried_keys() -> Array:
	var keys: Array = []
	for kind in catalog.machines:
		if int(machine_inventory.get(kind, 0)) > 0:
			keys.append("machine:" + str(kind))
	for product in catalog.products:
		if int(inventory.get(product, 0)) > 0:
			keys.append("product:" + str(product))
	return keys

func carried_count(key: String) -> int:
	var parts := key.split(":")
	if parts.size() != 2:
		return 0
	return int((machine_inventory if parts[0] == "machine" else inventory).get(parts[1], 0))

func _valid_inventory_key(key: String) -> bool:
	var parts := key.split(":")
	return parts.size() == 2 and ((parts[0] == "machine" and catalog.machines.has(parts[1])) or (parts[0] == "product" and catalog.products.has(parts[1])))

## Pins `key` to `slot` (first empty slot when -1). A key lives in one slot only: moving it
## from another slot swaps it with whatever was in the target. Returns false when there is
## no room or the key is unknown.
func pin(key: String, slot: int = -1) -> bool:
	if not _valid_inventory_key(key) or slot >= HOTBAR_SIZE:
		return false
	var from := hotbar.find(key)
	if slot < 0:
		if from >= 0:
			return true
		slot = hotbar.find("")
		if slot < 0:
			return false
	if from >= 0:
		hotbar[from] = hotbar[slot]
	hotbar[slot] = key
	return true

func unpin(slot: int) -> void:
	if slot >= 0 and slot < HOTBAR_SIZE:
		hotbar[slot] = ""

## After loading: every mine keeps its saved deposit when that is valid, others (saves from
## before the map) take the free deposit nearest to their position. Other machines have none.
func _settle_deposits() -> bool:
	var ids := machines.keys()
	ids.sort()
	var taken := {}
	var homeless: Array = []
	for id in ids:
		var machine: Dictionary = machines[id]
		var d_id := str(machine.get("deposit", ""))
		machine.erase("deposit")
		if not uses_deposits(str(machine.kind)):
			continue
		if deposits.has(d_id) and deposits[d_id].kind == machine.kind and not taken.has(d_id):
			machine.deposit = d_id
			taken[d_id] = true
		else:
			homeless.append(id)
	for id in homeless:
		var machine: Dictionary = machines[id]
		var free := free_deposits(str(machine.kind), Vector2(machine.position[0], machine.position[1]))
		if free.is_empty():
			return false
		machine.deposit = free[0]
	return true

func snapshot() -> Dictionary:
	return {
		"version": 4,
		"inventory": inventory.duplicate(),
		"machine_inventory": machine_inventory.duplicate(),
		"craft_queue": craft_queue.duplicate(true),
		"hotbar": hotbar.duplicate(),
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
	var version: Variant = data.get("version")
	if not (version is int or version is float) or not (int(version) in [3, 4]) or float(version) != floorf(float(version)):
		return false
	if not data.get("machines") is Dictionary or not data.get("links") is Array:
		return false
	# Version 3 saves predate the inventory; they keep the starting kit.
	if int(version) == 4:
		for field in ["inventory", "machine_inventory"]:
			if not data.get(field) is Dictionary:
				return false
			for key in data[field]:
				if not _whole_count(data[field][key]):
					return false
		for key in data.inventory:
			if not catalog.products.has(key):
				return false
		for key in data.machine_inventory:
			if not catalog.machines.has(key):
				return false
		if not data.get("craft_queue") is Array:
			return false
		for job in data.craft_queue:
			if not job is Dictionary or not (job.get("type") in ["machine", "recipe"]):
				return false
			if not (catalog.machines if job.type == "machine" else catalog.recipes).has(str(job.get("id", ""))):
				return false
			if not (job.get("remaining") is float or job.get("remaining") is int) or not is_finite(float(job.remaining)) or float(job.remaining) < 0:
				return false
		# Saves made before the quick-use bar have no "hotbar"; they keep the current one.
		if data.has("hotbar"):
			if not data.hotbar is Array or data.hotbar.size() != HOTBAR_SIZE:
				return false
			for key in data.hotbar:
				if not key is String or (not key.is_empty() and not _valid_inventory_key(key)):
					return false
	# Buffers may hold what the saved research allowed.
	var saved_bonus := _bonuses_for(data.completed_researches if data.get("completed_researches") is Array else [])
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
			# A depot's inputs are whatever products it holds.
			if field == "input" and is_storage(kind_str):
				products = m.input
			var cap: int = capacity(kind_str, field, saved_bonus)
			if m[field].size() != products.size():
				return false
			for product in products:
				if not catalog.products.has(product):
					return false
				var count: Variant = m[field].get(product)
				if not (count is float or count is int) or not is_finite(float(count)) or float(count) != floorf(float(count)) or float(count) < 0 or float(count) > cap:
					return false
		if m.running:
			for product in recipe.outputs:
				if int(m.output[product]) + int(recipe.outputs[product]) > capacity(kind_str, "output", saved_bonus):
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
		var to_has: bool = to_m.input.has(prod_str) if is_storage(str(to_m.kind)) else to_recipe.inputs.has(prod_str)
		if not from_recipe.outputs.has(prod_str) or not to_has:
			return false
		if not (link.get("transferred") is float or link.get("transferred") is int) or float(link.transferred) < 0:
			return false
		if not is_finite(float(link.transferred)) or float(link.transferred) != floorf(float(link.transferred)):
			return false
		# Older saves have no length and nothing on the way.
		var length: Variant = link.get("length", 0)
		if not _whole_count(length) or not link.get("items", []) is Array:
			return false
		for at in link.get("items", []):
			if not _whole_count(at) or float(at) > float(length):
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
	if not _settle_deposits():
		return false
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
		link.length = int(link.get("length", 0))
		var items: Array = []
		for at in link.get("items", []):
			items.append(int(at))
		link.items = items
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
	_refresh_bonuses()
	research_progress.clear()
	for tech_id in catalog.researches:
		research_progress[str(tech_id)] = {}
		for tier in data.research_progress.get(tech_id, {}):
			research_progress[str(tech_id)][str(tier)] = int(data.research_progress[tech_id][tier])
	for tier in research_points:
		research_points[tier] = int(data.research_points.get(tier, 0))
	if int(version) == 4:
		inventory.clear()
		for key in data.inventory:
			if int(data.inventory[key]) > 0:
				inventory[str(key)] = int(data.inventory[key])
		machine_inventory.clear()
		for key in data.machine_inventory:
			if int(data.machine_inventory[key]) > 0:
				machine_inventory[str(key)] = int(data.machine_inventory[key])
		craft_queue.clear()
		for job in data.craft_queue:
			craft_queue.append({"type": str(job.type), "id": str(job.id), "remaining": float(job.remaining)})
		if data.has("hotbar"):
			hotbar = data.hotbar.duplicate()
	active_research = str(data.get("active_research", "MK-01"))
	sandbox_mode = bool(data.get("sandbox_mode", false))
	elapsed = float(data.elapsed)
	accumulator = float(data.accumulator)
	next_id = int(data.next_id)
	return true

func _whole_count(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) == floorf(float(value))
