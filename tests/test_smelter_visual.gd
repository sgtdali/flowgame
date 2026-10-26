extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Control = load("res://app/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in range(4):
		await process_frame
	# The game starts on an empty canvas; the old starting network gives these cards.
	main.build_sample_network()
	for i in range(2):
		await process_frame
	main.paused = true
	main.sim.unlock_all()
	main.graph.zoom = 1.0
	main.graph.scroll_offset = Vector2(0, -10)
	var id := "machine_3"
	var card: GraphNode = main.cards[id].node
	assert(card.get_input_port_count() == 1 and card.get_output_port_count() == 1)
	assert(card.get_input_port_type(0) == main.sim.product_port_type("iron_ore"))
	
	assert(card.get_output_port_type(0) == main.sim.product_port_type("pig_iron"))
	# One port row each side spans the 256px artwork: ports at its vertical centre.
	var top: float = card.get_node("PortRow_0").position.y
	assert(absf(card.get_input_port_position(0).y - (128 + top)) < 0.6)
	
	assert(absf(card.get_output_port_position(0).y - (128 + top)) < 0.6)
	for recipe in ["copper_ingot", "insulator", "pig_iron"]:
		main._change_machine_recipe(id, recipe)
		await process_frame
		await process_frame
		card = main.cards[id].node
		assert(card.get_input_port_count() == main.sim.input_products(id).size())
		assert(card.get_output_port_type(0) == main.sim.product_port_type(main.sim.output_product(id)))
		assert(card.rate_label.text == ("15/min" if recipe == "insulator" else "40/min"))
	main._select_card(id)
	main.graph.zoom = 1.0
	main.graph.scroll_offset = Vector2(0, -10)
	var machine: Dictionary = main.sim.machines[id]
	machine.input["iron_ore"] = 8
	machine.input["coal"] = 4
	main.paused = false
	main.sim.advance(0.01)
	main._refresh()
	var frame: int = card.animation_frame
	await create_timer(0.25).timeout
	assert(card.animation_frame != frame and card.animation_active)
	main._toggle_pause()
	main._refresh()
	frame = card.animation_frame
	await create_timer(0.25).timeout
	assert(card.animation_frame == frame and not card.animation_active)
	main._toggle_speed()
	main._refresh()
	assert(is_equal_approx(card.animation_scale, 4.0))
	main._toggle_speed()
	card.pause_btn.pressed.emit()
	assert(not machine.enabled)
	main.sim.advance(5.0)
	main._refresh()
	assert(not card.animation_active)
	card.pause_btn.pressed.emit()
	machine.running = false
	machine.remaining = 0.0
	machine.output["pig_iron"] = 12
	var saved_links: Array = main.sim.links.duplicate(true)
	main.sim.links.clear()
	main.sim.advance(0.1)
	main._refresh()
	assert(not card.animation_active and card.output_gauges["pig_iron"].count == 12)
	machine.output["pig_iron"] = 0
	main.sim.links = saved_links
	main.paused = false
	main.sim.advance(0.01)
	main._refresh()
	await create_timer(0.15).timeout
	main._select_card(id)
	main.graph.zoom = 0.9
	main.graph.scroll_offset = Vector2(-10, -10)
	for i in range(3):await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/smelter-a-in-game.png")
	print("SMELTER_SKIN_OK: three recipes, live rates, input/output port counts, port alignment, animation, pause, speed, toggle, blocked output")
	quit()
