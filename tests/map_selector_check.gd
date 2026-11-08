extends SceneTree

const YardSession = preload("res://data/sessions/score_attack.tres")
const ParkSession = preload("res://data/sessions/amusement_park.tres")
const FerrySession = preload("res://data/sessions/last_ferry.tres")
const StudioSession = preload("res://data/sessions/night_studio.tres")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	game.qa_mode = true
	game.achievements.scores.clear()
	game.hud.rebuild_menu()
	assert(game.title_frame_ready and game.nav_ready and game.session==YardSession)
	assert(game.hud.fire_button.text=="FIRE")
	assert(game.hud.menu.get_children().filter(func(node):return node is Button).size()==7)
	assert(not game.hud.menu.get_node("comedy").button_pressed)
	assert(not game.hud.menu.get_node("roach").button_pressed)
	var selected = game.hud.menu.get_node("MapYard/Selected")
	assert(selected.get_theme_stylebox("panel").border_width_left==4)
	var fire: Rect2 = game.hud.fire_button.get_rect()
	var yard_rect: Rect2 = game.hud.menu.get_node("MapYard").get_rect()
	var park_rect: Rect2 = game.hud.menu.get_node("MapPark").get_rect()
	var ferry_rect: Rect2 = game.hud.menu.get_node("MapFerry").get_rect()
	var last_card: Rect2 = game.hud.menu.get_node("MapStudio").get_rect()
	assert(yard_rect.position.x==ferry_rect.position.x and park_rect.position.x==last_card.position.x)
	assert(yard_rect.position.y==park_rect.position.y and ferry_rect.position.y==last_card.position.y)
	assert(yard_rect.end.x<park_rect.position.x and yard_rect.end.y<ferry_rect.position.y)
	assert(is_equal_approx(fire.end.y,last_card.end.y),"FIRE and the last map share a baseline")
	assert_card_records([0,0,0,0])
	game.achievements.merge({"scores":{"score":13,"score_amusement_park_v1":7,
		"score_last_ferry_v1":5,"score_night_studio_v1":9,"score_night_studio_v2":123}})
	game.hud.rebuild_menu()
	assert_card_records([13,7,5,123])
	if DisplayServer.get_name()!="headless":await capture("map-medals-title")
	var old_frame = game.hud.title_frame
	var park_card = game.hud.menu.get_node("MapPark")
	assert(park_card.text.is_empty() and not park_card.accessibility_name.is_empty())
	park_card.grab_focus()
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	assert(game.switching_session and game.hud.fire_button.disabled)
	assert(is_zero_approx(game.hud.fire_progress.value))
	assert(game.hud.menu.has_node("MapPark/Selected") and not game.hud.menu.has_node("MapYard/Selected"))
	assert(game.session==YardSession and game.hud.title_frame==old_frame)
	game.menu_action("play")
	assert(game.state=="TITLE")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/local/map-switch-highlight.png")
	var stages = await wait_for_switch()
	assert(stages.size()>=4,"Map loading must yield between visible stages")
	assert(game.session==ParkSession and game.nav_ready and game.title_frame_ready)
	assert(not game.hud.fire_button.disabled and game.hud.fire_progress==null)
	assert(game.title_session_id=="amusement_park")
	assert(game.hud.menu.get_node("MapPark/Selected"))
	assert(game.hud.menu.get_node("MapPark").has_focus())
	assert(game.world_environment.environment==game.arena.environment_override)
	if DisplayServer.get_name()!="headless":
		assert(game.hud.title_frame!=old_frame and game.hud.title_frame.get_image().get_size()==Vector2i(root.get_texture().get_size()))
		await capture("park-title")
	var park_frame = game.hud.title_frame

	var records = ConfigFile.new()
	records.set_value("score","best",13)
	records.set_value("score_amusement_park_v1","best",7)
	records.set_value("score_last_ferry_v1","best",5)
	records.set_value("score_night_studio_v1","best",9)
	game.load_session_record(records)
	assert(game.best==7)
	var ferry_card = game.hud.menu.get_node("MapFerry")
	assert(ferry_card.text.is_empty() and not ferry_card.accessibility_name.is_empty())
	ferry_card.grab_focus()
	game._unhandled_input(enter)
	await wait_for_switch()
	assert(game.nav_ready and game.session==FerrySession and game.title_session_id=="last_ferry")
	assert(game.hud.menu.get_node("MapFerry/Selected") and game.hud.menu.get_node("MapFerry").has_focus())
	assert(game.world_environment.environment==game.arena.environment_override)
	game.load_session_record(records)
	assert(game.best==5)
	if DisplayServer.get_name()!="headless":await capture("ferry-title")
	var studio_card = game.hud.menu.get_node("MapStudio")
	assert(studio_card.text.is_empty() and not studio_card.accessibility_name.is_empty())
	studio_card.grab_focus()
	game._unhandled_input(enter)
	assert(game.hud.menu.has_node("MapStudio/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	assert(game.nav_ready and game.session==StudioSession and game.title_session_id=="night_studio")
	assert(game.hud.menu.get_node("MapStudio").has_focus() and not game.hud.fire_button.disabled)
	game.load_session_record(records)
	assert(game.best==9)
	if DisplayServer.get_name()!="headless":await capture("studio-title-selector")
	await game.select_session(YardSession)
	assert(game.nav_ready and game.world_environment.environment==game.daylight_environment)
	assert(game.title_session_id=="score_attack" and game.hud.menu.get_node("MapYard/Selected"))
	game.load_session_record(records)
	assert(game.best==13)
	if DisplayServer.get_name()!="headless":await capture("yard-title-selector")

	# Try a real, packed map whose start cannot reach its baked navigation.
	var bad_map = ParkSession.map_scene.instantiate()
	bad_map.get_node(bad_map.start_path).position.y += 100
	var bad_scene = PackedScene.new()
	assert(bad_scene.pack(bad_map)==OK)
	bad_map.free()
	var invalid = ParkSession.duplicate()
	invalid.map_scene = bad_scene
	var yard = game.arena
	old_frame = game.hud.title_frame
	game.select_session(invalid)
	assert(game.hud.menu.has_node("MapPark/Selected"))
	await wait_for_switch()
	assert(game.session==YardSession and game.arena==yard)
	assert(game.nav_ready and game.title_frame_ready and game.hud.title_frame==old_frame)
	assert(game.hud.menu.has_node("MapYard/Selected") and not game.hud.menu.has_node("MapPark/Selected"))
	assert(game.best==13 and not game.hud.fire_button.disabled)
	await game.select_session(ParkSession)
	assert(game.nav_ready and game.title_session_id=="amusement_park")
	assert(game.hud.title_frame==park_frame,"Revisiting a map reuses its opening texture at the same size")

	game.start_run()
	game.begin_running()
	game.rules.kills = 17
	game.finish_run()
	game.menu_action("menu")
	assert(game.state=="TITLE" and game.session==ParkSession)
	game.hud.rebuild_menu()
	assert(game.hud.menu.get_node("MapPark/Selected"))
	assert_card_records([13,17,5,123])
	game.start_run()
	game.begin_running()
	game.rules.kills = 99
	game.pause_run()
	game.set_physics_process(false)
	game.touch_mode = true
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(844,390)
	await process_frame
	game.hud.rebuild_menu()
	if DisplayServer.get_name()!="headless":await capture("pause-home-touch")
	var home = game.hud.menu.get_node("menu")
	assert(home.text==game.hud.tr("HOME"))
	assert(home.get_rect().position.x>game.hud.menu.get_node("retry").get_rect().end.x)
	assert(game.hud.get_rect().encloses(home.get_rect()))
	click(home.get_global_rect().get_center())
	assert(game.state=="TITLE" and game.session==ParkSession)
	assert(not game.rules.active and not game.player.enabled)
	assert(game.enemies.get_child_count()==0 and game.effects.get_child_count()==0)
	game.hud.rebuild_menu()
	assert_card_records([13,17,5,123])
	print("MAP_SELECTOR_PASS: staged selection, focus, rollback, individual records and return home from results or pause")
	await process_frame
	await process_frame
	if DisplayServer.get_name()=="headless":
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	quit()

func assert_card_records(expected: Array) -> void:
	var names = ["MapYard","MapPark","MapFerry","MapStudio"]
	for i in range(names.size()):
		var card = game.hud.menu.get_node(names[i])
		var panel = card.get_node("Record")
		assert(panel.find_child("Score",true,false).text==str(expected[i]))
		assert(panel.mouse_filter==Control.MOUSE_FILTER_IGNORE)
		assert(panel.position.x>0 and panel.get_rect().end.x<card.size.x)

func click(center: Vector2) -> void:
	for pressed in [true,false]:
		var event = InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)

func wait_for_switch() -> Array[float]:
	var stages: Array[float] = []
	for _frame in range(900):
		if not game.switching_session:return stages
		var progress: float = game.map_switch_progress
		if stages.is_empty() or progress>stages[-1]:stages.append(progress)
		assert(game.hud.fire_button.disabled)
		await process_frame
	assert(false,"Map selection did not settle")
	return stages

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
