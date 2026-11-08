extends SceneTree

const Progress = preload("res://scripts/achievements.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	check_catalog()
	game = load("res://scenes/main.tscn").instantiate()
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
	for x in [17,19]:
		var target = game.spawn_enemy(Vector3(x,0,12),false)
		target.set_physics_process(false)
	await physics_frame
	await physics_frame
	game.barrel_blast(Vector3(18,1,12),5,game.arena.barrels[0])
	assert(game.achievements.unlocked_badge("barrel") and game.achievements.unlocked_badge("triple"))
	game.rules.elapsed = game.rules.duration
	game.rules.active = false
	var final_foe = game.spawn_enemy(Vector3(16,0,10),false)
	final_foe.take_damage(3,false,true)
	assert(game.rules.kills==4 and game.achievements.combat_kills==3)
	game.finish_run()
	for _frame in range(5):await process_frame
	assert(game.hud.menu.has_node("Badge_first") and game.hud.menu.has_node("Badge_barrel"))
	assert(not game.hud.menu.has_node("Badge_headshot"))
	await capture("achievement-results")
	game.menu_action("menu")
	game.hud.rebuild_menu()
	assert(game.hud.menu.has_node("Badge_first"))
	for id in Progress.BADGES:game.achievements.advance(id,Progress.BADGES[id][2])
	game.hud.rebuild_menu()
	assert(game.hud.menu.get_children().filter(func(n):return str(n.name).begins_with("Badge_")).size()==12)
	await capture("achievement-title")
	var badge = game.hud.menu.get_node("Badge_first")
	badge.gui_input.emit(InputEventMouseMotion.new())
	assert_badge_detail("first")
	await capture("achievement-hover")
	badge.mouse_exited.emit()
	assert(game.hud.badge_detail==null)
	game.touch_mode = true
	game.get_window().content_scale_size = Vector2i(960,540)
	await process_frame
	game.hud.rebuild_menu()
	await capture("achievement-title-touch")
	badge = game.hud.menu.get_node("Badge_headshot")
	badge.pressed.emit()
	assert_badge_detail("headshot")
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
	print("ACHIEVEMENTS_PASS: 12 thresholds, saved progress, real headshot, toast, results, title, badge details and finale exclusion")
	game.queue_free()
	await process_frame
	quit()

func assert_badge_detail(id: String) -> void:
	var detail = game.hud.badge_detail
	assert(is_instance_valid(detail) and detail.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	var labels = detail.get_child(0).get_children()
	for i in range(2):assert(labels[i].text==game.hud.tr(Progress.BADGES[id][i]))

func check_catalog() -> void:
	var progress = Progress.new()
	assert(Progress.BADGES.size()==12)
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
	progress.advance("barrel",1)
	assert(not progress.unlocked_badge("barrel"))
	progress.advance("barrel",2)
	progress.advance("studio",1)
	for i in range(8):progress.increment("wreck")
	assert(unlocks.size()==12 and progress.counts.size()==12)
	progress.advance("first",1)
	assert(unlocks.size()==12,"Achievements are awarded only once")
	var loaded = Progress.new()
	loaded.merge(JSON.parse_string(JSON.stringify(progress.snapshot())))
	assert(loaded.counts==progress.counts and loaded.scores==progress.scores)
	assert(loaded.run_unlocks.is_empty(),"Stored unlocks do not repeat in the next match")

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
