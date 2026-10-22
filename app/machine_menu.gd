extends PopupMenu
## Card context menu: recipe screen, stop/run, speed, empty output, delete. The same popup also
## lists the producers of an input product when a card's "+" is pressed.

signal recipe_screen_requested(id: String)
signal toggle_requested(id: String)
signal speed_requested(id: String)
signal clear_outputs_requested(id: String)
signal research_requested()
signal delete_requested(id: String)
signal supplier_selected(target_id: String, product: String, kind: String, recipe_id: String)

enum { TOGGLE = 1000, SPEED, CLEAR, RESEARCH, DELETE, RECIPE }

var target_id := ""
var target_product := ""
var _choices: Array = []

func _ready() -> void:
	id_pressed.connect(_on_id_pressed)
	add_theme_font_size_override("font_size", 13)

## `at` is in viewport coordinates (like Control.global_position).
func _open(at: Vector2) -> void:
	var host := get_parent().get_viewport()
	position = Vector2i(at) if host.gui_embed_subwindows else Vector2i(at) + host.get_window().position
	reset_size()
	popup()

## Context menu for one machine card.
func show_machine(sim: RefCounted, id: String, at: Vector2) -> void:
	clear()
	target_id = id
	target_product = ""
	_choices.clear()
	var machine: Dictionary = sim.machines[id]
	var spec: Dictionary = sim.catalog.machines[machine.kind]
	add_separator(str(spec.name))
	if machine.kind == "lab":
		add_item("Araştırma hedefi seç", RESEARCH)
		add_separator()
	elif sim.recipe_mode(str(machine.kind)) == "choose":
		add_item("Ne üretilsin?", RECIPE)
		add_separator()
	add_item("Durdur" if machine.enabled else "Çalıştır", TOGGLE)
	add_item("Hız: %d → %d iş/sn" % [int(machine.speed), 40 if float(machine.speed) == 20.0 else 20], SPEED)
	if not sim.output_products(id).is_empty():
		add_item("Çıkışı boşalt", CLEAR)
	add_separator()
	add_item("Sil", DELETE)
	_open(at)

## Producers that can feed `product` into `id`; locked ones are listed but disabled.
func show_suppliers(sim: RefCounted, id: String, product: String, at: Vector2) -> void:
	clear()
	target_id = id
	target_product = product
	_choices.clear()
	var products := [product]
	if product == sim.ANY:
		# An open input lists producers for everything the machine could still take.
		products = sim.recipe_input_union(str(sim.machines[id].kind)).filter(func(p: String) -> bool:
			return sim.accepts_new_input(id, p) and not sim.is_input_linked(id, p))
	add_separator("Üretici kur" if product == sim.ANY else "%s üreticisi kur" % sim.product_name(product))
	for p in products:
		for info in sim.producers_for(str(p)):
			var index := item_count
			var label := str(info.machine_name)
			if products.size() > 1:
				label = "%s → %s" % [info.machine_name, sim.product_name(str(p))]
			add_item(label if info.unlocked else "%s (%s)" % [label, info.unlock_tech], _choices.size())
			set_item_tooltip(index, "%s · %s" % [info.recipe_name, info.inputs_text])
			set_item_disabled(index, not info.unlocked)
			info["product"] = str(p)
			_choices.append(info)
	_open(at)

func _on_id_pressed(item_id: int) -> void:
	match item_id:
		TOGGLE: toggle_requested.emit(target_id)
		SPEED: speed_requested.emit(target_id)
		CLEAR: clear_outputs_requested.emit(target_id)
		RESEARCH: research_requested.emit()
		DELETE: delete_requested.emit(target_id)
		RECIPE: recipe_screen_requested.emit(target_id)
		_:
			if item_id < _choices.size():
				var info: Dictionary = _choices[item_id]
				supplier_selected.emit(target_id, str(info.product), str(info.kind), str(info.recipe))
