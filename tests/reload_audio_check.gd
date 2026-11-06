extends Node

var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.set_process(false)
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	assert(game.sounds.cartridge_insert is AudioStreamWAV)
	assert(game.sounds.cartridge_insert.get_length()>0 and game.sounds.cartridge_insert.get_length()<.04)
	# Drive the real reload clock, checking actual audio voices at every tick.
	for starting in [0,14,19]:
		prepare_run()
		game.ammo = starting
		game.reduced_motion = starting==19
		game.reload_weapon()
		var total = game.audio_index
		for tick in range(54):
			var before = game.audio_index
			var previous = int(game.hud.reload_rounds_fed())
			game._physics_process(1.0/60.0)
			var fed = int(game.hud.reload_rounds_fed()) if game.reload_time>0 else 20-starting
			assert_insertions(before,fed-previous)
			assert(game.audio_index-total==fed,"Insertion sounds must match seated cartridges")
			if tick==10:
				game.pause_run()
				var held_time = game.reload_time
				before = game.audio_index
				game._physics_process(.5)
				await get_tree().create_timer(.1).timeout
				assert(game.reload_time==held_time)
				assert_insertions(before,0)
				game.menu_action("resume")
				game.player.enabled = false
			await get_tree().physics_frame
		assert(game.ammo==20 and game.reload_time==0 and game.audio_index-total==20-starting)
		var before = game.audio_index
		game._physics_process(.1)
		assert_insertions(before,0)
		print("RELOAD_AUDIO_FEED_PASS ",20-starting)
	# A delayed step still includes the last cartridge at reload completion.
	prepare_run()
	game.ammo = 0
	game.reload_weapon()
	var before = game.audio_index
	game._physics_process(.9)
	assert_insertions(before,20)
	assert(game.ammo==20)
	# Death and results cancel future clicks instead of leaving an audio timer.
	prepare_run()
	game.ammo = 0
	game.reload_weapon()
	game._physics_process(.2)
	game.invulnerable = 0
	game.damage_player(100)
	before = game.audio_index
	game._physics_process(.2)
	assert_insertions(before,0)
	game.start_run()
	assert_insertions(before,0)
	assert(game.reload_time==0)
	prepare_run()
	game.ammo = 0
	game.reload_weapon()
	game.rules.elapsed = 59.99
	before = game.audio_index
	game._physics_process(.02)
	assert(game.state=="RESULTS" and game.audio_index==before+1)
	assert(game.audio_voices[before%game.audio_voices.size()].stream==game.sounds.end)
	before = game.audio_index
	game._physics_process(.2)
	assert_insertions(before,0)
	# Loading uses the same sound at the same whole-round boundary.
	game.clear_round()
	game.state = "LOADING"
	game.loading = game.LoadingTransition.new()
	game.loading.report(1)
	var total = game.audio_index
	for frame in range(240):
		before = game.audio_index
		var previous = int(game.loading.rounds)
		game._process(1.0/60.0)
		assert_insertions(before,int(game.loading.rounds)-previous)
		assert(game.audio_index-total==int(game.loading.rounds))
	assert(game.loading.rounds==17 and game.audio_index-total==17)
	before = game.audio_index
	game._process(1)
	assert_insertions(before,0)
	game.loading.suspended = true
	game.loading.work_complete = true
	game._process(1)
	assert(game.loading.rounds==17)
	assert_insertions(before,0)
	game.loading.suspended = false
	for frame in range(20):
		before = game.audio_index
		var previous = int(game.loading.rounds)
		game._process(1.0/60.0)
		assert_insertions(before,int(game.loading.rounds)-previous)
	assert(game.loading.rounds==20 and game.audio_index-total==20)
	# Seating, revealing and docking cannot replay the twenty insertions.
	for frame in range(70):
		before = game.audio_index
		game._process(1.0/60.0)
		assert_insertions(before,0)
	assert(game.loading.phase=="DOCK")
	game.cancel_loading()
	before = game.audio_index
	game._process(.2)
	assert_insertions(before,0)
	game.state = "LOADING"
	game.loading = game.LoadingTransition.new()
	game.loading.work_complete = true
	game._process(.05)
	assert_insertions(before,0)
	game._process(.05)
	assert_insertions(before,1)
	game.cancel_loading()
	await get_tree().create_timer(.2).timeout
	print("RELOAD_AUDIO_CHECK_PASS: actual voices, 20/6/1 cartridges, pause, completion, death/deadline/reset, loading 17+3, suspension, no repeated clicks, cancel/reentry")
	get_tree().quit()

func prepare_run() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.player.enabled = false
	game.spawn_time = 999
	game.invulnerable = 999

func assert_insertions(before: int, expected: int) -> void:
	assert(game.audio_index-before==expected,"Expected %d insertion sounds, got %d"%[expected,game.audio_index-before])
	for index in range(before,game.audio_index):
		var voice = game.audio_voices[index%game.audio_voices.size()]
		assert(voice.stream==game.sounds.cartridge_insert and voice.playing)
		assert(voice.volume_db==-12)
