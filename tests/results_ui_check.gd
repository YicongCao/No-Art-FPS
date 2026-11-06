extends Node

var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Results UI check needs rendered frames")
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.spawn_time = 999
	game.best = 6
	game.rules.kills = 18
	game.rules.elapsed = 58.99
	game._physics_process(.02)
	await get_tree().create_timer(.65).timeout
	game._physics_process(.99)
	await results_ready()
	assert(game.new_record and game.rules.kills==26 and game.best==26)
	assert_results_buttons()
	await capture("finale-results")
	game.rules.kills = 123
	game.best = 999
	game.new_record = false
	await capture("results-three-digits")
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(.15).timeout
	await capture("finale-results-small")
	click("menu")
	assert(game.state=="TITLE" and game.hud.results_frame==null and game.frozen_process_modes.is_empty())
	assert(not game.finale_active)
	for prop in game.arena.finale_props:assert(prop.visible)
	await get_tree().process_frame
	await capture("results-return-title")
	# Load again and click the other real result button, including its icon hit area.
	game.request_run()
	await running_ready()
	game.player.enabled = false
	game.rules.kills = 10
	game.finish_run()
	await results_ready()
	assert_results_buttons()
	click("retry")
	assert(game.state=="LOADING" and game.hud.results_frame==null and game.frozen_process_modes.is_empty())
	await running_ready()
	assert(game.rules.kills==0 and game.ammo==20 and not game.finale_active)
	for building in game.arena.structures:assert(not building.collapsed)
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("RESULTS_UI_CHECK_PASS: two imagegen icon buttons, new/best scores, three digits, 960x540, actual title/retry clicks, captured frame reset, loading and full restoration")
	get_tree().quit()

func results_ready() -> void:
	for _frame in range(12):await get_tree().process_frame
	assert(game.state=="RESULTS" and game.hud.results_frame!=null and game.hud.menu.visible)

func running_ready() -> void:
	for _frame in range(500):
		if game.state=="RUNNING":break
		await get_tree().process_frame
	assert(game.state=="RUNNING")

func assert_results_buttons() -> void:
	var buttons = game.hud.menu.get_children()
	assert(buttons.size()==2)
	for button in buttons:
		assert(button is Button and button.text.is_empty() and button.tooltip_text.length()>0)
		assert(button.get_node("Icon").texture.resource_path.begins_with("res://assets/ui/results/"))
		assert(button.get_node("Icon").mouse_filter==Control.MOUSE_FILTER_IGNORE)

func click(action: String) -> void:
	var button = game.hud.menu.get_node(action)
	var center = button.get_global_rect().get_center()
	var motion = InputEventMouseMotion.new()
	motion.position = center
	get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event = InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)

func capture(filename: String) -> void:
	game.hud.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
