extends SceneTree

var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.reduced_motion = false
	game.set_physics_process(false)
	game.start_run()
	assert(not is_instance_valid(game.comedy_toilet))
	return_to_title()
	var maps = ["score_attack","amusement_park","last_ferry","night_studio"]
	for i in range(maps.size()):
		if i>0:await game.select_session(load("res://data/sessions/"+maps[i]+".tres"))
		assert(game.nav_ready and not is_instance_valid(game.comedy_toilet))
		game.menu_action("comedy" if i%2==0 else "roach")
		game.start_run()
		var fixture = game.comedy_toilet
		assert(fixture and fixture.charge_bodies.size()==3)
		await sync_bodies()
		check_placement(fixture)
		if i<2:await check_blast(fixture)
		return_to_title()
		assert(not is_instance_valid(game.comedy_toilet))
		game.menu_action("comedy" if i%2==0 else "roach")
	print("TOILET_PASS: four clear placements, both toy modes, real shot, cover and 10 m boundary, no duplicates and reset")
	game.queue_free()
	await process_frame
	if DisplayServer.get_name()=="headless":
		var deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<deadline:await process_frame
	quit()

func return_to_title() -> void:
	game.state = "RESULTS"
	game.menu_action("menu")

func check_placement(fixture: Node3D) -> void:
	var bodies = [fixture.booth_body]+fixture.charge_bodies
	var excluded: Array[RID] = []
	for body in bodies:excluded.append(body.get_rid())
	var space = game.get_world_3d().direct_space_state
	for body in bodies:
		var shape: Shape3D = body.get_child(0).shape.duplicate()
		if shape is BoxShape3D:shape.size -= Vector3(.06,.12,.06)
		else:
			shape.height -= .12
			shape.radius -= .02
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = body.global_transform
		query.collision_mask = 1
		query.exclude = excluded
		var overlaps = space.intersect_shape(query)
		assert(overlaps.is_empty(),"%s %s overlaps %s"%[game.arena.map_id,body.name,overlaps])
		var base = body.global_position
		var ground = PhysicsRayQueryParameters3D.create(Vector3(base.x,fixture.position.y+.35,base.z),Vector3(base.x,fixture.position.y-.35,base.z),1,excluded)
		var floor_hit = space.intersect_ray(ground)
		assert(not floor_hit.is_empty() and absf(floor_hit.position.y-fixture.position.y)<.09,"%s support differs for %s"%[game.arena.map_id,body.name])
	var nav = game.get_world_3d().navigation_map
	var approach: Vector3 = fixture.to_global(Vector3(-1.1,0,2.5))
	var closest = NavigationServer3D.map_get_closest_point(nav,approach)
	var path = NavigationServer3D.map_get_path(nav,game.arena.player_start().origin,closest,true)
	assert(closest.distance_to(approach)<.8 and not path.is_empty() and path[-1].distance_to(closest)<.65)
	print("TOILET_PLACEMENT_PASS ",game.arena.map_id)

func check_blast(fixture: Node3D) -> void:
	game.begin_running()
	game.player.enabled = false
	game.hud.go_time = 0
	for actor in game.enemies.get_children():
		game.enemies.remove_child(actor)
		actor.queue_free()
	var center: Vector3 = fixture.global_position
	var inside = stationary(center+Vector3(4,0,0))
	var ledge = stationary(center+Vector3(0,3.1,-9.98))
	var outside = stationary(center+Vector3(10.02,0,0))
	var wall = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(.25,3,2)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.global_position = center+Vector3(2,1,0)
	game.player.global_position = fixture.to_global(Vector3(-1.32,.05,5.8))
	await sync_bodies()
	var charge: Node3D = fixture.charge_bodies[0]
	aim(charge.global_position)
	var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,charge.global_position,1)
	assert(game.get_world_3d().direct_space_state.intersect_ray(ray).get("collider")==charge)
	var exclude_booth: Array[RID] = [fixture.booth_body.get_rid()]
	var cover = PhysicsRayQueryParameters3D.create(center+Vector3.UP,inside.global_position+Vector3.UP,1,exclude_booth)
	assert(game.get_world_3d().direct_space_state.intersect_ray(cover).get("collider")==wall)
	await capture("toilet-"+game.comedy_mode+"-armed")
	var health = game.health
	game.shoot()
	assert(fixture.spent and fixture.booth_body.collision_layer==0 and not fixture.obstacle.avoidance_enabled)
	assert(fixture.charge_bodies.all(func(b):return b.collision_layer==0 and not b.visible))
	assert(inside.dead and ledge.dead and not outside.dead and game.rules.kills==2 and game.health==health)
	assert(game.effects.get_children().filter(func(node):return node is Sprite3D).size()==22)
	assert(game.effects.has_node("Door") and game.effects.has_node("Roof"))
	fixture.explode()
	assert(game.rules.kills==2)
	for _tick in range(16):await physics_frame
	await capture("toilet-"+game.comedy_mode+"-burst")
	wall.queue_free()
	game.start_run()
	assert(game.comedy_toilet!=fixture and not game.comedy_toilet.spent and game.comedy_toilet.booth_body.collision_layer==1)
	game.begin_running()
	var fresh = game.comedy_toilet
	assert(not fresh.shot_hit(false,false) and not fresh.spent)
	assert(fresh.shot_hit(false,true) and not fresh.spent)
	assert(fresh.shot_hit(false,true) and fresh.spent)
	game.start_run()
	game.begin_running()
	game.rules.elapsed = game.rules.duration
	game.rules.active = false
	game.start_finale()
	assert(game.comedy_toilet.spent and game.comedy_toilet.booth_body.collision_layer==0)

func stationary(at: Vector3) -> Node3D:
	var target = game.spawn_enemy(at,false)
	target.set_physics_process(false)
	return target

func sync_bodies() -> void:
	await physics_frame
	await physics_frame

func aim(at: Vector3) -> void:
	var direction = game.player.camera.global_position.direction_to(at)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
