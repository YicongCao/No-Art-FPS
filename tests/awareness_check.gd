extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	# These checks follow one telegraphed round to its target; misses are covered by enemy_accuracy_check.
	game.enemy_hit_chance = 1.0
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	await check_detection_range()
	game.player.position = Vector3(18,.05,5)
	game.player.rotation.y = 0
	game.player.pitch = 0
	game.hud.go_time = 0
	game.invulnerable = 0
	var rear = stationary(Vector3(18,0,14))
	await get_tree().physics_frame
	assert(game.hud.damage_edge_direction()==Vector2.ZERO,"An enemy behind the player alone does not indicate damage")
	rear.queue_free()
	await get_tree().physics_frame
	var guard = stationary(Vector3(15,0,-2))
	guard.look_at(Vector3(18,guard.position.y,5))
	guard.attack = 0
	await get_tree().physics_frame
	guard.advance_ranged_attack(0,true)
	var aim_duration: float = guard.windup
	assert(aim_duration>=.5 and aim_duration<=1.0 and guard.aim_line.visible)
	var initial_gray: Color = guard.aim_line.material_override.albedo_color
	guard.advance_ranged_attack(aim_duration*.75,true)
	assert(game.bullets.is_empty() and guard.aim_line.material_override.albedo_color.r<initial_gray.r)
	await capture("enemy-aim-line")
	guard.advance_ranged_attack(.01,false)
	assert(guard.windup==0 and not guard.aim_line.visible and game.bullets.is_empty())
	guard.advance_ranged_attack(0,true)
	guard.advance_ranged_attack(guard.windup,true)
	assert(not guard.aim_line.visible and game.bullets.size()==1)
	assert(game.reserve_ranged_aim(guard))
	var second = stationary(Vector3(15,0,-2))
	assert(game.reserve_ranged_aim(second))
	var waiting = stationary(Vector3(15,0,-2))
	assert(not game.reserve_ranged_aim(waiting),"In-flight rounds also occupy an attack slot")
	guard.cancel_ranged_aim()
	assert(game.reserve_ranged_aim(waiting),"Interrupted aims release their slot")
	print("ENEMY_AIM_PASS: duration, darkening, interruption, shot release")
	game.clear_round()
	await check_rear_aim()
	game.health = game.MAX_HEALTH
	game.invulnerable = 0
	# A 16 m shot must arrive in about 0.2 s with a two-metre tracer.
	game.enemy_shoot(Vector3(18,1.1,-11),Vector3(18,1.1,5))
	assert(game.bullets.size()==1 and not game.bullets[0].node.visible)
	game.update_bullets(.1)
	assert(game.health==game.MAX_HEALTH and game.bullets.size()==1)
	var trail = game.bullets[0].node
	assert(trail.mesh is BoxMesh and trail.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert(trail.material_override.albedo_color.is_equal_approx(Color("ffcf3bee")))
	assert(is_equal_approx(trail.global_basis.z.length(),2.0))
	var position: Vector3 = game.bullets[0].position
	game.state = "PAUSED"
	game.update_bullets(.2)
	assert(game.bullets[0].position==position and game.health==game.MAX_HEALTH)
	game.state = "RUNNING"
	game.update_bullets(.11)
	assert(game.health==game.MAX_HEALTH-34 and game.bullets.is_empty())
	game.hud._process(0)
	assert(game.hud.vignette.material.get_shader_parameter("hit_flash")>.9)
	assert(game.hud.damage_edge_direction()==Vector2.ZERO,"On-screen hits use the edge flash without a direction marker")
	await capture("player-hit-flash")
	game.invulnerable = 0
	game.damage_player(12,game.player.camera.to_global(Vector3(-8,0,-1)))
	assert(game.hud.damage_edge_direction().x<-.99)
	await capture("damage-offscreen-left")
	game.invulnerable = 0
	var health_before_rear_shot = game.health
	game.enemy_shoot(Vector3(18,1.1,11),Vector3(18,1.1,5))
	game.update_bullets(.1)
	assert(game.health==health_before_rear_shot-34 and game.hud.damage_edge_direction().y>.99)
	await capture("damage-offscreen-rear")
	game.hud._process(.81)
	assert(game.hud.damage_edge_direction()==Vector2.ZERO,"Direction marker expires with the hit flash")
	print("ENEMY_SHOT_SPEED_PAUSE_PASS")
	# A long physics step still sweeps into cover, never through it.
	game.health = game.MAX_HEALTH
	game.invulnerable = 0
	var cover = StaticBody3D.new()
	var cover_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(14,4,.4)
	cover_shape.shape = box
	cover.add_child(cover_shape)
	game.add_child(cover)
	cover.position = Vector3(18,2,-3)
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.enemy_shoot(Vector3(18,1.1,-11),Vector3(18,1.1,5))
	game.update_bullets(.5)
	assert(game.health==game.MAX_HEALTH and game.bullets.is_empty())
	cover.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.hud.damage = 0
	game.hud.kill_pop = 0
	# A visible tracer can pass to the player's side without causing damage.
	game.enemy_shoot(Vector3(12,1.1,-3),Vector3(18.8,1.1,5))
	game.update_bullets(.065)
	await capture("enemy-yellow-trace")
	game.update_bullets(.09)
	assert(game.health==game.MAX_HEALTH)
	game.start_run()
	assert(game.bullets.is_empty())
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.25).timeout
	print("AWARENESS_CHECK_PASS: aim timing, yellow tracer, hit flash, swept cover collision, near miss, restart cleanup")
	get_tree().quit()

