extends Node
## Authored cuts through the actual arena. Shots, destruction and scoring use game code.

var game: Node
var frame := 0
var yard_targets: Array[Node3D] = []
var warehouse_target: Node3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Demo capture requires rendered Movie Maker output")
		get_tree().quit(1)
		return
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.music.play()
	game.player.enabled = false
	game.invulnerable = 999.0
	game.spawn_time = 999.0
	for position in [Vector3(-2,0,11),Vector3(2,0,10),Vector3(0,0,8)]:
		yard_targets.append(stage_target(position))
	warehouse_target = stage_target(Vector3(30,0,-5))
	stage_target(Vector3(-6,0,-3))
	stage_target(Vector3(31,0,2))
	pose(Vector3(-11,1.8,15),Vector3(-6,1.5,-2))

func _physics_process(_delta: float) -> void:
	var t := frame / 60.0
	if t < 4.0:
		pose(Vector3(-11,1.8,15).lerp(Vector3(-8,1.8,13),t/4.0),
			Vector3(-6,1.5,-2).lerp(Vector3(-.5,1.5,-5),t/4.0))
	elif t < 11.0:
		var eye := Vector3(0,1.7,20).lerp(Vector3(-1,1.7,16), (t-4.0)/7.0)
		var index := mini(2,maxi(0,int((frame-260)/43.0)))
		pose(eye,yard_targets[index].position+Vector3.UP*1.70 if frame < 387 else Vector3(-2,1.5,-4))
		if frame in [280,323,366]:
			game.shoot()
			yard_targets[index].set_physics_process(true)
		if frame == 420:game.reload_weapon()
	elif t < 14.0:
		pose(Vector3(-11,1.7,1).lerp(Vector3(-11,4.75,-9.6),(t-11.0)/3.0),
			Vector3(-9.9,3.9,-12))
	elif t < 17.5:
		pose(Vector3(-6,4.75,-12.9).lerp(Vector3(-4.7,4.75,-15),(t-14.0)/3.5),
			Vector3(1.5,3.4,-18.5))
	elif t < 21.0:
		pose(Vector3(30,1.7,8).lerp(Vector3(30,1.7,3),(t-17.5)/3.5),
			warehouse_target.position+Vector3.UP*1.70 if frame < 1165 else Vector3(31,3.0,-13))
		if frame == 1150:
			game.shoot()
			warehouse_target.set_physics_process(true)
	elif t < 25.2:
		if frame == 1260:game.rules.elapsed = 45.0
		pose(Vector3(-6,1.7,5.5).lerp(Vector3(-7,1.7,6.5),(t-21.0)/4.2),Vector3(-6,1.4,-1.6))
		if frame in [1365,1380,1395]:game.shoot()
	elif frame < 1610:
		pose(Vector3(18,1.7,-2.5),Vector3(24,2.6,-2.5))
		if frame in [1520,1535,1550]:game.shoot()
	elif frame == 1610:
		if not (game.arena.structures[1].collapsed and game.arena.warehouse_structure.collapsed):
			push_error("Scripted burning shots failed to collapse both structures")
			get_tree().quit(1)
			return
		pose(Vector3(10,5.8,14),Vector3(0,1.3,-6))
		# The regular tick triggers the blast and results after this cut.
		game.rules.elapsed = 58.0
	if frame >= 1800:
		if not (game.destroy_active and game.finale_active and game.state == "RESULTS" and game.rules.headshots >= 3):
			push_error("DEMO_CAPTURE_FAILED shots=%d hits=%d headshots=%d state=%s" % [game.rules.shots,game.rules.hits,game.rules.headshots,game.state])
			get_tree().quit(1)
			return
		print("DEMO_CAPTURE_PASS shots=%d headshots=%d kills=%d" % [game.rules.shots,game.rules.headshots,game.rules.kills])
		get_tree().quit()
	frame += 1

func stage_target(position: Vector3) -> Node3D:
	var enemy: Node3D = game.spawn_enemy(position,false)
	enemy.set_physics_process(false)
	return enemy

func pose(eye: Vector3, target: Vector3) -> void:
	var direction := eye.direction_to(target)
	game.player.position = eye-Vector3.UP*1.65
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
