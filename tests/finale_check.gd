extends Node
const CombatFX = preload("res://scripts/combat_fx.gd")

var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.spawn_time = 999
	game.rules.elapsed = 0
	for _tick in range(3539):game.rules.tick(1.0/60.0)
	game._physics_process(0)
	assert(not game.finale_active,"No global blast before the last second")
	var score = game.rules.kills
	var alive = game.live_enemies().size()
	assert(alive>0)
	game.pause_run()
	game._physics_process(.2)
	assert(not game.finale_active and game.rules.kills==score)
	game.menu_action("resume")
	game.player.enabled = false
	game._physics_process(1.0/60.0)
	assert(game.finale_active and is_equal_approx(game.rules.remaining(),1),"Tick 3540 starts the blast")
	assert(game.live_enemies().is_empty() and game.rules.kills==score+alive)
	for building in game.arena.structures:assert(building.collapsed)
	for barrel in game.arena.barrels:assert(barrel.spent and barrel.collision_layer==0)
	assert(not game.arena.finale_hidden.is_empty() and not game.arena.finale_batches.is_empty(),"Finale decor: props=%d hidden=%d batches=%d"%[game.arena.finale_props.size(),game.arena.finale_hidden.size(),game.arena.finale_batches.size()])
	var population = game.effects.get_child_count()
	game._physics_process(0)
	assert(game.effects.get_child_count()==population and game.rules.kills==score+alive,"The global blast cannot repeat")
	var fx = game.effects.get_children().filter(func(node):return node is CombatFX)[0]
	game.pause_run()
	var held = fx.age
	await get_tree().create_timer(.15).timeout
	assert(fx.age==held)
	game.menu_action("resume")
	game.player.enabled = false
	for tick in range(59):
		game._physics_process(1.0/60.0)
		await get_tree().physics_frame
		assert(game.state=="RUNNING")
		if tick==25:await capture("finale-blast")
	game._physics_process(1.0/60.0)
	assert(game.state=="RESULTS" and game.rules.remaining()==0 and not game.rules.active)
	var final_score = game.rules.kills
	for _frame in range(8):await get_tree().process_frame
	var held_age = fx.age
	var held_camera = game.player.camera.global_transform
	var image: Image
	if DisplayServer.get_name()!="headless":
		assert(game.hud.results_frame!=null and not game.hud.results_frame_pending)
		await capture("finale-results")
		image = get_viewport().get_texture().get_image()
	await get_tree().create_timer(.4).timeout
	game._physics_process(.5)
	game.start_finale()
	assert(fx.age==held_age and game.player.camera.global_transform==held_camera)
	assert(game.rules.kills==final_score)
	if image:
		await RenderingServer.frame_post_draw
		assert(image.compute_image_metrics(get_viewport().get_texture().get_image(),false)["max"]==0,"Results must remain pixel-identical")
	game.start_run()
	assert(not game.finale_active and game.hud.results_frame==null and game.frozen_process_modes.is_empty())
	assert(game.rules.kills==0 and game.effects.get_child_count()==0)
	for prop in game.arena.finale_props:assert(prop.visible)
	for building in game.arena.structures:
		assert(not building.collapsed)
		for body in building.collision_states:assert(body.collision_layer==building.collision_states[body])
	for barrel in game.arena.barrels:assert(not barrel.spent and barrel.collision_layer==1)
	assert(game.arena.finale_collisions.is_empty() and game.arena.finale_batches.is_empty())
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("FINALE_CHECK_PASS: exact last-second boundary, all enemies/structures/barrels/props, one-shot score, pause, deadline, frozen pixels/camera/FX, full reset")
	get_tree().quit()

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
