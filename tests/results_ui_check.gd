extends Node

var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Results UI check needs rendered frames")
	Engine.max_fps = 60
	TranslationServer.set_locale("zh")
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.spawn_time = 999
	game.best = 6
	game.rules.kills = 18
	game.rules.elapsed = 59.99
	game._physics_process(.02)
	await get_tree().create_timer(.65).timeout
	game._physics_process(game.rules.finale_duration)
	await results_ready()
	assert(game.new_record and game.rules.kills==18 and game.best==18)
	assert_results_buttons()
	assert_record_label("新纪录")
	await capture("finale-results")
	game.rules.kills = 123
	game.best = 123
	game.achievements.advance("first",1)
	game.hud.rebuild_menu()
	await capture("results-three-digits")
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(.15).timeout
	assert(game.hud.menu.has_node("ResultBadges"))
	assert_record_label("新纪录")
	await capture("finale-results-small")
	TranslationServer.set_locale("en")
	game.hud.rebuild_menu()
	assert_record_label("NEW RECORD")
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
	game.rules.kills = game.best
	game.finish_run()
	await results_ready()
	assert_results_buttons()
	assert_no_record()
	click("retry")
	assert(game.state=="LOADING" and game.hud.results_frame==null and game.frozen_process_modes.is_empty())
	await running_ready()
	assert(game.rules.kills==0 and game.ammo==20 and not game.finale_active)
	for building in game.arena.structures:assert(not building.collapsed)
	game.finish_run()
	await results_ready()
	assert_no_record()
	await check_mission_record()
	game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("RESULTS_UI_CHECK_PASS: localized score and mission records, no label for ties or losses, badge layout, actual title and retry clicks")
	get_tree().quit()

func results_ready() -> void:
	for _frame in range(12):await get_tree().process_frame
	assert(game.state=="RESULTS" and game.hud.results_frame!=null and game.hud.menu.visible)

func running_ready() -> void:
	for _frame in range(500):
		if game.state=="RUNNING":break
		await get_tree().process_frame
	assert(game.state=="RUNNING")

func assert_record_label(text: String) -> void:
	var menu: Control = game.hud.menu
	var record := menu.get_node_or_null("NewRecord") as Label
	assert(record and record.is_visible_in_tree() and record.text==text)
	var font: Font = record.get_theme_font("font")
	for glyph in text:assert(font.has_char(glyph.unicode_at(0)))
	var area := record.get_global_rect()
	assert(is_equal_approx(area.get_center().x,menu.get_global_rect().get_center().x))
	for child in menu.get_children():
		if child==record:continue
		assert(not area.intersects(child.get_global_rect()),"New record must not overlap result controls")

func assert_no_record() -> void:
	assert(not game.new_record and not game.hud.menu.has_node("NewRecord"))

func check_mission_record() -> void:
	game.menu_action("menu")
	await game.select_session(load("res://data/sessions/defuse.tres"))
	assert(game.rules.mission)
	game.start_run()
	game.begin_running()
	game.best_mission = 40.0
	game.rules.elapsed = 25.0
	for id in game.rules.objective_ids:assert(game.rules.request_defuse(id))
	game.settle_rules()
	await results_ready()
	assert(game.best_mission==25.0 and game.new_record)
	assert_record_label("NEW RECORD")
	await capture("results-mission-record")
	click("retry")
	await running_ready()
	game.rules.report_death()
	game.settle_rules()
	await results_ready()
	assert_no_record()

func assert_results_buttons() -> void:
	var buttons = game.hud.menu.get_children().filter(func(node):return node is Button)
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
	var output := OS.get_environment("RESULTS_CAPTURE_DIR")
	if output.is_empty():output = "res://artifacts/local"
	assert(DirAccess.make_dir_recursive_absolute(output)==OK)
	assert(get_viewport().get_texture().get_image().save_png(output.path_join(filename+".png"))==OK)
