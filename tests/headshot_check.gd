extends SceneTree
var game: Node3D
const FX = preload("res://scripts/headshot_fx.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.position = Vector3(18,.05,14)
	for fast in [false,true]:
		for wounded in [false,true]:
			game.clear_round()
			var foe = game.spawn_enemy(Vector3(18,.05,10.5),fast)
			foe.set_physics_process(false)
			if wounded:foe.take_hit(false)
			await physics_frame
			await physics_frame
			var target: Vector3 = foe.global_position+Vector3.UP*1.7
			var direction: Vector3 = game.player.camera.global_position.direction_to(target)
			game.player.rotation.y = atan2(-direction.x,-direction.z)
			game.player.pitch = asin(direction.y)
			game.player.camera.rotation.x = game.player.pitch
			game.player.crosshair_offset = Vector2.ZERO
			game.fire_time = 0
			game.ammo = 30
			var kills: int = game.rules.kills
			game.shoot()
			assert(foe.dead and foe.headshot_death and game.rules.kills==kills+1)
			assert(foe.collision_layer==0 and foe.head_area.collision_layer==0)
			assert(game.hud.headshot_confirm>0)
			assert(not foe.visual.find_child("Helmet",true,false).visible and foe.head_core.visible)
			var effects := get_nodes_in_group("headshot_feedback")
			assert(effects.size()==1)
			var fx = effects[0]
			assert(fx.full_burst and fx.pieces[FX.Shape.CHUNK].size()==9)
			foe.take_hit(true)
			assert(game.rules.kills==kills+1 and get_nodes_in_group("headshot_feedback").size()==1)
			foe.set_physics_process(true)
			game.state = "PAUSED"
			var age: float = fx.age
			var death_age: float = foe.death_time
			var confirm: float = game.hud.headshot_confirm
			for i in range(5):await physics_frame
			assert(fx.age==age and foe.death_time==death_age and game.hud.headshot_confirm==confirm)
			game.state = "RUNNING"
			for i in range(50):await physics_frame
			assert(get_nodes_in_group("headshot_feedback").is_empty())
			assert(game.hud.headshot_confirm==0 and not foe.head_core.visible)
	print("HEADSHOT_REAL_BULLET_PASS: both actors, pristine/wounded, single score, pause and cleanup")
	for kind in ["body","burning_body","explosion","finale"]:
		game.clear_round()
		await process_frame
		var foe = game.spawn_enemy(Vector3(18,.05,10.5),false)
		foe.set_physics_process(false)
		match kind:
			"body":
				foe.take_hit(false)
				assert(foe.health==1 and foe.wounded)
				foe.take_hit(false)
			"burning_body":foe.take_hit(false,true)
			"explosion":foe.take_damage(3)
			"finale":foe.take_damage(3,false,true)
		assert(foe.dead and not foe.headshot_death and game.hud.headshot_confirm==0)
		assert(get_nodes_in_group("headshot_feedback").is_empty())
	print("HEADSHOT_SOURCE_FILTER_PASS")
	for mode in ["comedy","roach"]:
		game.clear_round()
		await process_frame
		game.comedy_mode = mode
		var foe = game.spawn_enemy(Vector3(18,.05,10.5),true)
		foe.set_physics_process(false)
		foe.take_hit(true)
		var fx = get_nodes_in_group("headshot_feedback")[0]
		assert(not fx.full_burst and fx.pieces.is_empty() and foe.comedy_head.visible and foe.head_core==null)
	game.comedy_mode = ""
	game.clear_round()
	await process_frame
	game.reduced_motion = true
	var reduced_foe = game.spawn_enemy(Vector3(18,.05,10.5),true)
	reduced_foe.set_physics_process(false)
	reduced_foe.take_hit(true)
	var reduced_fx = get_nodes_in_group("headshot_feedback")[0]
	assert(reduced_fx.pieces[FX.Shape.CHUNK].size()==3 and not reduced_fx.pieces.has(FX.Shape.BLOOM))
	game.clear_round()
	await process_frame
	assert(game.hud.headshot_confirm==0 and get_nodes_in_group("headshot_feedback").is_empty())
	game.reduced_motion = false
	for i in range(7):
		var fx = FX.new()
		game.effects.add_child(fx)
		fx.setup(game,Vector3(18,1.7,10),Vector3.FORWARD,Vector3.BACK,false)
		assert(fx.full_burst==(i<FX.FULL_LIMIT))
	assert(get_nodes_in_group("headshot_full").size()==6)
	game.start_run()
	await process_frame
	assert(get_nodes_in_group("headshot_feedback").is_empty() and game.hud.headshot_confirm==0)
	print("HEADSHOT_MODE_BUDGET_RESET_PASS")
	game.queue_free()
	for i in range(3):await process_frame
	quit()
