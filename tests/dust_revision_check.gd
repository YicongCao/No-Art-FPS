extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 120
	game.player.set_process_unhandled_input(false)
	game.start_run();game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.hud.go_time = 0
	for enemy in game.enemies.get_children():enemy.set_physics_process(false)
	assert(game.arena.find_children("*","Label3D",true,false).is_empty(),"No floating C4 labels")
	assert(game.arena.has_node("floor_b_site") and game.arena.has_node("mid_double_doors") and game.arena.has_node("tunnel_roof"))
	var foundation = game.arena.get_node("SafetyFoundation/Collision")
	assert(foundation.collision_layer==1)
	# Physical downward ray checks cover all map cells, including formerly exposed gaps.
	var checked = 0
	for x in range(-87,27,3):
		for z in range(-23,68,3):
			var ray = PhysicsRayQueryParameters3D.create(Vector3(x,20,z),Vector3(x,-6,z),1)
			var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
			assert(not hit.is_empty(),"No floor below "+str(Vector2(x,z)))
			checked += 1
	# Radar uses the same map-local transforms as the C4 positions.
	assert(game.hud.DUST_RADAR.resource_path.ends_with("dust-radar.svg"))
	for objective in game.arena.objectives:
		assert(game.hud.radar_rect().has_point(game.hud.radar_position(objective.global_position)))
		assert(objective.get_node("Indicator") is MeshInstance3D)
	print("DUST_FLOOR_RADAR_PASS: ",checked," collision rays; 3 objective markers")
	for view in [["dust-revised-long",Vector3(-44,.05,-10),Vector3(-15,1.6,-10)],["dust-revised-a",Vector3(-5,.05,3),Vector3(8,1.8,-13.72)],["dust-revised-mid",Vector3(-43,-3.45,33),Vector3(-51,-1.8,34)],["dust-revised-b",Vector3(-62,-3.45,45),Vector3(-80,-.8,60)],["dust-revised-tunnel",Vector3(-80,-3.45,31),Vector3(-80,-1.8,22)]]:
		game.player.global_position = view[1]
		aim(view[2])
		await capture(view[0])
	game.player.global_position = Vector3(8,.05,-8)
	aim(Vector3(8,1.8,-13.72))
	await capture("dust-a-mark")
	var objective = game.arena.objectives[0]
	game.player.global_position = objective.global_position+Vector3(0,-.4,1)
	game.player.velocity = Vector3.ZERO
	aim(objective.global_position)
	await get_tree().physics_frame
	assert(objective.available())
	objective.set_physics_process(false)
	Input.action_press("interact")
	objective._physics_process(2.5)
	assert(objective.progress==2.5)
	await capture("dust-defuse-ring-half")
	objective._physics_process(2.4)
	await capture("dust-defuse-ring-nearly-full")
	game.touch_mode = true
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(.15).timeout
	await capture("dust-defuse-ring-small")
	game.touch_mode = false
	DisplayServer.window_set_size(Vector2i(1280,720))
	game.pause_run()
	assert(objective.progress==0)
	game.menu_action("resume");game.player.enabled = false
	Input.action_release("interact")
	game.rules.completed[objective.objective_id] = 1
	objective.mark_defused()
	await capture("dust-radar-one-defused")
	# Walking off each nominal outer side hits the authored perimeter.
	for xz in [Vector2(-88.5,0),Vector2(27.5,0),Vector2(-50,-24.5),Vector2(-50,68.5)]:
		var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(xz.x,0,xz.y),Vector3(xz.x,-6,xz.y),1))
		assert(not hit.is_empty())
	game.invulnerable = 999
	game.player.global_position = Vector3(-60,-7,0)
	game.player.enabled = true
	game.player._physics_process(1.0/60)
	assert(game.state=="RESULTS" and game.rules.outcome=="DEAD")
	var final_position = game.player.global_position
	assert(final_position.y==game.arena.fall_limit and game.player.velocity==Vector3.ZERO and not game.player.enabled)
	await get_tree().create_timer(.3).timeout
	assert(game.player.global_position==final_position,"Fall failure freezes instead of falling forever")
	game.start_run()
	assert(game.health==100 and game.rules.completed.is_empty())
	game.state = "RESULTS";game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("DUST_REVISION_CHECK_PASS: expanded landmarks, bounded floor, mapped C4s, ring, completion/cancel, fall freeze and restart")
	get_tree().quit()

func aim(point: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(point)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	game.player.camera.rotation.x = game.player.pitch

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for frame in range(4):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+name+".png")
