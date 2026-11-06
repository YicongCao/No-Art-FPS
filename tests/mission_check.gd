extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 120
	game.player.set_process_unhandled_input(false)
	assert(game.rules.mission and game.rules.duration==180)
	assert(game.arena.objectives.size()==3 and game.opening.size()==8)
	for objective in game.arena.objectives:
		var target = objective.global_position-Vector3.UP*.4
		var path = NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,game.arena.player_start().origin,target,true)
		assert(path.size()>1 and path[-1].distance_to(target)<1,"Objective not reachable: "+objective.objective_id+" path="+str(path))
	for actor in game.opening:
		var route = actor.patrol
		var path = NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,route[0],route[1],true)
		assert(path.size()>1 and path[-1].distance_to(route[1])<1,"Patrol route blocked: "+str(route)+" path="+str(path))
	print("MISSION_NAV_PASS: all objectives and patrol legs")
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	var first = game.enemies.get_child(0)
	var before = first.global_position
	await get_tree().create_timer(2.5).timeout
	assert(first.patrol_brain!=null and first.global_position.distance_to(before)>.5)
	assert(not first.patrol_brain.sees_player(),"A wall/distance should prevent seeing the starting player")
	await capture("dust-long")
	for enemy in game.enemies.get_children():enemy.set_physics_process(false)
	game.set_physics_process(false)
	for objective in game.arena.objectives:objective.set_physics_process(false)
	var target = game.arena.objectives[0]
	game.player.global_position = target.global_position+Vector3(0,-.4,1)
	game.player.velocity = Vector3.ZERO
	game.player.enabled = false
	await get_tree().physics_frame
	assert(target.available())
	Input.action_press("interact")
	target._physics_process(2)
	assert(target.progress==2 and game.objective_focus==target)
	var shots = game.rules.shots
	game.shoot();game.reload_weapon()
	assert(game.rules.shots==shots and game.reload_time==0)
	game.invulnerable = 0
	game.damage_player(1)
	assert(target.progress==0 and target.needs_release)
	target._physics_process(5)
	assert(game.rules.completed.is_empty())
	Input.action_release("interact");target._physics_process(0)
	Input.action_press("interact");target._physics_process(2)
	game.pause_run()
	assert(target.progress==0)
	game.menu_action("resume");game.player.enabled = false
	Input.action_release("interact");target._physics_process(0)
	# An opaque test wall blocks the interaction even inside the distance threshold.
	var wall = StaticBody3D.new();var shape = CollisionShape3D.new();var box = BoxShape3D.new()
	box.size = Vector3(2,3,.1);shape.shape = box;wall.add_child(shape);game.add_child(wall)
	wall.global_position = target.global_position+Vector3(0,.6,.5)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(not target.available())
	wall.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	# All three objectives complete through real component input, in reverse order.
	for i in [2,1,0]:
		target = game.arena.objectives[i]
		game.player.global_position = target.global_position+Vector3(0,-.4,1)
		game.player.velocity = Vector3.ZERO
		Input.action_release("interact");target._physics_process(0)
		await get_tree().physics_frame
		assert(target.available())
		Input.action_press("interact")
		for tick in range(299):
			target._physics_process(1.0/60.0)
			assert(not game.rules.completed.has(target.objective_id))
		target._physics_process(1.0/60.0)
		game.settle_rules()
		assert(game.rules.completed.has(target.objective_id))
		Input.action_release("interact")
		if i==1:await capture("dust-short")
	assert(game.rules.outcome=="SUCCESS" and game.state=="RESULTS")
	await capture("mission-success")
	game.start_run();game.begin_running()
	for objective in game.arena.objectives:objective.set_physics_process(false)
	game.player.enabled = false
	assert(game.rules.completed.is_empty() and game.health==100)
	for id in game.rules.objective_ids:game.rules.request_defuse(id)
	game.invulnerable = 0
	game.damage_player(100)
	game.settle_rules()
	assert(game.rules.outcome=="DEAD" and game.state=="RESULTS" and game.respawn_time==0 and game.rules.completed.is_empty())
	await capture("mission-dead")
	for duration in [120,150,180]:
		game.rules.duration = duration
		game.start_run();game.begin_running();game.player.enabled = false
		game.rules.elapsed = duration-1.0/60.0
		game._physics_process(1.0/60.0);game.settle_rules()
		assert(game.rules.outcome=="TIMEOUT" and not game.destroy_active and not game.finale_active)
	await capture("mission-timeout")
	game.menu_action("menu")
	await game.select_session(game.DefaultSession)
	assert(not game.rules.mission and game.rules.duration==60 and game.arena.map_id=="yard")
	game.start_run();game.begin_running();game.player.enabled = false
	game.invulnerable = 0;game.damage_player(100)
	assert(game.respawn_time==5)
	game.state = "RESULTS";game.menu_action("menu")
	await game.select_session(load("res://data/sessions/defuse.tres"))
	assert(game.rules.mission and game.arena.objectives.size()==3 and game.rules.completed.is_empty())
	game.state = "RESULTS";game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("MISSION_CHECK_PASS: objective/patrol navigation, patrol movement, interaction/weapon lock, hurt/pause/occlusion cancel, reverse-order success, death/timeout, retry and mode isolation")
	get_tree().quit()

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for i in range(8):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+name+".png")
