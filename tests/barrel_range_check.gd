extends Node
var game: Node

func _ready() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 0
	var source = game.arena.barrels[0]
	var origin: Vector3 = source.global_position
	var actors = []
	for distance in [4.4,6.0,8.0]:
		var enemy = game.spawn_enemy(origin+Vector3(distance,0,0),false)
		enemy.set_physics_process(false)
		actors.append(enemy)
	game.player.position = origin+Vector3(0,.05,6)
	await get_tree().physics_frame
	await get_tree().physics_frame
	source.explode()
	assert(actors[0].dead and actors[1].health==1 and actors[2].health==3)
	assert(game.health<game.MAX_HEALTH and game.health>game.MAX_HEALTH-60)
	for point in game.arena.spawn_points:
		var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),point,game.arena.player_start().origin,true)
		assert(path.size()>1 and path[-1].distance_to(game.arena.player_start().origin)<1)
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.25).timeout
	print("BARREL_RANGE_NAV_PASS: expanded core, 6 m splash, 8 m exclusion, player risk, all spawns connected")
	get_tree().quit()
