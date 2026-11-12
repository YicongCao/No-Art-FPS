extends SceneTree

const ComedyFX = preload("res://scripts/comedy_fx.gd")
const FlameBolt = preload("res://scripts/flame_bolt.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var roach = "--roach" in OS.get_cmdline_user_args()
	var mode = "roach" if roach else "comedy"
	var alternative = "comedy" if roach else "roach"
	var heads = ComedyFX.ROACH_ART if roach else ComedyFX.POOP_ART
	var knockout = ComedyFX.ROACH_KNOCKOUT if roach else ComedyFX.SPLAT
	var weapon = "mop_launcher" if roach else "water_blaster"
	var bolt = "SlipperBolt" if roach else "WaterBolt"
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	assert(game.comedy_mode.is_empty() and not game.hud.comedy_buttons[mode].button_pressed)
	assert(not game.hud.comedy_buttons[alternative].button_pressed)
	game.set_physics_process(false)
	start_fixture()
	var foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*1.7)
	assert(foe.dead and game.rules.kills==1 and game.rules.headshots==1)
	assert(game.player.weapon_mode.is_empty() and not foe.comedy_head and not has_sprite(knockout))

	return_to_title()
	var button: Button = game.hud.comedy_buttons[mode]
	var other: Button = game.hud.comedy_buttons[alternative]
	other.pressed.emit()
	assert(game.comedy_mode==alternative and other.button_pressed and not button.button_pressed)
	button.grab_focus()
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	assert(game.comedy_mode==mode and button.button_pressed and not other.button_pressed and game.state=="TITLE")
	await capture(mode+"-title")
	start_fixture()
	assert(game.player.weapon_mode==mode and game.player.weapon_models[mode].visible)
	assert(game.player.weapon_models[mode].scene_file_path.ends_with(weapon+".glb"))
	assert(game.shot_sound_key()==("slipper_shot" if roach else "water_shot"))
	game.menu_action(alternative)
	assert(game.comedy_mode==mode,"The mode can only be toggled from the title screen")
	foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	assert(foe.comedy_head.texture==heads[0] and not foe.visual.find_child("Helmet",true,false).visible)
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.health==1 and not foe.dead and game.rules.kills==0,"First body hit leaves one point of health, got %s"%foe.health)
	assert(game.effects.has_node(bolt))
	await capture(mode+"-pellet")
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.dead and game.rules.kills==1 and game.rules.headshots==0)
	assert(game.effects.has_node(bolt) and has_sprite(knockout))
	var voice = game.audio_voices[(game.audio_index-1)%game.audio_voices.size()]
	assert(voice.stream==game.sounds["roach_buzz" if roach else "comedy_plop"])
	for _tick in range(5):await physics_frame
	await capture(mode+"-knockout")
	foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*1.7)
	assert(foe.dead and game.rules.headshots==1)

	game.clear_round()
	foe = stationary(Vector3(18,0,9))
	game.rules.elapsed = 45
	game._physics_process(0)
	assert(game.destroy_active)
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.dead and game.effects.get_children().any(func(fx):return fx is FlameBolt))
	assert(game.effects.has_node(bolt))
	game.player.position = Vector3(18,.05,4)
	var rusher = stationary(Vector3(18,0,-7),true)
	await sync_bodies()
	assert(rusher.comedy_head.texture==heads[1])
	shoot_at(rusher.position+Vector3.UP*1.7)
	assert(rusher.health==3 and game.player_bullets.size()==1)
	var projectile = game.player_bullets[0]
	assert(projectile.toy_round.name==bolt and projectile.flame and projectile.burning)
	game.update_player_bullets(1.0/60.0)
	assert(is_instance_valid(projectile.toy_round))

	return_to_title()
	assert(game.comedy_mode==mode and game.hud.comedy_buttons[mode].button_pressed and game.player.weapon_mode.is_empty())
	game.hud.comedy_buttons[alternative].pressed.emit()
	assert(game.comedy_mode==alternative and not game.hud.comedy_buttons[mode].button_pressed)
	start_fixture()
	assert(game.player.weapon_mode==alternative and not game.player.weapon_models[mode].visible)
	return_to_title()
	game.hud.comedy_buttons[alternative].pressed.emit()
	assert(game.comedy_mode.is_empty() and not game.hud.comedy_buttons[alternative].button_pressed)
	start_fixture()
	assert(game.player.weapon_mode.is_empty() and game.effects.get_child_count()==0)
	print("COMEDY_PASS ",mode,": exclusive modes, toy model, enemy heads, projectile, damage, sound, flame and clean restart")
	game.queue_free()
	await process_frame
	if DisplayServer.get_name()=="headless":
		var deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<deadline:await process_frame
	quit()

func start_fixture() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.hud.go_time = 0
	game.player.enabled = false
	game.invulnerable = 999
	game.player.position = Vector3(18,.05,14)

func return_to_title() -> void:
	game.state = "RESULTS"
	game.menu_action("menu")
	game.hud.rebuild_menu()

func stationary(at: Vector3, fast: bool = false) -> Node3D:
	var foe = game.spawn_enemy(at,fast)
	foe.set_physics_process(false)
	return foe

func has_sprite(texture: Texture2D) -> bool:
	return game.effects.get_children().any(func(fx):return fx is Sprite3D and fx.texture==texture)

func sync_bodies() -> void:
	await physics_frame
	await physics_frame

func shoot_at(target: Vector3) -> void:
	var direction = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.fire_time = 0
	game.shoot()

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+label+".png")
