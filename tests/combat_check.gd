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
