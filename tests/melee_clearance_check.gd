extends SceneTree
var game: Node3D
const Enemy = preload("res://scripts/enemy.gd")
const AT = Vector3(100,0,100)
func _initialize() -> void:run.call_deferred()
func foe(offset: Vector3, ready_attack: bool = false) -> Node3D:
	game.clear_round()
	game.player.position = AT
	game.player.rotation.y = 0
	game.health = game.MAX_HEALTH
	game.invulnerable = 0
	var actor = game.spawn_enemy(AT+offset,true)
	actor.attack = 0 if ready_attack else 999
	return actor
func ticks(count: int) -> void:
	for i in range(count):await physics_frame
func gap(actor: Node3D) -> float:
	var d = actor.global_position-game.player.global_position
	return Vector2(d.x,d.z).length()
func run() -> void:
	Engine.max_fps = 120
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.start_run();game.begin_running();game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.enemy_model = load("res://assets/models/toy/enemy_mobile.glb")
	game.rusher_model = load("res://assets/models/toy/rusher_mobile.glb")
	# A separate flat navigation island avoids map-specific walls in AI regression cases.
	var floor_body = StaticBody3D.new()
	var shape = CollisionShape3D.new();var box = BoxShape3D.new()
	box.size = Vector3(40,.2,40);shape.shape = box
	floor_body.add_child(shape);floor_body.position = AT-Vector3.UP*.1;game.add_child(floor_body)
	var region = NavigationRegion3D.new();var nav = NavigationMesh.new()
	nav.vertices = PackedVector3Array([Vector3(-20,0,-20),Vector3(-20,0,20),Vector3(20,0,20),Vector3(20,0,-20)])
	nav.add_polygon(PackedInt32Array([0,1,2,3]));region.navigation_mesh = nav
	region.position = AT+Vector3.UP*game.arena.nav.navigation_mesh.cell_height*2.0;game.add_child(region)
	await ticks(3)
	var actor = foe(Vector3(0,0,-5))
	await ticks(180)
	assert(gap(actor)>1.65 and gap(actor)<1.9,"Cooldown chase must stop outside the camera")
	var settled: Vector3 = actor.position
	actor.position = AT+Vector3(0,0,-Enemy.MELEE_STAND_DISTANCE)
	var tangent = actor.melee_spacing_velocity(Vector3(2,0,5.8),1.0/60)
	assert(absf(tangent.x-2)<.001 and tangent.z<.1,"Final RVO command preserves sidesteps without pushing inward")
	actor.position = settled
	print("MELEE_CLEARANCE_APPROACH_PASS gap=",gap(actor))
	actor = foe(Vector3(0,0,3),true)
	await ticks(150)
	assert(gap(actor)>1.65 and actor.rush_state=="CHASE" and game.health==game.MAX_HEALTH,"Rear pursuit must keep clearance without a rear knife hit")
	game.player.rotation.y = PI
	await ticks(52)
	assert(game.health==game.MAX_HEALTH-34,"The original slash still reaches once at the new stand-off distance")
	print("MELEE_CLEARANCE_REAR_AND_HIT_PASS gap=",gap(actor))
	actor = foe(Vector3(0,0,-.4))
	var previous: Vector3 = actor.position
	var max_step := 0.0
	for i in range(60):
		await physics_frame
		max_step = maxf(max_step,actor.position.distance_to(previous));previous = actor.position
	assert(gap(actor)>1.65 and max_step<.13,"Overlap recovery must move smoothly, not teleport")
	print("MELEE_CLEARANCE_OVERLAP_PASS gap=",gap(actor)," max_step=",max_step)
	actor = foe(Vector3(0,0,-1.75),true)
	await ticks(10)
	assert(actor.rush_state=="WINDUP")
	game.state = "PAUSED"
	var pose: Vector3 = actor.position
	await ticks(20)
	assert(actor.position==pose,"Pause freezes retreat and attacks")
	game.state = "RUNNING";game.player.position.x += 4
	await ticks(45)
	assert(game.health==game.MAX_HEALTH,"Locked knife direction remains dodgeable")
	print("MELEE_CLEARANCE_PAUSE_DODGE_PASS")
	actor = foe(Vector3(0,0,-1.75),true)
	await ticks(8)
	var wall = StaticBody3D.new();var wall_shape = CollisionShape3D.new();var wall_box = BoxShape3D.new()
	wall_box.size = Vector3(4,3,.2);wall_shape.shape = wall_box;wall.add_child(wall_shape)
	wall.position = AT+Vector3(0,1.5,-.9);game.add_child(wall)
	await ticks(48)
	assert(game.health==game.MAX_HEALTH,"Solid cover still blocks knife damage")
	var through_corner := Vector3(0,0,5.8)
	assert(actor.melee_spacing_velocity(through_corner,1.0/60)==through_corner,"Occluded path following must not be stopped by the spacing rule")
	wall.queue_free()
	print("MELEE_CLEARANCE_COVER_PASS")
	game.clear_round();game.player.position = AT
	var crowd: Array = []
	for x in [-2.0,0.0,2.0]:
		var member = game.spawn_enemy(AT+Vector3(x,0,-5),true);member.attack = 999;crowd.append(member)
	await ticks(180)
	for member in crowd:assert(gap(member)>1.62,"Crowd avoidance must not push an attacker into the camera")
	print("MELEE_CLEARANCE_CROWD_PASS")
	for type in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for voice in game.find_children("*",type,true,false):voice.stop()
	await create_timer(.15).timeout
	game.queue_free();await create_timer(.15).timeout
	print("MELEE_CLEARANCE_PASS")
	quit()
