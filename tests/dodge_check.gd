extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.player.enabled = false
	game.invulnerable = 999
	game.player.position = Vector3(18,.05,4)
	var enemy = game.spawn_enemy(Vector3(18,0,-7),true)
	enemy.attack = 999
	await get_tree().physics_frame
	aim(enemy.position+Vector3.UP*1.7)
	game.shoot()
	assert(enemy.rush_state=="DODGE" and enemy.health==3 and game.player_bullets.size()==1)
	var start = enemy.position
	game.pause_run()
	var life = game.player_bullets[0].life
	await get_tree().create_timer(.2).timeout
	assert(enemy.position==start and game.player_bullets[0].life==life)
	game.menu_action("resume")
	game.player.enabled = false
	await get_tree().create_timer(.12).timeout
	assert(absf(enemy.position.x-start.x)>.5 and enemy.health==3)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/melee-dodge.png")
	await get_tree().create_timer(.2).timeout
	assert(enemy.health==3 and game.rules.kills==0)
	game.player.position = enemy.position+Vector3(0,0,5)
	await get_tree().physics_frame
	aim(enemy.position+Vector3.UP*1.7)
	game.fire_time = 0
	game.shoot()
	assert(enemy.dead and game.rules.kills==1,"Close shot kills the knife enemy")
	game.start_run()
	assert(game.player_bullets.is_empty())
	print("DODGE_CHECK_PASS: real shot, physical sidestep, pause, far miss, close headshot, reset")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func aim(target: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	game.player.camera.rotation.x = game.player.pitch
