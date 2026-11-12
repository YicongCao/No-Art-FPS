extends SceneTree

# Renders the toy actors in the yard: rifleman and rusher, walking and knife poses,
# the rifle at the hip and aimed, then the water blaster and mop launcher.
# Run windowed: godot --path . --script tests/toy_actor_capture.gd
const OUT = "res://docs/art/toy/actors/"
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440,810)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.hud.go_time = 0
	game.invulnerable = 999
	game.set_physics_process(false)
	var player = game.player
	player.enabled = false
	player.position = Vector3(18,.05,14)
	var rifleman = stationary(Vector3(17.2,0,10.6),false)
	var rusher = stationary(Vector3(19.3,0,10.9),true)
	await physics_frame
	await physics_frame
	for foe in [rifleman,rusher]:
		var eye = player.global_position
		foe.look_at(Vector3(eye.x,foe.global_position.y,eye.z),Vector3.UP)
		foe.rotate_y(-.5 if foe==rifleman else .45)
	look(player,Vector3(18.2,1.1,10.7))
	await capture("pair")
	# Readability views use the same actors and game renderer at measured distances.
	for foe in [rifleman,rusher]:foe.position.z -= 16.0
	player.gun.hide()
	var scout = Camera3D.new()
	root.add_child(scout)
	scout.fov = player.camera.fov
	scout.cull_mask = player.camera.cull_mask
	for distance in [15,25]:
		scout.global_position = Vector3(18.2,1.65,-5.3+distance)
		scout.look_at(Vector3(18.2,1.1,-5.3))
		scout.current = true
		await capture("readability-"+str(distance)+"m")
	scout.queue_free()
	player.camera.current = true
	player.gun.show()
	for foe in [rifleman,rusher]:foe.position.z += 16.0
	for i in range(rifleman.limbs.size()):
		if rifleman.limbs[i].name!="RightArm":rifleman.limbs[i].rotation.x = .5*(1 if i%2==0 else -1)
	rifleman.rotation.y += 1.1
	rusher.knife_arm.rotation.x = -2.35
	await capture("walk-pose")
	rusher.knife_arm.rotation.x = 0
	rifleman.rotation.y -= 1.1
	look(player,Vector3(15,3.2,6))
	await capture("rifle-hip")
	player.enabled = true
	player.set_aim_requested(true)
	player.aim_requested = true
	for _frame in range(40):await process_frame
	await capture("rifle-aim")
	player.set_aim_requested(false)
	player.aim_requested = false
	for _frame in range(30):await process_frame
	for mode in ["comedy","roach"]:
		player.set_weapon_style(mode)
		await capture("water-blaster" if mode=="comedy" else "mop-launcher")
	quit()

func stationary(at: Vector3, fast: bool) -> Node3D:
	var foe = game.spawn_enemy(at,fast)
	foe.set_physics_process(false)
	return foe

func look(player: Node3D, target: Vector3) -> void:
	var direction = player.camera.global_position.direction_to(target)
	player.rotation.y = atan2(-direction.x,-direction.z)
	player.pitch = asin(direction.y)
	player.camera.rotation.x = player.pitch

func capture(label: String) -> void:
	for _frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
