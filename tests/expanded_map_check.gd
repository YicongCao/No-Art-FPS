extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().physics_frame
	await get_tree().physics_frame
	for point in game.arena.spawn_points:
		var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),point,Vector3(0,0,10.5),true)
		assert(path.size()>1 and path[-1].distance_to(Vector3(0,0,10.5))<1,"Spawn must connect to yard: "+str(point))
	print("EXPANSION_NAV_PASS: all spawn points including warehouse and deck connect to yard")
	# Enter the warehouse through the loading bay and through a side door.
	for entry in [Vector3(30,.05,12),Vector3(21,.05,4)]:
		game.player.position = entry
		game.player.velocity = Vector3.ZERO
		game.player.rotation.y = 0 if entry.x==30 else -PI/2
		Input.action_press("forward")
		await get_tree().create_timer(1.2).timeout
		Input.action_release("forward")
		if entry.x==30:assert(game.player.position.z<8)
		else:assert(game.player.position.x>25)
	print("EXPANSION_WAREHOUSE_ENTRY_PASS")
	# Walk sideways against each stair rail; the capsule must stay above the stair, inside its side.
	for x in [-11.0,7.6]:
		game.player.position = Vector3(x,1.65,-5)
		game.player.velocity = Vector3.ZERO
		game.player.rotation.y = 0
		await get_tree().create_timer(.3).timeout
		Input.action_press("right")
		await get_tree().create_timer(.75).timeout
		Input.action_release("right")
		assert(game.player.position.y>1.0,"Rail must prevent walking off the stair")
		assert(game.player.position.x<x+1.1,"Rail must stop sideways capsule travel")
	print("EXPANSION_RAILS_PASS")
	game.player.position = Vector3(18,.05,14)
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = 0
	Input.action_press("forward")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("forward")
	assert(game.player.position.z<6,"Crosswalk and street must be continuously walkable")
	print("EXPANSION_STREET_PASS")
	game.player.enabled = false
	game.set_physics_process(false)
	game.rules.elapsed = 18
	game.rules.kills = 8
	game.ammo = 16
	await shot("expanded-yard",Vector3(-2,1.8,11),Vector3(5,1.5,-3))
	await shot("street",Vector3(18,1.8,21),Vector3(24,2,-6))
	await shot("warehouse",Vector3(30,1.8,7),Vector3(30,2,-12))
	await shot("stairs",Vector3(-14,1.8,1),Vector3(-11,2,-5))
	game.clear_round()
	await get_tree().process_frame
	await get_tree().process_frame
	print("EXPANSION_CHECK_PASS")
	get_tree().quit()

func shot(filename: String, eye: Vector3, target: Vector3) -> void:
	game.player.position = eye-Vector3(0,1.65,0)
	var direction = eye.direction_to(target)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
