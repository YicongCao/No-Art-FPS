extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.player.position = Vector3(18,.05,14)
	game.invulnerable = 999
	game.rules.elapsed = 4
	var one = target(Vector3(16,0,9))
	var two = target(Vector3(18,0,9))
	var three = target(Vector3(20,0,9))
	await get_tree().physics_frame
	shoot_head(one)
	assert(game.rules.kills==1 and game.hud.kill_group==1 and game.hud.multi_time==0)
	game.rules.elapsed = 4.4
	shoot_head(two)
	assert(game.rules.kills==2 and game.hud.kill_group==2 and game.hud.multi_time==.65)
	await get_tree().create_timer(.12).timeout
	await capture("double-kill")
	game.rules.elapsed = 4.8
	shoot_head(three)
	assert(game.rules.kills==3 and game.hud.kill_group==3)
	await get_tree().create_timer(.12).timeout
	await capture("triple-kill")
	game.on_kill(three,true)
	assert(game.rules.kills==3 and game.hud.kill_group==3,"Duplicate callbacks cannot create a multi-kill")
	game.pause_run()
	var held = game.hud.multi_time
	await get_tree().create_timer(.2).timeout
	assert(game.hud.multi_time==held)
	game.menu_action("resume")
	game.player.enabled = false
	await get_tree().create_timer(.7).timeout
	assert(game.hud.multi_time==0)
	game.rules.elapsed = 6.1
	var next = target(Vector3(18,0,9))
	await get_tree().physics_frame
	shoot_head(next)
	assert(game.rules.kills==4 and game.kill_group_count==1 and game.hud.multi_time==0,"New burst must start outside the window")
	# Three kills from one environmental event also count as a triple kill.
	game.rules.elapsed = 9
	for x in [16,18,20]:target(Vector3(x,0,9)).take_damage(3)
	assert(game.rules.kills==7 and game.hud.kill_group==3 and game.hud.multi_time>0)
	game.state = "RESULTS"
	game.rules.active = false
	game.on_kill(next,false)
	assert(game.rules.kills==7)
	game.start_run()
	assert(game.rules.kills==0 and game.kill_group_count==0 and game.hud.kill_group==1 and game.hud.multi_time==0)
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	print("MULTIKILL_CHECK_PASS: real headshots, double/triple, no bonus scores, duplicate rejection, pause/fade, window, environmental batch, deadline, reset")
	get_tree().quit()

func target(at: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(at,false)
	enemy.set_physics_process(false)
	return enemy

func shoot_head(enemy: Node3D) -> void:
	var dir = game.player.camera.global_position.direction_to(enemy.position+Vector3.UP*1.7)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.camera.rotation.x = asin(dir.y)
	game.player.pitch = asin(dir.y)
	game.fire_time = 0
	game.shoot()
	assert(enemy.dead)

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
