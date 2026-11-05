extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.position = Vector3(-8,.05,8)
	game.invulnerable = 0
	var barrel = game.arena.barrels[0]
	var adjacent = game.arena.barrels[1]
	var near = stationary(Vector3(-6.5,0,5))
	var far = stationary(Vector3(-1,0,5))
	var covered = stationary(Vector3(-8,0,1))
	var wall = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3,3,.4)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = Vector3(-8,1.5,2.5)
	await get_tree().physics_frame
	await get_tree().physics_frame
	aim(barrel.global_position+Vector3.UP*.8)
	game.shoot()
	assert(barrel.fuse>0 and not barrel.spent,"Real bullet must ignite barrel")
	game.state = "PAUSED"
	var fuse = barrel.fuse
	await get_tree().create_timer(.8).timeout
	assert(barrel.fuse==fuse and not barrel.spent,"Pause freezes ignition")
	game.state = "RUNNING"
	await get_tree().create_timer(.72).timeout
	assert(barrel.spent and near.dead and game.rules.kills==1)
	assert(far.health==3 and covered.health==3,"Range and solid cover block blast")
	assert(game.health<100 and game.health>0,"Blast hurts nearby player")
	assert(adjacent.fuse>0 or adjacent.spent,"Nearby barrel chains")
	await get_tree().create_timer(.35).timeout
	assert(adjacent.spent)
	barrel.explode()
	assert(game.rules.kills==1,"Repeated explosions cannot duplicate score")
	print("COMBAT_BARREL_PASS: bullet, warning, pause, chain, cover, range, player damage, score")
	game.state = "RESULTS"
	game.rules.active = false
	game.arena.barrels[2].ignite()
	assert(game.arena.barrels[2].fuse<0)
	wall.queue_free()
	game.start_run()
	assert(game.rules.kills==0)
	for item in game.arena.barrels:assert(not item.spent and item.fuse<0 and item.collision_layer==1 and item.visual.visible)
	print("COMBAT_BARREL_RESET_PASS")
	game.begin_running()
	game.clear_round()
	game.player.enabled = false
	game.player.position = Vector3(18,.05,0)
	game.invulnerable = 0
	var rusher = game.spawn_enemy(Vector3(18,0,5),true)
	rusher.attack = 0
	await get_tree().create_timer(.12).timeout
	assert(rusher.fast and rusher.rush_state=="WINDUP" and rusher.charge_marker.visible)
	assert(not rusher.visual.find_child("EnemyGun",true,false).visible)
	game.state = "PAUSED"
	var warning = rusher.rush_time
	await get_tree().create_timer(.3).timeout
	assert(rusher.rush_time==warning)
	game.state = "RUNNING"
	game.player.position.x = 22
	await get_tree().create_timer(1.5).timeout
	assert(game.health==100 and absf(rusher.position.x-18)<.2,"Sidestep must dodge locked-direction charge")
	assert(rusher.rush_state=="RECOVER" and game.bullets.is_empty())
	print("COMBAT_RUSH_DODGE_PAUSE_PASS")
	game.clear_round()
	game.player.position = Vector3(18,.05,0)
	game.invulnerable = 0
	rusher = game.spawn_enemy(Vector3(18,0,4),true)
	rusher.attack = 0
	await get_tree().create_timer(1.3).timeout
	assert(game.health==58 and rusher.rush_state=="RECOVER","Contact deals one 42-point hit")
	await get_tree().create_timer(.3).timeout
	assert(game.health==58)
	print("COMBAT_RUSH_CONTACT_PASS")
	game.clear_round()
	game.health = 100
	game.invulnerable = 0
	rusher = game.spawn_enemy(Vector3(18,0,5),true)
	rusher.attack = 0
	await get_tree().create_timer(.1).timeout
	assert(rusher.rush_state=="WINDUP")
	var blocker = StaticBody3D.new()
	var blocker_shape = CollisionShape3D.new()
	blocker_shape.shape = box
	blocker.add_child(blocker_shape)
	game.add_child(blocker)
	blocker.position = Vector3(18,1.5,2.5)
	await get_tree().create_timer(1.2).timeout
	assert(game.health==100 and rusher.position.z>2.5 and rusher.rush_state=="RECOVER")
	blocker.queue_free()
	print("COMBAT_RUSH_WALL_PASS")
	game.clear_round()
	rusher = game.spawn_enemy(Vector3(18,0,5),true)
	rusher.attack = 0
	await get_tree().create_timer(.1).timeout
	assert(rusher.rush_state=="WINDUP")
	var before = game.rules.kills
	rusher.take_hit(true)
	assert(rusher.dead and not rusher.charge_marker.visible and game.rules.kills==before+1)
	await get_tree().create_timer(1).timeout
	assert(game.health==100)
	print("COMBAT_RUSH_INTERRUPT_PASS")
	if DisplayServer.get_name()!="headless":await showcase()
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.25).timeout
	print("COMBAT_CHECK_PASS")
	get_tree().quit()

func stationary(pos: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(pos,false)
	enemy.set_physics_process(false)
	return enemy

func aim(target: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	game.player.camera.rotation.x = game.player.pitch

func showcase() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.player.enabled = false
	game.player.position = Vector3(0,.05,8)
	game.invulnerable = 999
	var rusher = game.spawn_enemy(Vector3(-5,0,3),true)
	rusher.set_physics_process(false)
	rusher.start_charge()
	rusher.visual.position.y = -.12
	stationary(Vector3(-6.8,0,5))
	await get_tree().physics_frame
	aim(Vector3(-6,1.1,4))
	await get_tree().create_timer(.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/combat-warning.png")
	game.arena.barrels[0].explode()
	await get_tree().create_timer(.07).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/combat-explosion.png")
