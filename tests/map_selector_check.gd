extends SceneTree

const YardSession = preload("res://data/sessions/score_attack.tres")
const ParkSession = preload("res://data/sessions/amusement_park.tres")
const FerrySession = preload("res://data/sessions/last_ferry.tres")
const StudioSession = preload("res://data/sessions/night_studio.tres")
const SandgateSession = preload("res://data/sessions/sandgate.tres")
const OfficeSession = preload("res://data/sessions/bb_office.tres")
const HogwartsSession = preload("res://data/sessions/hogwarts.tres")
const CARDS = ["MapYard","MapPark","MapFerry","MapStudio","MapSandgate","MapOffice","MapRainMarket","MapBaggage","MapSnowline"]
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	game.qa_mode = true
	game.achievements.scores.clear()
	game.hud.rebuild_menu()
	assert(game.title_frame_ready and game.nav_ready and game.session==YardSession)
	assert(game.hud.fire_button.text=="FIRE")
	assert(game.hud.map_grid.get_child_count()==11)
	assert(game.hud.menu.get_children().filter(func(node):return node is Button).size()==3)
	assert(not game.hud.menu.get_node("comedy").button_pressed)
	assert(not game.hud.menu.get_node("roach").button_pressed)
	var selected = game.hud.map_grid.get_node("MapYard/Selected")
	assert(selected.get_theme_stylebox("panel").border_width_left==4)
	assert_grid()
	assert_card_records([0,0,0,0,0,0,0,0,0])
	game.achievements.merge({"scores":{"score":13,"score_amusement_park_v1":7,
		"score_last_ferry_v1":5,"score_night_studio_v1":9,"score_night_studio_v2":123,"score_sandgate_v1":6,"score_bb_office_v1":8}})
	game.hud.rebuild_menu()
	assert_card_records([13,7,5,123,6,8,0,0,0])
	if DisplayServer.get_name()!="headless":await capture("map-medals-title")
	var old_frame = game.hud.title_frame
	var park_card = game.hud.map_grid.get_node("MapPark")
	assert(park_card.text.is_empty() and not park_card.accessibility_name.is_empty())
	park_card.grab_focus()
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	assert(game.switching_session and game.hud.fire_button.disabled)
	assert(is_zero_approx(game.hud.fire_progress.value))
	assert(game.hud.map_grid.has_node("MapPark/Selected") and not game.hud.map_grid.has_node("MapYard/Selected"))
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
	assert(game.hud.map_grid.get_node("MapPark/Selected"))
	assert(game.hud.map_grid.get_node("MapPark").has_focus())
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
	var ferry_card = game.hud.map_grid.get_node("MapFerry")
	assert(ferry_card.text.is_empty() and not ferry_card.accessibility_name.is_empty())
	ferry_card.grab_focus()
	game._unhandled_input(enter)
	await wait_for_switch()
	assert(game.nav_ready and game.session==FerrySession and game.title_session_id=="last_ferry")
	assert(game.hud.map_grid.get_node("MapFerry/Selected") and game.hud.map_grid.get_node("MapFerry").has_focus())
	assert(game.world_environment.environment==game.arena.environment_override)
	game.load_session_record(records)
	assert(game.best==5)
	if DisplayServer.get_name()!="headless":await capture("ferry-title")
	var studio_card = game.hud.map_grid.get_node("MapStudio")
	assert(studio_card.text.is_empty() and not studio_card.accessibility_name.is_empty())
	studio_card.grab_focus()
	game._unhandled_input(enter)
	assert(game.hud.map_grid.has_node("MapStudio/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	assert(game.nav_ready and game.session==StudioSession and game.title_session_id=="night_studio")
	assert(game.hud.map_grid.get_node("MapStudio").has_focus() and not game.hud.fire_button.disabled)
	game.load_session_record(records)
	assert(game.best==9)
	if DisplayServer.get_name()!="headless":await capture("studio-title-selector")
	var sandgate_card = game.hud.map_grid.get_node("MapSandgate")
	sandgate_card.grab_focus()
	game._unhandled_input(enter)
	assert(game.hud.map_grid.has_node("MapSandgate/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	assert(game.session==SandgateSession and game.nav_ready and game.title_frame_ready)
	assert(not game.rules.mission and game.score_record_key()=="score_sandgate_v1" and game.best==6)
	assert(game.hud.map_grid.get_node("MapSandgate").has_focus() and not game.hud.fire_button.disabled)
	if DisplayServer.get_name()!="headless":await capture("sandgate-title-selector")
	var office_card = game.hud.map_grid.get_node("MapOffice")
	office_card.grab_focus()
	game._unhandled_input(enter)
	assert(game.hud.map_grid.has_node("MapOffice/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	assert(game.session==OfficeSession and game.nav_ready and game.best==8)
	assert(game.score_record_key()=="score_bb_office_v1" and game.hud.map_grid.get_node("MapOffice").has_focus())
	if DisplayServer.get_name()!="headless":await capture("bb-office-title-selector")

	await game.select_session(YardSession)
	assert(game.nav_ready and game.world_environment.environment==game.daylight_environment)
	assert(game.title_session_id=="score_attack" and game.hud.map_grid.get_node("MapYard/Selected"))
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
	assert(game.hud.map_grid.has_node("MapPark/Selected"))
	await wait_for_switch()
	assert(game.session==YardSession and game.arena==yard)
	assert(game.nav_ready and game.title_frame_ready and game.hud.title_frame==old_frame)
	assert(game.hud.map_grid.has_node("MapYard/Selected") and not game.hud.map_grid.has_node("MapPark/Selected"))
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
	assert(game.hud.map_grid.get_node("MapPark/Selected"))
	assert_card_records([13,17,5,123,6,8,0,0,0])
	game.start_run()
	game.begin_running()
	game.rules.kills = 99
	game.pause_run()
	game.set_physics_process(false)
	game.touch_mode = true
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(844,390)
	await process_frame
	TranslationServer.set_locale("zh")
	game.hud.rebuild_menu()
	if DisplayServer.get_name()!="headless":await capture("pause-home-touch")
	var language = game.hud.menu.get_node("language")
	assert(language.text=="Language: Chinese")
	var cjk: Font = game.hud.font.fallbacks[0]
	for character in "返回首页语言：英文":
		assert(cjk.has_char(character.unicode_at(0)))
	click(language.get_global_rect().get_center())
	assert(TranslationServer.get_locale()=="en")
	game.hud.rebuild_menu()
	language = game.hud.menu.get_node("language")
	assert(language.text=="语言：英文")
	if DisplayServer.get_name()!="headless":await capture("pause-home-touch-english")
	click(language.get_global_rect().get_center())
	assert(TranslationServer.get_locale()=="zh")
	game.hud.rebuild_menu()
	var home = game.hud.menu.get_node("menu")
	assert(home.text=="返回首页")
	assert(home.get_rect().position.x>game.hud.menu.get_node("retry").get_rect().end.x)
	assert(game.hud.get_rect().encloses(home.get_rect()))
	click(home.get_global_rect().get_center())
	assert(game.state=="TITLE" and game.session==ParkSession)
	assert(not game.rules.active and not game.player.enabled)
	assert(game.enemies.get_child_count()==0 and game.effects.get_child_count()==0)
	game.hud.rebuild_menu()
	assert_card_records([13,17,5,123,6,8,0,0,0])
	assert_grid()
	var office_touch = game.hud.map_grid.get_node("MapOffice")
	click(office_touch.get_global_rect().get_center())
	assert(game.hud.map_grid.has_node("MapOffice/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	assert(game.session==OfficeSession and game.nav_ready and not game.hud.fire_button.disabled)
	if DisplayServer.get_name()!="headless":await capture("bb-office-title-touch")
	click(game.hud.fire_button.get_global_rect().get_center())
	# Native QA can exercise the touch layout, but has no browser touch bridge.
	game.touch_mode = false
	game.set_physics_process(true)
	for _frame in range(900):
		if game.state=="RUNNING":break
		await process_frame
	assert(game.state=="RUNNING" and game.session==OfficeSession)
	game.pause_run()
	game.menu_action("menu")
	game.hud.rebuild_menu()
	await process_frame
	var scroller: ScrollContainer = game.hud.map_scroll
	var secret: Button = game.hud.map_grid.get_node("MapHogwarts")
	assert(not scroller.get_global_rect().intersects(secret.get_global_rect()))
	for _step in range(6):
		var wheel := InputEventMouseButton.new()
		wheel.position = scroller.get_global_rect().get_center()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.factor = 1.0
		root.push_input(wheel,true)
		wheel.pressed = false
		root.push_input(wheel,true)
		await process_frame
	assert(scroller.get_global_rect().encloses(secret.get_global_rect().grow(-1.0)))
	var palm: Button = game.hud.map_grid.get_node("MapPalmHouse")
	assert(scroller.get_global_rect().encloses(palm.get_global_rect().grow(-1.0)))
	assert(palm.position.y==secret.position.y and palm.position.x>secret.get_rect().end.x)
	click(secret.get_global_rect().get_center())
	assert(game.hud.map_grid.has_node("MapHogwarts/Selected") and game.hud.fire_button.disabled)
	await wait_for_switch()
	await process_frame
	assert(game.session==HogwartsSession and game.nav_ready and game.score_record_key()=="score_hogwarts_v1")
	secret = game.hud.map_grid.get_node("MapHogwarts")
	assert(game.hud.map_scroll.get_global_rect().has_point(secret.get_global_rect().get_center()))
	assert(not game.hud.fire_button.disabled)
	click(game.hud.fire_button.get_global_rect().get_center())
	for _frame in range(900):
		if game.state=="RUNNING":break
		await process_frame
	assert(game.state=="RUNNING" and game.session==HogwartsSession)
	print("MAP_SELECTOR_PASS: nine visible cards, wheel reveals Hogwarts and Palm House, staged selection, focus, rollback, records, and FIRE")
	game.pause_run()
	game.menu_action("menu")
	game.set_physics_process(false)
	game.music.stop()
	await process_frame
	await process_frame
	if DisplayServer.get_name()=="headless":
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	game.queue_free()
	await process_frame
	quit()

func assert_grid() -> void:
	var fire: Rect2 = game.hud.fire_button.get_global_rect()
	var grid: Array[Rect2] = []
	for card in CARDS:
		var rect: Rect2 = game.hud.map_grid.get_node(card).get_global_rect()
		assert(game.hud.get_rect().encloses(rect) and rect.position.x>fire.end.x)
		grid.append(rect)
	for row in range(3):
		for column in range(3):
			var rect = grid[row*3+column]
			assert(rect.position.x==grid[column].position.x)
			assert(rect.position.y==grid[row*3].position.y)
			if column>0:assert(rect.position.x>grid[row*3+column-1].end.x)
			if row>0:assert(rect.position.y>grid[(row-1)*3+column].end.y)
	assert(is_equal_approx(fire.end.y,grid[-1].end.y),"FIRE and the last visible row share a baseline")
	var secret = game.hud.map_grid.get_node("MapHogwarts")
	assert(not game.hud.map_scroll.get_global_rect().intersects(secret.get_global_rect()))

func assert_card_records(expected: Array) -> void:
	for i in range(CARDS.size()):
		var card = game.hud.map_grid.get_node(CARDS[i])
		var panel = card.get_node("Record")
		assert(panel.find_child("Score",true,false).text==str(expected[i]))
		assert(panel.mouse_filter==Control.MOUSE_FILTER_IGNORE)
		assert(panel.scale==Vector2.ONE*.5)
		assert(is_equal_approx(panel.position.x+panel.size.x*panel.scale.x,card.size.x-8))

func click(center: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion,true)
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
