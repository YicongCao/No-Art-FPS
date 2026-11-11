extends SceneTree

const SCORES = ["night_studio","sandgate","bb_office","rain_market","baggage_below","snowline","hogwarts","palm_house","ginza_station"]
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	game.reduced_motion = false
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	for id in ["score_attack","amusement_park","last_ferry"]+SCORES:
		if id!="score_attack":
			await game.select_session("res://data/sessions/%s.tres"%id,id)
			assert(game.nav_ready and game.session.session_id==id)
		game.start_run()
		game.begin_running()
		for enemy in game.live_enemies():
			enemy.set_physics_process(false)
		game.spawn_time = 999
		await process_frame
		var cue: AudioStream = game.music.stream
		var playback: AudioStreamPlayback = game.music.get_stream_playback()
		if id in SCORES:
			assert(cue==game.session.round_music and cue.resource_path=="res://assets/music/%s.ogg"%id)
			assert(is_equal_approx(cue.get_length(),60.0))
		else:
			assert(game.session.round_music==null)
			assert(cue==(game.COMBAT_MUSIC if id=="score_attack" else game.session.combat_music))
		game.rules.elapsed = 44.99
		game._physics_process(.01)
		assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15.0))
		if id in SCORES:
			assert(game.music.stream==cue and game.music.playing)
			assert(game.music.get_stream_playback()==playback)
		else:
			assert(game.music.stream==(game.DESTROY_MUSIC if id=="score_attack" else game.session.destroy_music))
		if id=="baggage_below":
			check_airport_beats()
		game.pause_run()
		game._physics_process(.1)
		assert(game.music.stream_paused)
		game.menu_action("resume")
		game._physics_process(0.0)
		assert(not game.music.stream_paused)
		game.rules.elapsed = 59.99
		game._physics_process(.01)
		assert(game.finale_active and not game.music.playing)
		game._physics_process(game.rules.finale_duration)
		assert(game.state=="RESULTS")
		game.menu_action("menu")
		print("ARENA_MUSIC_PASS ",id)
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	quit()

func check_airport_beats() -> void:
	var beat_seconds: float = game.arena.airport_display.PHASE_SECONDS
	assert(is_equal_approx(beat_seconds,60.0/104.0))
	for beat in range(26):
		game.rules.elapsed = 45.0+beat_seconds*(beat+.01)
		game.arena._process(0)
		var red = game.arena.frenzy_lights[0].light_energy
		var blue = game.arena.frenzy_lights[1].light_energy
		assert((red>blue)==(beat%2==0))
	game.reduced_motion = true
	game.arena._process(0)
	assert(is_equal_approx(game.arena.frenzy_lights[0].light_energy,game.arena.frenzy_lights[1].light_energy))
	game.reduced_motion = false
	game.rules.elapsed = 45.0