func check_rear_aim() -> void:
	var player = game.player
	var rear = stationary(Vector3(18,0,14))
	rear.look_at(Vector3(18,rear.position.y,5))
	rear.attack = 0
	var waiting = stationary(Vector3(20,0,14))
	waiting.look_at(Vector3(18,waiting.position.y,5))
	await get_tree().physics_frame
	rear.advance_ranged_attack(0,true)
	assert(rear.rear_warned and rear.windup==1.1 and game.rear_aiming_enemy()==rear)
	assert(game.hud.source_edge_direction(rear.ranged_origin()).y>.99)
	assert(game.effects.get_children().any(func(node):return node is AudioStreamPlayer3D and node.stream==game.sounds.enemy_raise))
	assert(not game.reserve_ranged_aim(waiting))
	await capture("rear-aim-warning")
	rear.advance_ranged_attack(1.0,true)
	assert(game.bullets.is_empty() and rear.windup>0)
	rear.advance_ranged_attack(rear.windup,true)
	assert(game.rear_bullet_active() and not game.reserve_ranged_aim(waiting))
	game.invulnerable = 1
	game.update_bullets(.3)
	assert(not game.rear_bullet_active() and game.reserve_ranged_aim(waiting))
	game.clear_round()

	# Both can wind up in front. Turning away grants the earlier shot the rear slot.
	var earlier = stationary(Vector3(18,0,-5))
	var later = stationary(Vector3(19,0,-7))
	for enemy in [earlier,later]:
		enemy.look_at(Vector3(18,enemy.position.y,5))
		enemy.attack = 0
	await get_tree().physics_frame
	earlier.advance_ranged_attack(0,true)
	later.advance_ranged_attack(0,true)
	assert(earlier.windup>0 and later.windup>0)
	earlier.windup = .1
	later.windup = .4
	player.rotation.y = PI
	later.advance_ranged_attack(.05,true)
	assert(later.windup==0 and game.rear_aiming_enemy()==earlier)
	earlier.advance_ranged_attack(.05,true)
	assert(earlier.rear_warned and earlier.windup==1.1 and game.bullets.is_empty())
	player.rotation.y = 0
	game.clear_round()
	print("ENEMY_REAR_AIM_PASS: direction, audio, 1.1 s warning, rear bullet slot, turn arbitration")

func check_detection_range() -> void:
	game.player.position = Vector3(-15,.05,18)
	var guard = game.spawn_enemy(Vector3(18,0,5),false)
	var patrol = game.spawn_enemy(Vector3(30,0,3),false)
	var guard_start: Vector3 = guard.position
	var patrol_start: Vector3 = patrol.position
	var heading: float = guard.rotation.y
	guard.attack = 0
	for i in range(90):await get_tree().physics_frame
	assert(not guard.tracking_player and not patrol.tracking_player)
	assert(guard.position.distance_to(guard_start)<.15 and is_equal_approx(guard.rotation.y,heading))
	assert(patrol.position.distance_to(patrol_start)>1 and game.arena.enemy_zone(patrol.position)=="warehouse")
	assert(game.ranged_aimers.is_empty() and game.bullets.is_empty())

	game.player.position = Vector3(18,.05,21)
	for i in range(45):
		await get_tree().physics_frame
		if guard.windup>0 and guard.position.distance_to(guard_start)>.15:break
	assert(guard.tracking_player and guard.windup>0 and guard.aim_line.visible)
	assert(guard.position.distance_to(guard_start)>.15)
	game.player.position = Vector3(-15,.05,18)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(not guard.tracking_player and guard.windup==0 and not guard.aim_line.visible)
	assert(not game.ranged_aimers.has(guard) and game.bullets.is_empty())
	game.clear_round()
	print("ENEMY_DETECTION_RANGE_PASS: distant idle and patrol, close chase and aim, retreat cancels aim")

func stationary(pos: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(pos,false)
	enemy.set_physics_process(false)
	return enemy

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/local")
	get_viewport().get_texture().get_image().save_png("res://artifacts/local/"+filename+".png")
