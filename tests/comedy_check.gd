extends SceneTree

const ComedyFX = preload("res://scripts/comedy_fx.gd")
const FlameBolt = preload("res://scripts/flame_bolt.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	assert(not game.comedy_mode and not game.hud.comedy_button.button_pressed)
	game.set_physics_process(false)
	start_fixture()
	var foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*1.7)
	assert(foe.dead and game.rules.kills==1 and game.rules.headshots==1)
	assert(not game.player.comedy_stains and not has_sprite(ComedyFX.SPLAT))

	return_to_title()
	var button: Button = game.hud.comedy_button
	button.grab_focus()
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	game._unhandled_input(enter)
	assert(game.comedy_mode and button.button_pressed and game.state=="TITLE")
	await capture("comedy-title")
	start_fixture()
	assert(game.player.comedy_stains.visible and game.player.comedy_stains.get_child_count()==2)
	game.menu_action("comedy")
	assert(game.comedy_mode,"The mode can only be toggled from the title screen")
	foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.health==1 and not foe.dead and game.rules.kills==0,"First body hit leaves one point of health, got %s"%foe.health)
	assert(has_sprite(ComedyFX.PELLETS[0]))
	await capture("comedy-pellet")
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.dead and game.rules.kills==1 and game.rules.headshots==0)
	assert(has_sprite(ComedyFX.PELLETS[1]) and has_sprite(ComedyFX.SPLAT))
	for _tick in range(5):await physics_frame
	await capture("comedy-splat")
	foe = stationary(Vector3(18,0,9))
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*1.7)
	assert(foe.dead and game.rules.headshots==1 and has_sprite(ComedyFX.PELLETS[2]))

	game.clear_round()
	foe = stationary(Vector3(18,0,9))
	game.rules.elapsed = 45
	game._physics_process(0)
	assert(game.destroy_active)
	await sync_bodies()
	shoot_at(foe.position+Vector3.UP*.8)
	assert(foe.dead and game.effects.get_children().any(func(fx):return fx is FlameBolt))
	assert(has_sprite(ComedyFX.PELLETS[0]))
	game.player.position = Vector3(18,.05,4)
	var rusher = stationary(Vector3(18,0,-7),true)
	await sync_bodies()
	shoot_at(rusher.position+Vector3.UP*1.7)
	assert(rusher.health==3 and game.player_bullets.size()==1)
	var projectile = game.player_bullets[0]
	assert(projectile.pellet.texture==ComedyFX.PELLETS[1] and projectile.flame and projectile.burning)
	game.update_player_bullets(1.0/60.0)
	assert(is_instance_valid(projectile.pellet))

	return_to_title()
	assert(game.comedy_mode and game.hud.comedy_button.button_pressed and not game.player.comedy_stains.visible)
	game.hud.comedy_button.pressed.emit()
	assert(not game.comedy_mode and not game.hud.comedy_button.button_pressed)
	start_fixture()
	assert(not game.player.comedy_stains.visible and game.effects.get_child_count()==0)
	print("COMEDY_PASS: default off, keyboard toggle, three pellets, unchanged damage, splat, flame and dodge, clean title and restart")
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
