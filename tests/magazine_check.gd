extends Node

var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Magazine check requires rendered pixels")
	Engine.max_fps = 60
	game.start_run()
	game.set_physics_process(false)
	game.reduced_motion = false
	await check_pixels(20,"magazine-full")
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.player.enabled = false
	game.player.pitch = .8
	for remaining in range(19,-1,-1):
		game.fire_time = 0
		game.shoot()
		assert(game.ammo==remaining)
		assert(game.hud.ejections.size()==1,"Every accepted shot must eject one casing")
		if remaining==19:
			await get_tree().create_timer(.06).timeout
			await capture("magazine-ejection")
		await get_tree().create_timer(.52).timeout
		assert(game.hud.ejections.is_empty(),"Casing animation must expire")
		var filename = "magazine-%02d"%remaining if remaining in [19,8,0] else ""
		await check_pixels(remaining,filename)
	assert(game.reload_time>0,"Empty magazine must automatically reload")
	game.fire_time = 0
	game.shoot()
	assert(game.ammo==0,"Reload cannot fire a phantom round")
	assert(game.hud.ejections.is_empty(),"Rejected shots must not eject casings")
	game.pause_run()
	game.set_physics_process(true)
	var reload_before = game.reload_time
	await get_tree().create_timer(.25).timeout
	assert(game.reload_time==reload_before,"Pause must freeze refill")
	game.menu_action("resume")
	await get_tree().create_timer(1.0).timeout
	assert(game.ammo==20 and game.reload_time<=0)
	await check_pixels(20,"magazine-refilled")
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.reset_position()
	game.player.pitch = .8
	# Check the rendered loading sequence at settled cartridge boundaries.
	for starting in [0,14,19]:
		game.ammo = starting
		game.hud.reset_magazine()
		game.reload_weapon()
		var base_y = game.hud.magazine_rect().position.y
		var missing = 20-starting
		for added in range(missing+1):
			var elapsed = .04+.64*float(added)/missing
			# Tiny offset avoids testing the representational side of a float boundary.
			game.reload_time = game.RELOAD_DURATION-elapsed-.0000001
			await check_pixels(starting+added,"reload-half" if starting==0 and added==10 else "")
			assert(is_equal_approx(game.hud.magazine_rect().position.y,base_y),"No dip until all rounds are inserted")
			assert(game.ammo==starting,"Visual loading must not grant usable ammo early")
			var before = game.rules.shots
			game.fire_time = 0
			game.shoot()
			assert(game.rules.shots==before)
		game.reload_time = .08
		assert(game.hud.magazine_rect().position.y>base_y+8,"Full magazine dips after feeding")
		await check_pixels(20,"reload-seated" if starting==0 else "")
		game.pause_run()
		var held = game.hud.magazine_rect()
		game._physics_process(.2)
		assert(game.hud.magazine_rect()==held,"Pause freezes the seating motion")
		game.menu_action("resume")
		game._physics_process(.04)
		assert(game.reload_time>0 and game.ammo==starting)
		assert(game.hud.magazine_rect().position.y<held.position.y-6,"Return is faster than the dip")
		game._physics_process(.04)
		assert(game.reload_time==0 and game.ammo==20)
		assert(is_equal_approx(game.hud.magazine_rect().position.y,base_y))
	# Inspect a moving round, reduced motion, and cancellation during reload.
	game.ammo = 0
	game.reload_weapon()
	game.reload_time = .9-(.04+.64*5.5/20)
	await capture("reload-inserting")
	game.reduced_motion = true
	game.reload_time = .08
	assert(game.hud.reload_seating_offset()<=3.01)
	game.invulnerable = 0
	game.damage_player(100)
	assert(game.reload_time==0 and game.hud.reload_rounds_fed()==0)
	game.start_run()
	assert(game.reload_time==0 and game.ammo==20)
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.reduced_motion = false
	# Partial reload keeps its remaining rounds until the real reload completes.
	game.set_physics_process(false)
	for i in range(6):
		game.fire_time = 0
		game.shoot()
	game.reload_weapon()
	game.shoot()
	assert(game.hud.ejections.size()==6)
	game.pause_run()
	var animation_before = game.hud.ejections.duplicate()
	await get_tree().create_timer(.2).timeout
	assert(game.hud.ejections==animation_before,"Pause freezes shell animation")
	game.menu_action("resume")
	await get_tree().create_timer(.52).timeout
	await check_pixels(14)
	game.set_physics_process(true)
	await get_tree().create_timer(1.0).timeout
	await check_pixels(20)
	game.start_run()
	game.set_physics_process(false)
	await check_pixels(20)
	# Resize the actual window and render target, retaining the logical HUD layout.
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(.2).timeout
	await check_pixels(20,"magazine-small-window")
	game.begin_running()
	game.clear_round()
	game.player.enabled = false
	game.spawn_time = 999
	game.ammo = 0
	game.reload_weapon()
	for tick in range(53):
		game._physics_process(1.0/60.0)
		await get_tree().physics_frame
		assert(game.ammo==0 and game.reload_time>0,"Reload cannot complete before .9 seconds")
		if tick==23:await capture("reload-small-window")
	game._physics_process(1.0/60.0)
	assert(game.ammo==20 and game.reload_time==0,"Reload completes in exactly 54 ticks")
	await check_pixels(20)
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.25).timeout
	print("MAGAZINE_CHECK_PASS: shot/loading pixel counts, feed/seat/return, firing lock, auto/manual reload, pause, death, restart, 960x540")
	get_tree().quit()

func check_pixels(expected: int, filename: String = "") -> void:
	# A process-frame boundary makes sure the HUD redraw precedes the capture.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var scale = Vector2(image.get_size())/game.hud.size
	var body: Rect2 = game.hud.magazine_rect()
	var rect = Rect2i((body.position+Vector2(42,18)*game.hud.MAGAZINE_SCALE)*scale,Vector2(349,60)*game.hud.MAGAZINE_SCALE*scale)
	var count = count_gold_shapes(image,rect)
	assert(count==expected,"Rendered cartridges: expected %d, found %d"%[expected,count])
	if not filename.is_empty():image.save_png("res://artifacts/"+filename+".png")
	print("MAGAZINE_PIXELS_PASS ",expected)

func capture(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")

func count_gold_shapes(image: Image, rect: Rect2i) -> int:
	# Count occupied column groups, so the cartridge's dark case seam cannot
	# split a single visible round into two connected components.
	var count = 0
	var in_round = false
	for x in range(rect.size.x):
		var gold_pixels = 0
		for y in range(rect.size.y):
			var color = image.get_pixel(rect.position.x+x,rect.position.y+y)
			if color.r>.55 and color.g>.4 and color.b<color.g*.8 and color.r>color.g:
				gold_pixels += 1
		var occupied = gold_pixels>=4
		if occupied and not in_round:count += 1
		in_round = occupied
	return count
