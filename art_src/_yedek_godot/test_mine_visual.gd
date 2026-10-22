extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Control = load("res://app/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in range(4):
		await process_frame
	var card: GraphNode = main.cards["machine_1"].node
	assert(card.get_output_port_count() == 1)
	assert(card.get_output_port_type(0) == main.sim.product_port_type("iron_ore"))
	main._select_card("machine_1")
	main.graph.zoom = 1.0
	main.graph.scroll_offset = Vector2(-20, -10)
	var start_frame: int = card.animation_frame
	await create_timer(0.25).timeout
	assert(card.animation_frame != start_frame, "Working mine must animate")
	main._toggle_pause()
	main._refresh()
	var paused_frame: int = card.animation_frame
	await create_timer(0.25).timeout
	assert(card.animation_frame == paused_frame, "Global pause must freeze mine")
	main._toggle_speed()
	main._refresh()
	assert(is_equal_approx(card.animation_scale, 4.0))
	main._toggle_speed()
	main._refresh()
	# Button must drive the existing simulation signal, not only its icon.
	card.pause_btn.pressed.emit()
	assert(not main.sim.machines["machine_1"].enabled)
	main.sim.advance(3.0)
	main._refresh()
	assert(not card.animation_active)
	card.pause_btn.pressed.emit()
	assert(main.sim.machines["machine_1"].enabled)
	# Exercise real full-output blocking with no consumer to drain it.
	var saved_links: Array = main.sim.links.duplicate(true)
	main.sim.links.clear()
	var machine: Dictionary = main.sim.machines["machine_1"]
	machine.running = false
	machine.remaining = 0.0
	machine.output["iron_ore"] = 12
	main.sim.advance(0.1)
	main._refresh()
	assert(not card.animation_active and card.stock_label.text == "12/12")
	machine.output["iron_ore"] = 0
	main.sim.links = saved_links
	main.paused = false
	main.pause_button.text = "Duraklat"
	main.sim.advance(0.01)
	main._refresh()
	await create_timer(0.15).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/iron-mine-b-in-game.png")
	print("MINE_SKIN_OK: animation, global pause, speed, machine toggle, blocked output, real output port")
	print("MINE_PORT_POSITION: ", card.get_output_port_position(0), " CARD_SIZE: ",card.size)
	quit()
