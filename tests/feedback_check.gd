extends Node
var game: Node

func _ready() -> void:
	game.start_run()
	game.begin_running()
	game.spawn_time = 999
	game.set_physics_process(false)
	game.player.enabled = false
	assert(game.music.playing and is_equal_approx(game.music.stream.get_length(),60.0))
	game.pause_run()
	game._physics_process(.1)
	assert(game.music.stream_paused)
	game.menu_action("resume")
	game._physics_process(.01)
	assert(not game.music.stream_paused)
	game.player.enabled = false
	print("FEEDBACK_MUSIC_PASS")
	game.clear_round()
	# A hit cancels healing; five full seconds must elapse before gradual recovery.
	game.health = 32
	game.since_damage = 0
	game._physics_process(4.9)
	assert(game.health==32)
	game._physics_process(.2)
	assert(game.health>32 and game.health<40)
	game.invulnerable = 0
	game.health = 70
	game.damage_player()
	assert(game.health==36 and game.since_damage==0)
	game._physics_process(4.9)
	assert(game.health==36)
	game._physics_process(2)
	assert(game.health>36 and game.health<100)
	game.since_damage = 4.8
	game.invulnerable = .4
	var protected_health = game.health
	game.damage_player()
	assert(game.since_damage==0 and game.health==protected_health)
	print("FEEDBACK_HEAL_PASS")
	# A full magazine delivers twenty shots, then reloads without reserve depletion.
	game.ammo = 20
	game.rules.shots = 0
	game.player.pitch = 1.0
	game.player.camera.rotation.x = 1.0
	for i in range(20):
		game.fire_time = 0
		game.shoot()
	assert(game.ammo==0 and game.reload_time>0 and game.rules.shots==20)
	game.shoot()
	assert(game.rules.shots==20)
	game._physics_process(1)
	assert(game.ammo==20)
	print("FEEDBACK_MAGAZINE_PASS")
	# Exactly one fresh pulse on entering each of the final ten displayed seconds.
	game.last_tick = 11
	for remaining in range(10,0,-1):
		game.hud.time_pulse = 0
		game.rules.elapsed = 60.0-remaining-.01
		game._physics_process(.02)
		assert(game.hud.time_pulse==1)
		game.hud.time_pulse = .5
		game._physics_process(.02)
		assert(game.hud.time_pulse==.5)
	print("FEEDBACK_TEN_PULSES_PASS")
	game.best = 12
	game.rules.kills = 13
	game.finish_run()
	assert(game.new_record and game.best==13 and not game.music.playing)
	game.finish_run()
	assert(not game.new_record and game.best==13)
	game.rules.kills = 0
	game.finish_run()
	assert(not game.new_record and game.best==13)
	print("FEEDBACK_RECORD_PASS")
	# Staged engine captures for reviewing animated typography and health treatment.
	game.state = "RUNNING"
	game.rules.active = true
	game.rules.elapsed = 51
	game.rules.kills = 13
	game.health = 16
	game.player.reset_position()
	await get_tree().process_frame
	game.hud.set_process(false)
	game.hud.health_shade = .85
	game.hud.time_pulse = .7
	game.hud.kill_pop = .25
	game.hud._process(0)
	game.hud.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/feedback.png")
	game.hud.set_process(true)
	game.best = 12
	game.finish_run()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/new-record.png")
	game.clear_round()
	await get_tree().process_frame
	await get_tree().process_frame
	print("FEEDBACK_CHECK_PASS")
	get_tree().quit()
