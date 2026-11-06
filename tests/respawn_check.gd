extends Node

var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.spawn_time = 999
	assert(game.rules.deaths==0)
	defeat()
	assert(game.rules.deaths==1 and game.respawn_time==3 and not game.player.enabled)
	assert(not game.player.gun.visible)
	var shots = game.rules.shots
	game.shoot()
	game.damage_player(100)
	assert(game.rules.shots==shots and game.rules.deaths==1)
	await capture("death-wait")
	game.pause_run()
	game._physics_process(1)
	assert(game.respawn_time==3)
	game.menu_action("resume")
	assert(not game.player.enabled,"Resume must not re-enable a dead player")
	var start = game.player.position
	var clock = game.rules.elapsed
	Input.action_press("forward")
	for frame in range(179):
		game._physics_process(1.0/60.0)
		await get_tree().physics_frame
		assert(game.respawn_time>0 and not game.player.enabled,"No early respawn")
		assert(game.player.position.is_equal_approx(start),"Cannot move during death wait")
	Input.action_release("forward")
	game._physics_process(1.0/60.0)
	assert(game.respawn_time==0 and game.player.enabled and game.player.gun.visible)
	assert(game.health==100 and game.ammo==20 and game.rules.deaths==1)
	assert(is_equal_approx(game.rules.elapsed-clock,3),"Round clock keeps running during death")
	await capture("death-one")
	defeat()
	for frame in range(180):game._physics_process(1.0/60.0)
	assert(game.rules.deaths==2 and game.respawn_time==0)
	await capture("death-two")
	# A death near the deadline ends at results; it must not respawn after time is up.
	game.rules.elapsed = 59
	defeat()
	game._physics_process(1)
	assert(game.state=="RESULTS" and not game.player.enabled)
	game._physics_process(6)
	assert(game.state=="RESULTS" and game.rules.deaths==3)
	await capture("text-review-results")
	game.start_run()
	assert(game.rules.deaths==0 and game.respawn_time==0 and game.player.gun.visible)
	await capture("death-reset")
	# Starting over during a pending death also clears the entire sequence.
	game.begin_running()
	game.clear_round()
	defeat()
	game.start_run()
	assert(game.rules.deaths==0 and game.respawn_time==0 and game.player.gun.visible)
	game.pause_run()
	await capture("text-review-pause")
	game.menu_action("resume")
	game.state = "TITLE"
	await capture("text-review-title")
	print("RESPAWN_CHECK_PASS: exact 180 ticks, pause/input lock, one count per death, deadline, restart")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func defeat() -> void:
	game.invulnerable = 0
	game.damage_player(100)

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
