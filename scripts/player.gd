extends CharacterBody3D

const WALK_SPEED = 7.0
const SPRINT_SPEED = 10.5
const ComedyFX = preload("res://scripts/comedy_fx.gd")
var camera: Camera3D
var gun: Node3D
var weapon_mode = ""
var weapon_models: Dictionary = {}
var enabled = true
var pitch = 0.0
var recoil = 0.0
var bob = 0.0
var sprinting = false
var sprint_blend = 0.0
var crosshair_offset = Vector2.ZERO
var gun_origin = Vector3(.25,-.32,-.66)
var sensitivity = .0022
var game: Node
var touch_move = Vector2.ZERO
var touch_jump = false
var outline: MeshInstance3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = .35
	var shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = .3
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = .9
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 63
	camera.near = .035
	add_child(camera)
	gun = Node3D.new()
	camera.add_child(gun)
	gun.position = gun_origin
	gun.scale = Vector3.ONE*.70
	set_weapon_style("")

	# Full-screen depth/color edges cover all opaque scenery, actors and the viewmodel.
	# No second mesh shell: hard-edged Blender models keep their seams closed.
	outline = MeshInstance3D.new()
	outline.name = "ComicOutline"
	var quad = QuadMesh.new()
	quad.size = Vector2(2,2)
	outline.mesh = quad
	outline.extra_cull_margin = 16384
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ink = ShaderMaterial.new()
	ink.shader = preload("res://assets/shaders/comic_outline.gdshader")
	ink.render_priority = -128
	outline.material_override = ink
	camera.add_child(outline)
	outline.position.z = -.1

func set_weapon_style(mode: String) -> void:
	if weapon_models.has(weapon_mode):weapon_models[weapon_mode].hide()
	if not weapon_models.has(mode):
		var asset = "res://assets/models/rifle.glb"
		if mode=="comedy":asset = "res://assets/models/comedy/water_blaster.glb"
		if mode=="roach":asset = "res://assets/models/comedy/slipper_launcher.glb"
		var model = load(asset).instantiate()
		gun.add_child(model)
		for part in model.find_children("*","MeshInstance3D",true,false):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not mode.is_empty():
			var sticker = ComedyFX.sprite(ComedyFX.ROACH_ART[0] if mode=="roach" else ComedyFX.SPLAT,.18)
			sticker.position = Vector3(-.146,.028,.09)
			sticker.rotation.y = -PI*.5
			model.add_child(sticker)
		weapon_models[mode] = model
	weapon_mode = mode
	weapon_models[mode].show()

func weapon_muzzle() -> Vector3:
	match weapon_mode:
		"comedy":return gun.to_global(Vector3(0,.072,-.665))
		"roach":return gun.to_global(Vector3(0,.15,-.82))
	return gun.to_global(Vector3(0,.015,-1.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and enabled:
		rotate_y(-event.relative.x*sensitivity)
		pitch = clampf(pitch-event.relative.y*sensitivity,-1.35,1.35)

func _physics_process(delta: float) -> void:
	if not enabled:return
	var keyboard = Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not (game and game.touch_mode)
	var input = Input.get_vector("left","right","forward","back") if keyboard else Vector2.ZERO
	if game and game.touch_mode:input = touch_move
	var wants_sprint = keyboard and input.length_squared()>0 and Input.is_action_pressed("sprint")
	var speed = SPRINT_SPEED if wants_sprint else WALK_SPEED
	var direction = basis*Vector3(input.x,0,input.y)
	velocity.x = move_toward(velocity.x,direction.x*speed,35*delta)
	velocity.z = move_toward(velocity.z,direction.z*speed,35*delta)
	if not is_on_floor():velocity.y -= 22*delta
	elif touch_jump or (Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):velocity.y = 7
	touch_jump = false
	move_and_slide()
	var travel = get_real_velocity()
	sprinting = wants_sprint and is_on_floor() and Vector2(travel.x,travel.z).length()>WALK_SPEED
	if position.y < game.arena.fall_limit:
		if game.rules.respawn_allowed:reset_position()
		else:
			# End the mission at the safety plane, before another fall frame.
			enabled = false
			velocity = Vector3.ZERO
			global_position.y = game.arena.fall_limit
			game.invulnerable = 0
			game.damage_player(1000)
			game.settle_rules()

func _process(delta: float) -> void:
	recoil = move_toward(recoil,0,delta*6)
	var speed = Vector2(velocity.x,velocity.z).length()
	bob += delta*minf(speed,SPRINT_SPEED)*1.4
	var movement = minf(speed/WALK_SPEED,1)
	sprint_blend = move_toward(sprint_blend,1.0 if enabled and sprinting else 0.0,delta*6)
	if game and game.reduced_motion:
		movement = 0
		sprint_blend = 0
	var stride = Vector2(sin(bob),cos(bob*2))
	var sprint_sway = stride*sprint_blend
	crosshair_offset = Vector2(sprint_sway.x*14,-sprint_sway.y*9)
	camera.rotation.x = pitch+recoil*.018
	gun.position = gun_origin+Vector3(stride.x*.008,stride.y*.007,0)*movement+Vector3(sprint_sway.x*.046,sprint_sway.y*.025,recoil*.06)
	gun.rotation.x = recoil*.04+sprint_sway.y*.035
	gun.rotation.z = -sprint_sway.x*.10
	if game and game.reload_time>0:
		var reload_phase = sin((1-game.reload_time/game.RELOAD_DURATION)*PI)
		gun.position.y -= reload_phase*.18
		gun.rotation.z -= reload_phase*.25

func reset_position() -> void:
	global_transform = game.arena.player_start()
	velocity = Vector3.ZERO
	sprinting = false
	sprint_blend = 0
	crosshair_offset = Vector2.ZERO
	rotation.y = global_rotation.y
	pitch = 0
