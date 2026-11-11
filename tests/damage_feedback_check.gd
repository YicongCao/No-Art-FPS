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
	game.hud.go_time = 0
	place_player()
	await get_tree().physics_frame
	var hud = game.hud
	var left = stationary(Vector3(10,0,5))
	var right = stationary(Vector3(26,0,5))
	var ahead = stationary(Vector3(18,0,-4))
	await get_tree().physics_frame

	hit(left)
	hit(right)
	assert(hud.damage_marks.size()==2)
	assert(cos(hud.damage_mark_angle(hud.damage_marks[0]))<-.9,"Left attacker arcs to the left of the crosshair")
	assert(cos(hud.damage_mark_angle(hud.damage_marks[1]))>.9,"Right attacker arcs to the right")
	hit(left)
	assert(hud.damage_marks.size()==2,"Repeated hits refresh one arc per attacker")
	game.player.rotation.y = PI*.5
	await get_tree().physics_frame
	assert(sin(hud.damage_mark_angle(hud.damage_marks[0]))<-.9,"Arcs follow the attacker as the player turns")
	game.player.rotation.y = 0
	await get_tree().physics_frame
	assert(not hud.damage_mark_on_screen(hud.damage_marks[0]))
	hit(ahead)
	assert(hud.damage_marks.size()==3 and hud.damage_mark_on_screen(hud.damage_marks[2]),"Visible attacker gets an overhead mark")
	game.invulnerable = 0
	game.damage_player(20,Vector3(18,1,12),null,"explosion")
	assert(hud.damage_marks.size()==3 and hud.damage_marks[2].kind=="explosion","Only the three newest sources stay")
	await capture("damage-feedback-ring")
	hud._process(1.5)
	assert(hud.damage_marks.is_empty(),"Arcs expire")
	print("DAMAGE_RING_PASS: per-attacker arcs, turn tracking, on-screen marks, explosion style, limit and expiry")

	clear_sounds()
	hit(left)
	var impact = world_sound("hit_impact")
	var eye: Vector3 = game.player.camera.global_position
	assert(impact and (impact.global_position-eye).normalized().dot(Vector3.LEFT)>.95,"Impact sound comes from the attacker side")
	clear_sounds()
	var health: float = game.health
	game.enemy_shoot(Vector3(13,1.7,4.2),Vector3(23,1.7,4.4))
	for _step in range(6):game.update_bullets(.05)
	assert(world_sound("whiz") and game.health==health,"A near miss whizzes past without damage")
	print("DAMAGE_AUDIO_PASS: positioned impact and near-miss whiz")

	ahead.look_at(game.player.global_position)
	ahead.attack = 0
	ahead.advance_ranged_attack(0,true)
	assert(ahead.glint and ahead.glint.visible)
	var early: Color = ahead.aim_line.material_override.albedo_color
	ahead.advance_ranged_attack(ahead.windup*.8,true)
	var late: Color = ahead.aim_line.material_override.albedo_color
	assert(late.r>late.b and late.r-late.b>early.r-early.b,"Aim line warms toward red before the shot")
	ahead.cancel_ranged_aim()
	assert(not ahead.glint.visible)
	left.position = Vector3(10,0,2)
	right.position = Vector3(26,0,2)
	await get_tree().physics_frame
	for side in [left,right]:
		side.look_at(game.player.global_position)
		side.attack = 0
		side.advance_ranged_attack(0,true)
	var threats: Array = hud.side_aim_threats()
	assert(threats.size()==2 and left in threats and right in threats,"Both off-screen side aimers warn")
	for side in [left,right]:side.cancel_ranged_aim()
	print("ENEMY_TELL_PASS: muzzle glint, warming aim line and two side warnings")

	place_player()
	game.health = 20
	game.invulnerable = 0
	game.reduced_motion = false
	game.damage_player(34,left.ranged_origin(),left)
	assert(game.respawn_time>0 and game.killer==left and left.highlighted)
	for _step in range(8):game.update_death_view(.1)
	var view: Vector3 = -game.player.camera.global_basis.z
	var to_killer: Vector3 = game.player.camera.global_position.direction_to(game.killer_focus())
	game.player._process(0)
	view = -game.player.camera.global_basis.z
	assert(absf(view.angle_to(to_killer)-game.DEATH_VIEW_DROP)<.06,"Death view turns to the killer")
	var killer_screen: Vector2 = game.player.camera.unproject_position(game.killer_focus())
	assert(killer_screen.y<get_viewport().get_visible_rect().get_center().y-40,"Killer sits above the respawn skull")
	await capture("damage-feedback-killer")
	game.respawn_time = .01
	game.set_physics_process(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.set_physics_process(false)
	assert(game.respawn_time==0 and game.killer==null and not left.highlighted,"Respawn clears the killer highlight")
	place_player()
	game.health = 10
	game.invulnerable = 0
	game.reduced_motion = true
	var blast := Vector3(18,1,12)
	game.damage_player(30,blast,null,"explosion")
	game.update_death_view(.016)
	game.player._process(0)
	view = -game.player.camera.global_basis.z
	assert(game.killer==null and absf(view.angle_to(game.player.camera.global_position.direction_to(blast))-game.DEATH_VIEW_DROP)<.06,"Reduced motion snaps to the blast")
	game.reduced_motion = false
	game.clear_round()
	assert(game.hud.damage_marks.is_empty() and game.killer==null)
	print("DEATH_VIEW_PASS: turns to killer, gold highlight, blast focus, reduced motion and cleanup")
	get_tree().quit()

func place_player() -> void:
	game.player.position = Vector3(18,.05,5)
	game.player.rotation.y = 0
	game.player.pitch = 0
	game.player.velocity = Vector3.ZERO

func hit(enemy: Node3D) -> void:
	game.invulnerable = 0
	game.health = game.MAX_HEALTH
	game.damage_player(12,enemy.ranged_origin(),enemy)

func stationary(pos: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(pos,false)
	enemy.set_physics_process(false)
	return enemy

func clear_sounds() -> void:
	for voice in game.effects.find_children("*","AudioStreamPlayer3D",false,false):voice.free()

func world_sound(key: String) -> AudioStreamPlayer3D:
	for voice in game.effects.find_children("*","AudioStreamPlayer3D",false,false):
		if voice.stream==game.sounds[key]:return voice
	return null

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/local")
	get_viewport().get_texture().get_image().save_png("res://artifacts/local/"+filename+".png")
