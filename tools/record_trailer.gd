extends SceneTree
## Offline gameplay direction. The game owns movement, raycasts, damage, scoring and audio.

const TAKE_TICKS = 15 * 60
const OUTPUT_SIZE = Vector2i(1920, 1080)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Trailer recording requires a renderer")
		quit(1)
		return
	root.content_scale_size = OUTPUT_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(360):
		if game.title_frame_ready:
			break
		await process_frame
	if not game.title_frame_ready or not game.nav_ready or Vector2i(root.get_texture().get_size()) != OUTPUT_SIZE:
		push_error("The trailer needs a ready map and a 1920 × 1080 viewport, got %s" % root.get_texture().get_size())
		quit(1)
		return
	game.qa_mode = true
	game.player.set_process_unhandled_input(false)
	game.reduced_motion = false
	game.set_music_volume(.7)
	seed(204)
	var take = Take.new()
	take.game = game
	take.process_physics_priority = -200
	game.add_child(take)

class Take extends Node:
	var game: Node
	var tick := 0
	var opening_ready := false
	var subject: Node3D
	var other: Node3D
	var prop: Node3D
	var blast_score := 0

	func _ready() -> void:
		if game.session.session_id == "score_attack":
			# Let the authentic title remain visible until FIRE is pressed.
			return
		game.start_run()
		game.begin_running()
		hold_round()
		clear_actors()
		if game.session.session_id == "amusement_park":
			place(Vector3(8,.05,10.2),Vector3(0,2.15,1))
			subject = actor(Vector3(2.8,0,7),true)
			other = actor(Vector3(6,0,-2.7))
		else:
			# Begin the take just before the real 45-second phase boundary.
			game.rules.elapsed = 42.4
			place(Vector3(-8,.05,22),Vector3(1.2,1.35,2))
			subject = actor(Vector3(-6.6,0,14.7),true)
			other = actor(Vector3(2.1,0,13.5))

	func _physics_process(delta: float) -> void:
		if tick == TAKE_TICKS:
			walk(Vector3.ZERO,0)
			var ok = game.rules.kills >= 2
			if game.session.session_id == "last_ferry":
				ok = ok and game.destroy_active and prop.collapsed
			print("TRAILER_TAKE ",game.session.session_id," kills=",game.rules.kills," shots=",game.rules.shots," ticks=",tick)
			if not ok:
				fail("Take did not complete its combat beats")
				return
			print("TRAILER_TAKE_PASS")
			get_tree().quit()
			return
		match game.session.session_id:
			"score_attack":yard(delta)
			"amusement_park":park(delta)
			"last_ferry":ferry(delta)
		tick += 1

	func yard(delta: float) -> void:
		if tick == 54:
			game.hud.fire_button.pressed.emit()
		if game.state != "RUNNING":
			return
		if not opening_ready:
			opening_ready = true
			hold_round()
			for enemy in game.live_enemies():
				enemy.set_physics_process(false)
			subject = game.live_enemies()[0]
			print("TRAILER_FIRE_HANDOFF tick=",tick)
		if tick < 430:
			var gaze = Vector3(-.5,1.7,-2) if tick < 290 else head(subject)
			if tick >= 379:
				gaze = Vector3(-2,1.3,-2)
			move_to(Vector3(1.2,.05,7.4),gaze,2.5,delta)
			if tick == 371:
				fire(head(subject))
				animate_death(subject)
				require_beat(subject.dead,"yard opening headshot")
		elif tick < 645:
			if tick == 430:
				clear_actors()
				place(Vector3(-11,.05,-.5),Vector3(-11,3.4,-12))
				actor(Vector3(3,3.1,-19))
			if tick < 544:
				move_to(Vector3(-11,3.1,-9.9),Vector3(-10.8,4.1,-13),5.5,delta)
			else:
				if tick == 544:
					require_beat(game.player.position.y>2.7,"yard ramp reached upper deck")
				move_to(Vector3(-7.5,3.1,-12.2),Vector3(1.1,3.7,-17.6),3.0,delta)
		else:
			if tick == 645:
				clear_actors()
				place(Vector3(26.8,.05,6.5),Vector3(30,1.65,-6))
				subject = actor(Vector3(30,0,-3.6))
				other = actor(Vector3(31.6,0,-9.8))
			var gaze = head(subject) if tick < 746 else Vector3(30.5,1.65,-11)
			move_to(Vector3(28.6,.05,3.3),gaze,2.4,delta)
			if tick == 735:
				fire(head(subject))
				animate_death(subject)
				require_beat(subject.dead,"warehouse headshot")
			if tick == 815:
				game.reload_weapon()

	func park(delta: float) -> void:
		if tick < 285:
			var gaze = Vector3(0,2.15,1)
			if tick in range(98,164):
				gaze = head(subject)
			move_to(Vector3(7.9,.05,8.6),gaze,2.0,delta)
			if tick == 153:
				fire(head(subject))
				animate_death(subject)
				require_beat(subject.dead,"carousel headshot")
		elif tick < 552:
			if tick == 285:
				clear_actors()
				place(Vector3(-19,.48,9.5),Vector3(-18,1.6,-6))
				subject = actor(Vector3(-15,.43,-1))
				other = actor(Vector3(-22,.43,-7.9))
			var gaze = Vector3(-19,1.4,-8) if tick < 390 or tick > 447 else head(subject)
			move_to(Vector3(-19,-.85,3),gaze,2.8,delta)
			if tick == 439:
				fire(head(subject))
				animate_death(subject)
				require_beat(subject.dead,"skate bowl headshot")
		else:
			if tick == 552:
				clear_actors()
				place(Vector3(7.2,.05,-11.6),Vector3(13,.85,-8))
				prop = game.arena.get_node("Barrel3")
				subject = actor(Vector3(14.9,0,-7.0))
				other = actor(Vector3(12.9,0,-10.2))
				blast_score = game.rules.kills
			var aim_point = prop.global_position+Vector3.UP*.7
			var gaze = aim_point if tick < 727 else Vector3(20,3.9,-8)
			move_to(Vector3(8.5,.05,-11.6) if tick < 730 else Vector3(12,.05,-11.6),gaze,2.3,delta)
			if tick == 648:
				fire(aim_point)
				require_beat(prop.fuse>0,"park barrel ignited by rifle")
			if tick == 702:
				require_beat(prop.spent and subject.dead and other.dead and game.rules.kills>=blast_score+2,
					"barrel blast earned two kills")
				animate_death(subject)
				animate_death(other)

	func ferry(delta: float) -> void:
		if tick < 300:
			var gaze = Vector3(1.2,1.35,2)
			if tick in range(191,255):
				gaze = head(subject)
			move_to(Vector3(-9.3,.05,17.9),gaze,2.0,delta)
			if tick == 242:
				require_beat(game.destroy_active,"ferry crossed DESTROY ALL boundary")
				fire(head(subject))
				animate_death(subject)
				require_beat(subject.dead,"deck fire-round kill")
		elif tick < 620:
			if tick == 300:
				clear_actors()
				prop = game.arena.get_node("PortCrates")
				place(Vector3(-10.4,.05,14.3),prop.world_bounds().get_center())
				subject = actor(Vector3(-7.8,0,7.6))
				other = actor(Vector3(-10.1,0,5.6))
				blast_score = game.rules.kills
			var point: Vector3 = prop.world_bounds().get_center()
			var gaze = point if tick < 510 else Vector3(-8.5,1.5,1)
			move_to(Vector3(-10.5,.05,12.4) if tick < 510 else Vector3(-9.2,.05,10.6),gaze,1.9,delta)
			if tick == 383 or tick == 411:
				fire(point)
				require_beat(prop.hits==(1 if tick == 383 else 2),"fire round hit the crate stack")
			if tick == 446:
				require_beat(prop.collapsed and subject.dead and game.rules.kills>blast_score,
					"destroyed cover blast earned a kill")
				animate_death(subject)
				animate_death(other)
		else:
			if tick == 620:
				clear_actors()
				place(Vector3(-1.6,2.75,2.8),Vector3(-9.2,2.5,-15))
				subject = actor(Vector3(-9,0,-9))
				other = actor(Vector3(-7.8,0,-17))
			var gaze = Vector3(-9.2,2.5,-15) if tick < 774 else Vector3(1.0,2.8,-16)
			move_to(Vector3(-1.6,2.75,-3.8),gaze,2.1,delta)

	func hold_round() -> void:
		game.spawn_time = 999.0
		game.invulnerable = 999.0
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	func clear_actors() -> void:
		for enemy in game.enemies.get_children():
			game.enemies.remove_child(enemy)
			enemy.queue_free()

	func actor(at: Vector3, fast: bool = false) -> Node3D:
		var enemy: Node3D = game.spawn_enemy(at,fast)
		enemy.set_physics_process(false)
		var player_at: Vector3 = game.player.position
		enemy.look_at(Vector3(player_at.x,enemy.position.y,player_at.z))
		return enemy

	func head(enemy: Node3D) -> Vector3:
		return enemy.position+Vector3.UP*1.7

	func animate_death(enemy: Node3D) -> void:
		if enemy.dead:
			enemy.set_physics_process(true)

	func place(at: Vector3, gaze: Vector3) -> void:
		game.player.position = at
		game.player.velocity = Vector3.ZERO
		game.player.recoil = 0
		walk(Vector3.ZERO,0)
		look(gaze,1)

	func move_to(destination: Vector3, gaze: Vector3, speed: float, delta: float) -> void:
		look(gaze,1.0-exp(-7.5*delta))
		var offset: Vector3 = destination-game.player.position
		offset.y = 0
		walk(offset,minf(speed,offset.length()*3.4))

	func walk(direction: Vector3, speed: float) -> void:
		var local: Vector3 = game.player.global_basis.inverse()*direction.normalized()*speed/game.player.WALK_SPEED
		for input in [["left",-local.x],["right",local.x],["forward",-local.z],["back",local.z]]:
			if input[1]>.01:
				Input.action_press(input[0],input[1])
			else:
				Input.action_release(input[0])

	func look(point: Vector3, weight: float) -> void:
		var direction: Vector3 = game.player.camera.global_position.direction_to(point)
		game.player.rotation.y = lerp_angle(game.player.rotation.y,atan2(-direction.x,-direction.z),weight)
		game.player.pitch = lerpf(game.player.pitch,asin(direction.y),weight)
		game.player.camera.rotation.x = game.player.pitch

	func fire(point: Vector3) -> void:
		look(point,1)
		game.shoot()

	func require_beat(ok: bool, label: String) -> void:
		if not ok:
			fail(label)
		else:
			print("TRAILER_BEAT_PASS ",label," tick=",tick)

	func fail(label: String) -> void:
		push_error("Trailer: %s at tick %d, player=%s" % [label,tick,game.player.position])
		get_tree().quit(1)
