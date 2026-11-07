extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	await check_nonstructural_hits()
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.spawn_time = 999
	game.player.position = Vector3(-6,.05,4)
	var room = game.arena.structures[1]
	var inside = stationary(Vector3(-6,0,-3))
	var outside = stationary(Vector3(18,0,3))
	await get_tree().physics_frame
	aim(Vector3(-6,1.4,-1.6))
	shoot_rounds(2)
	assert(room.hits==0 and not room.collapsed,"Normal rounds cannot destroy buildings")
	for _tick in range(2699):game.rules.tick(1.0/60.0)
	game._physics_process(0)
	assert(not game.destroy_active)
	game._physics_process(1.0/60.0)
	assert(game.destroy_active and game.hud.destroy_time>1.5)
	assert(is_equal_approx(game.rules.remaining(),15),"DESTROY starts at exactly 45 seconds / 2700 ticks")
	var audio_before = game.audio_index
	game._physics_process(1.0/60.0)
	assert(game.audio_index==audio_before,"The DESTROY announcement only plays once")
	game.ammo = 20
	game.reload_time = 0
	shoot_rounds(1)
	assert(room.hits==1 and room.burn_time<0 and not room.collapsed)
	shoot_rounds(1)
	assert(room.burn_time>0 and room.hits==2,"Second burning shot ignites the wall")
	await capture("destroy-ignition")
	game.pause_run()
	var held = room.burn_time
	await get_tree().create_timer(.2).timeout
	assert(room.burn_time==held and not room.collapsed)
	game.menu_action("resume")
	game.player.enabled = false
	await get_tree().create_timer(.58).timeout
	assert(room.collapsed and inside.dead and not outside.dead and game.rules.kills==1)
	for body in room.collision_states:assert(body.collision_layer==0)
	await capture("destroy-collapse")
	room.collapse()
	inside.take_hit(true)
	assert(game.rules.kills==1,"Collapse kill is counted once")
	# Burn damage uses the same death registry and respects the round deadline.
	var burning = stationary(Vector3(18,0,-1))
	burning.set_physics_process(true)
	burning.agent.velocity = Vector3.ZERO
	burning.ignite()
	await get_tree().create_timer(.8).timeout
	assert(burning.dead and game.rules.kills==2)
	# Shoot warehouse structural walls, then verify its roof and floor behaviour.
	game.player.position = Vector3(18,.05,-2.5)
	var warehouse = game.arena.warehouse_structure
	var guard = stationary(Vector3(30,0,-3))
	await get_tree().physics_frame
	aim(Vector3(24,2.6,-2.5))
	game.ammo = 20
	shoot_rounds(2)
	assert(warehouse.burn_time>0)
	await get_tree().create_timer(.6).timeout
	assert(warehouse.collapsed and guard.dead and game.zone_capacity("warehouse")==0)
	await capture("destroy-warehouse")
	# Collapse the upper deck and confirm removed support leaves only ground.
	game.player.position = Vector3(0,.05,-4.5)
	var deck = game.arena.deck_structure
	var deck_guard = stationary(Vector3(4,3.1,-11))
	await get_tree().physics_frame
	aim(Vector3(0,1.5,-8.9))
	game.ammo = 20
	shoot_rounds(2)
	assert(deck.burn_time>0)
	await get_tree().create_timer(.6).timeout
	assert(deck.collapsed and deck_guard.dead and game.zone_capacity("deck")==0 and game.zone_capacity("yard")==12)
	var ray = PhysicsRayQueryParameters3D.create(Vector3(4,8,-11),Vector3(4,-1,-11),1)
	var floor_hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
	assert(not floor_hit.is_empty() and floor_hit.position.y<.1,"Destroyed deck no longer has invisible floor")
	await navigation_ready()
	var start = Vector3(18,0,-2.5)
	var end = Vector3(30,0,-2.5)
	var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),start,end,true)
	assert(path.size()>1 and path[-1].distance_to(end)<1)
	print("DESTROY_COLLISION_NAV_SCORE_PASS")
	# An already primed building cannot collapse or add scores after results.
	var late = game.arena.structures[2]
	late.burn_time = .01
	game.state = "RESULTS"
	game.rules.active = false
	var final = game.rules.kills
	await get_tree().create_timer(.1).timeout
	late.collapse()
	assert(not late.collapsed and game.rules.kills==final)
	game.start_run()
	assert(not game.destroy_active and game.hud.destroy_time==0)
	for building in game.arena.structures:
		assert(not building.collapsed and building.hits==0 and building.burn_time<0)
		for body in building.collision_states:assert(body.collision_layer==building.collision_states[body])
	await navigation_ready()
	var upstairs = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),Vector3(0,0,10.5),Vector3(4,3.1,-11),true)
	assert(upstairs.size()>1 and upstairs[-1].distance_to(Vector3(4,3.1,-11))<.7)
	assert(game.rules.kills==0 and game.effects.get_child_count()==0)
	print("DESTROY_CHECK_PASS: boundary, real fire shots, burn/pause, rubble, burial score, collision/nav, deadline, full reset")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func check_nonstructural_hits() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.rules.elapsed = 45
	game._physics_process(0)
	assert(game.destroy_active)
	game.player.position = Vector3(18,.05,14)
	var head = stationary(Vector3(18,0,9))
	var body = stationary(Vector3(21,0,9))
	await get_tree().physics_frame
	await get_tree().physics_frame
	shoot_nonstructural(head.position+Vector3.UP*1.7)
	assert(head.dead and game.rules.kills==1,"Burning headshots still score on ordinary enemies")
	await get_tree().physics_frame
	shoot_nonstructural(body.position+Vector3.UP*.8)
	assert(body.health==2 and body.burn_ticks==3,"Burning body shots still damage and ignite enemies")
	shoot_nonstructural(Vector3(18,0,12))
	assert(game.rules.kills==1,"Ground hits cannot score or be treated as a building")
	game.player.position = Vector3(-8,.05,8)
	await get_tree().physics_frame
	var barrel = game.arena.barrels[0]
	shoot_nonstructural(barrel.global_position+Vector3.UP*.8)
	assert(barrel.destroy_hits==1 and not barrel.spent,"First burning hit damages a barrel")
	shoot_nonstructural(barrel.global_position+Vector3.UP*.8)
	assert(barrel.spent,"Second burning hit detonates a barrel")
	game.player.position = Vector3(0,.05,10.5)
	await get_tree().physics_frame
	var forklift_point = Vector3(-2,1.3,-1)
	var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,forklift_point,game.shot_collision_mask(true))
	var cover = game.get_world_3d().direct_space_state.intersect_ray(ray)
	var forklift = cover.collider.get_meta("structure")
	assert(forklift.scenery,"The forklift is independently destructible")
	aim(forklift_point)
	shoot_rounds(1)
	assert(forklift.hits==1 and forklift.burn_time<0)
	shoot_rounds(1)
	assert(forklift.hits==2 and forklift.burn_time>0)
	await get_tree().create_timer(.3).timeout
	assert(forklift.collapsed)
	for collider in forklift.collision_states:assert(collider.collision_layer==0)
	forklift.restore()
	assert(not forklift.collapsed and forklift.hits==0)
	# The light post has no movement collider. Its shot target still removes
	# both the post and the lamp from their shared mesh batches.
	game.player.position = Vector3(10.4,.05,8)
	await get_tree().physics_frame
	var lamp_point = Vector3(13,2.4,8)
	ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,lamp_point,game.shot_collision_mask(true))
	var lamp_hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
	assert(lamp_hit.collider.collision_layer==game.SCENERY_TARGET_LAYER)
	var lamp = lamp_hit.collider.get_meta("structure")
	assert(lamp.batch_parts.size()==2)
	aim(lamp_point)
	shoot_rounds(2)
	await get_tree().create_timer(.3).timeout
	assert(lamp.collapsed)
	if DisplayServer.get_name()!="headless":
		for path in lamp.batch_parts:
			var batch = game.arena.get_node(path)
			for index in lamp.batch_parts[path]:
				assert(batch.multimesh.get_instance_transform(index).basis==Basis.from_scale(Vector3.ZERO))
	var untagged_area = Area3D.new()
	assert(game.enemy_from_hit({"collider":untagged_area})==null,"Unmarked areas are not enemy heads")
	untagged_area.free()
	print("DESTROY_NONSTRUCTURAL_HITS_PASS: real burning head/body/ground/barrel shots and unmarked area")

func shoot_nonstructural(point: Vector3) -> void:
	var query = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1|4|8)
	query.collide_with_areas = true
	var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
	assert(not hit.is_empty() and not hit.collider.has_meta("structure"),"Regression shot must hit an unmarked collider: point=%s hit=%s"%[point,hit])
	aim(point)
	game.fire_time = 0
	game.shoot()

func stationary(at: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(at,false)
	enemy.set_physics_process(false)
	return enemy

func shoot_rounds(count: int) -> void:
	for i in range(count):
		game.fire_time = 0
		game.shoot()

func aim(target: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	game.player.camera.rotation.x = game.player.pitch

func navigation_ready() -> void:
	for i in range(600):
		await get_tree().physics_frame
		if not game.arena.navigation_dirty and not game.arena.navigation_baking:break
	assert(not game.arena.navigation_dirty and not game.arena.navigation_baking)
	await get_tree().physics_frame
	await get_tree().physics_frame

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
