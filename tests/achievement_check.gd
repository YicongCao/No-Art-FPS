extends SceneTree

const Progress = preload("res://scripts/achievements.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	check_catalog()
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	game.achievements.counts.clear()
	game.achievements.scores.clear()
	game.best = 0
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.player.position = Vector3(18,.05,14)
	var foe = game.spawn_enemy(Vector3(18,0,9),false)
	foe.set_physics_process(false)
	await physics_frame
	await physics_frame
	var direction = game.player.camera.global_position.direction_to(foe.position+Vector3.UP*1.7)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.shoot()
	assert(foe.dead and game.rules.headshots==1 and game.achievements.counts.headshot==1)
	assert(game.achievements.run_unlocks==["first"] and game.hud.badge_toasts==["first"])
	for _tick in range(15):await physics_frame
	await capture("achievement-toast")
	for i in range(2):
		var target = game.spawn_enemy(Vector3(17+2*i,0,12),false)
		target.set_physics_process(false)
		await physics_frame
		await physics_frame
		game.barrel_blast(Vector3(18,1,12),5,game.arena.barrels[i])
		assert(target.dead and game.achievements.unlocked_badge("barrel"))
		assert(game.achievements.unlocked_badge("triple")==(i==1))
	game.rules.elapsed = game.rules.duration
	game.rules.active = false
	var final_foe = game.spawn_enemy(Vector3(16,0,10),false)
	final_foe.take_damage(3,false,true)
	assert(game.rules.kills==4 and game.achievements.combat_kills==3)
	game.finish_run()
	for _frame in range(5):await process_frame
	var results = game.hud.menu.get_node("ResultBadges")
	assert(not results.find_child("Badge_headshot",true,false))
	for id in ["first","barrel","triple"]:
		var row = results.find_child("Badge_"+id,true,false)
		assert(row.get_child(0).texture==Progress.BADGES[id][3])
		assert_badge_copy(id,row.get_child(1))
	await capture("achievement-results")
	game.touch_mode = true
	var window = game.get_window()
	var desktop_size = window.size
	window.content_scale_size = Vector2i(960,540)
	window.size = Vector2i(844,390)
	var locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	for _frame in range(3):await process_frame
	game.hud.rebuild_menu()
	for _frame in range(3):await process_frame
	results = game.hud.menu.get_node("ResultBadges")
	assert(not results.get_v_scroll_bar().visible)
	assert_badge_copy("barrel",results.find_child("Badge_barrel",true,false).get_child(1))
	await capture("achievement-results-touch")
	var saved_unlocks: Array[String] = game.achievements.run_unlocks.duplicate()
	for id in Progress.BADGES:
		if id not in saved_unlocks:game.achievements.run_unlocks.append(id)
	game.hud.rebuild_menu()
	for _frame in range(5):await process_frame
	results = game.hud.menu.get_node("ResultBadges")
	assert(results.get_v_scroll_bar().visible and results.get_child(0).get_child_count()==15)
	assert(results.get_rect().end.y<game.hud.menu.get_node("retry").position.y)
	game.achievements.run_unlocks = saved_unlocks
	game.touch_mode = false
	window.content_scale_size = Vector2i(1440,810)
	window.size = desktop_size
	TranslationServer.set_locale(locale)
	for _frame in range(3):await process_frame
	game.menu_action("menu")
	game.hud.rebuild_menu()
	assert(game.hud.menu.has_node("Badge_first"))
	for id in Progress.BADGES:game.achievements.advance(id,Progress.BADGES[id][2])
	game.hud.rebuild_menu()
	assert(game.hud.menu.get_children().filter(func(n):return str(n.name).begins_with("Badge_")).size()==15)
	await capture("achievement-title")
	var badge = game.hud.menu.get_node("Badge_first")
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(3,4)
	badge.gui_input.emit(motion)
	assert_badge_detail("first")
	var detail: Control = game.hud.badge_detail
	assert(detail.position.distance_to(badge.position+motion.position)<24)
	var first_position = detail.position
	motion.position += Vector2(15,16)
	badge.gui_input.emit(motion)
	assert(game.hud.badge_detail==detail and detail.position.is_equal_approx(first_position+Vector2(15,16)))
	await capture("achievement-hover")
	var gutters: Vector4 = game.hud.title_gutters()
	badge.position = game.hud.size-Vector2(gutters.y,gutters.z)-badge.size
	badge.gui_input.emit(motion)
	assert(detail.get_rect().end.x<badge.position.x+motion.position.x)
	assert(detail.get_rect().end.y<badge.position.y+motion.position.y)
	badge.mouse_exited.emit()
	assert(game.hud.badge_detail==null)
	game.touch_mode = true
	game.get_window().content_scale_size = Vector2i(960,540)
	await process_frame
	game.hud.rebuild_menu()
	await capture("achievement-title-touch")
	game.hud.menu.get_node("Badge_no_art").pressed.emit()
	assert_badge_detail("no_art")
	game.hud.menu.get_node("Badge_no_art").pressed.emit()
	badge = game.hud.menu.get_node("Badge_headshot")
	badge.pressed.emit()
	assert_badge_detail("headshot")
	for _frame in range(3):await process_frame
	await capture("achievement-tap")
	assert(game.hud.badge_detail.size.y<160)
	var outside = InputEventScreenTouch.new()
	outside.position = game.hud.size*.5
	outside.pressed = true
	game.hud._input(outside)
	assert(game.hud.badge_detail==null)
	game.touch_mode = false
	if DisplayServer.get_name()=="headless":
		var deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<deadline:await process_frame
	print("ACHIEVEMENTS_PASS: 15 badges, legacy progress, collection, real headshot, toast, results, title, badge details and finale exclusion")
	game.queue_free()
	await process_frame
	quit()

func assert_badge_detail(id: String) -> void:
	var detail = game.hud.badge_detail
	assert(is_instance_valid(detail) and detail.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert_badge_copy(id,detail.get_child(0))

func assert_badge_copy(id: String, column: Control) -> void:
	var labels = column.get_children()
	for i in range(2):assert(labels[i].text==game.hud.tr(Progress.BADGES[id][i]))

func check_catalog() -> void:
	var progress = Progress.new()
	assert(Progress.BADGES.size()==15)
	var unlocks: Array[String] = []
	progress.unlocked.connect(func(id):unlocks.append(id))
	progress.merge({"achievements":{"headshot":10,"missing":45},"scores":{"score":17,"score_last_ferry_v1":31}})
	progress.merge({"achievements":{"headshot":2,"yard":-4},"scores":{"score":5,"junk":99}})
	assert(progress.counts=={"headshot":10} and progress.scores=={"score":17,"score_last_ferry_v1":31})
	for i in range(12):
		progress.combat_kill("score_attack",i<2,mini(3,i+1),false,0,"comedy" if i<10 else "")
	assert(progress.unlocked_badge("first") and progress.unlocked_badge("headshot"))
	assert(progress.unlocked_badge("triple") and progress.unlocked_badge("yard") and progress.unlocked_badge("water"))
	progress.finish_round(false,0)
	progress.finish_round(true,1)
	assert(not progress.unlocked_badge("clean"))
	progress.finish_round(true,0)
	progress.start_round()
	assert(progress.run_unlocks.is_empty() and progress.combat_kills==0)
	for i in range(10):progress.combat_kill("amusement_park",false,1,i>=5,0,"roach")
	assert(progress.unlocked_badge("park") and progress.unlocked_badge("slipper"))
	progress.start_round()
	for height in [0.05,2.2,2.64,2.64,2.64]:
		progress.combat_kill("last_ferry",false,1,false,height,"")
	assert(progress.unlocked_badge("ferry") and progress.counts.ferry==3)
	progress.advance("barrel",0)
	assert(not progress.unlocked_badge("barrel"))
	progress.advance("barrel",1)
	assert(progress.unlocked_badge("barrel"))
	var legacy = Progress.new()
	legacy.merge({"achievements":{"barrel":2,"water":10,"no_art":1}})
	assert(legacy.counts.barrel==1 and legacy.unlocked_badge("barrel"))
	assert(legacy.counts.poop==10 and not legacy.unlocked_badge("no_art"))
	assert(legacy.run_unlocks.is_empty())
	progress.advance("studio",1)
	for i in range(8):progress.increment("wreck")
	assert(unlocks.size()==12 and not progress.unlocked_badge("no_art"))
	progress.advance("first",1)
	assert(unlocks.size()==12,"Achievements are awarded only once")
	progress.advance("no_art",1)
	assert(not progress.unlocked_badge("no_art"))
	for i in range(4):
		progress.combat_kill("sandgate",false,1,false,0,"comedy")
	assert(progress.counts.poop==14 and not progress.unlocked_badge("poop"))
	progress.start_round()
	progress.combat_kill("sandgate",false,1,false,0,"comedy")
	assert(progress.run_unlocks==["poop"] and not progress.unlocked_badge("no_art"))
	progress.increment("grenade",14)
	assert(not progress.unlocked_badge("grenade") and not progress.unlocked_badge("no_art"))
	progress.increment("grenade")
	assert(progress.run_unlocks==["poop","grenade","no_art"] and unlocks.size()==15)
	var loaded = Progress.new()
	var snapshot = JSON.parse_string(JSON.stringify(progress.snapshot()))
	snapshot.achievements.erase("no_art")
	loaded.merge(snapshot)
	assert(loaded.counts==progress.counts and loaded.scores==progress.scores)
	assert(loaded.run_unlocks.is_empty(),"Stored unlocks do not repeat in the next match")

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
