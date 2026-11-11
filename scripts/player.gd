extends CharacterBody3D

const WALK_SPEED = 7.0
const SPRINT_SPEED = 10.5
const AIM_SPEED = WALK_SPEED * .8
const HIP_FOV = 63.0
const AIM_ZOOM = 1.44
const HIP_HALF_TAN = tan(deg_to_rad(HIP_FOV * .5))
const AIM_GUN_ORIGIN = Vector3(0,-.31,-.86)
# Rifle iron sights in model space (tools/build_assets.py): the centre of the
# rear aperture and the top of the front post. Aiming pitches the rifle until
# this line is level and places the post tip on the screen centre, where shots go.
const RIFLE_REAR_APERTURE = Vector3(0,.269,-.17)
const RIFLE_FRONT_POST_TIP = Vector3(0,.205,-.65)
const RIFLE_POST_DISTANCE = .80
# Viewmodel meshes also sit on this render layer; only the camera key light uses it.
const VIEWMODEL_LAYER = 1 << 17
const ComedyFX = preload("res://scripts/comedy_fx.gd")
const Grenade = preload("res://scripts/grenade.gd")
var camera: Camera3D
var body_shape: CollisionShape3D
var gun: Node3D
var throw_hand: Node3D
var held_grenade: Node3D
var weapon_mode = ""
var weapon_models: Dictionary = {}
var enabled = true
var pitch = 0.0
var recoil = 0.0
var bob = 0.0
var sprinting = false
var sprint_blend = 0.0
var crosshair_offset = Vector2.ZERO
var aim_requested := false
var aim_blend := 0.0
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
	body_shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = .3
	cap.height = 1.8
	body_shape.shape = cap
	body_shape.position.y = .9
	add_child(body_shape)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = HIP_FOV
	camera.near = .035
	add_child(camera)
	gun = Node3D.new()
	camera.add_child(gun)
	gun.position = gun_origin
	gun.scale = Vector3.ONE*.70
	add_viewmodel_lights()
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
	set_map_outline(game.arena.map_id)

func add_viewmodel_lights() -> void:
	# Warm key from upper left and a cool rim from behind right, fixed to the
	# camera, so bevel highlights read the same in daylight and dark interiors.
	for spec in [[Vector3(-.55,.42,-.18),Color("fff0dc"),.85,1.6],[Vector3(.62,.12,-1.25),Color("a9c8ff"),1.6,1.5]]:
		var lamp := OmniLight3D.new()
		lamp.position = spec[0]
		lamp.light_color = spec[1]
		lamp.light_energy = spec[2]
		lamp.omni_range = spec[3]
		lamp.light_specular = 1.0
		lamp.light_cull_mask = VIEWMODEL_LAYER
		lamp.shadow_enabled = false
		camera.add_child(lamp)

func set_weapon_style(mode: String) -> void:
	if weapon_models.has(weapon_mode):weapon_models[weapon_mode].hide()
	if not weapon_models.has(mode):
		var asset = "res://assets/models/toy/rifle.glb"
		if mode=="comedy":asset = "res://assets/models/comedy/water_blaster.glb"
		if mode=="roach":asset = "res://assets/models/comedy/slipper_launcher.glb"
		var model = load(asset).instantiate()
		gun.add_child(model)
		for part in model.find_children("*","MeshInstance3D",true,false):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			part.layers |= VIEWMODEL_LAYER
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

func prepare_grenade(mode: String) -> void:
	if is_instance_valid(throw_hand):throw_hand.queue_free()
	throw_hand = Grenade.GLOVE.instantiate()
	throw_hand.name = "ThrowHand"
	camera.add_child(throw_hand)
	held_grenade = Grenade.MODELS[mode].instantiate()
	throw_hand.add_child(held_grenade)
	for part in throw_hand.find_children("*","MeshInstance3D",true,false):
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	animate_grenade_throw()

func animate_grenade_throw() -> void:
	if not is_instance_valid(throw_hand):return
	throw_hand.visible = game.state=="RUNNING" and enabled and game.grenade_throw_time>0
	if not throw_hand.visible:return
	var elapsed: float = game.GRENADE_WINDUP-game.grenade_throw_time
	var swing = smoothstep(0,game.GRENADE_RELEASE,elapsed)
	var follow = smoothstep(game.GRENADE_RELEASE,game.GRENADE_WINDUP,elapsed)
	held_grenade.visible = elapsed<game.GRENADE_RELEASE
	var reach = .55 if game.reduced_motion else 1.0
	throw_hand.position = Vector3(-.32,-.47,-.39)+Vector3(.06,.25,-.07)*swing*reach
	throw_hand.position += Vector3(-.11,-.34,-.11)*follow
	throw_hand.rotation.x = (-.5+.68*swing)*reach
	gun.position.y -= .19*(swing-follow)*reach

func _unhandled_input(event: InputEvent) -> void:
	if game and event.is_action("aim") and not game.touch_mode and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		set_aim_requested(event.is_pressed())
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and enabled:
		turn(-event.relative.x*sensitivity,-event.relative.y*sensitivity)

func set_aim_requested(active: bool) -> void:
	if active and (not enabled or game.state!="RUNNING" or not game.rules.active or game.grenade_throw_time>0):return
	if active==aim_requested:return
	aim_requested = active
	if game.touch_mode and OS.has_feature("web"):
		JavaScriptBridge.eval("window.noArtSetAim(%s)"%("true" if active else "false"))

func reset_aim() -> void:
	set_aim_requested(false)
	aim_blend = 0.0
	camera.fov = HIP_FOV

func aim_zoom() -> float:
	return lerpf(1.0,AIM_ZOOM,smoothstep(0.0,1.0,aim_blend))

func turn(yaw: float, pitch_delta: float) -> void:
	var zoom := aim_zoom()
	rotate_y(yaw/zoom)
	pitch = clampf(pitch+pitch_delta/zoom,-1.35,1.35)

func update_aim(delta: float) -> void:
	var target := 1.0 if aim_requested and enabled and game.reload_time<=0 and game.objective_focus==null else 0.0
	var next := target if game.reduced_motion else move_toward(aim_blend,target,delta/(.12 if target>0.0 else .10))
	if next==aim_blend:return
	aim_blend = next
	camera.fov = rad_to_deg(2.0*atan(HIP_HALF_TAN/aim_zoom()))

func _physics_process(delta: float) -> void:
	if not enabled:return
	var keyboard = Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not (game and game.touch_mode)
	var input = Input.get_vector("left","right","forward","back") if keyboard else Vector2.ZERO
	if game and game.touch_mode:input = touch_move
	var wants_sprint = keyboard and input.length_squared()>0 and Input.is_action_pressed("sprint")
	if wants_sprint:set_aim_requested(false)
	var speed = SPRINT_SPEED if wants_sprint else lerpf(WALK_SPEED,AIM_SPEED,aim_blend)
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
	if game:update_aim(delta)
	recoil = move_toward(recoil,0,delta*6)
	var speed = Vector2(velocity.x,velocity.z).length()
	bob += delta*minf(speed,SPRINT_SPEED)*1.4
	var movement = minf(speed/WALK_SPEED,1)
	sprint_blend = move_toward(sprint_blend,1.0 if enabled and sprinting else 0.0,delta*6)
	if game and game.reduced_motion:
		movement = 0
		sprint_blend = 0
	var stride = Vector2(sin(bob),cos(bob*2))
	var sprint_sway = stride*sprint_blend*(1.0-aim_blend)
	crosshair_offset = Vector2(sprint_sway.x*14,-sprint_sway.y*9)
	camera.rotation.x = pitch+recoil*.018
	var aim_pose := smoothstep(0.0,1.0,aim_blend)
	var aim_origin := AIM_GUN_ORIGIN
	var aim_pitch := 0.0
	if uses_iron_sights():
		var sights := rifle_sight_pose()
		aim_origin = sights.origin
		aim_pitch = sights.basis.get_euler().x
	gun.position = gun_origin.lerp(aim_origin,aim_pose)
	gun.position += Vector3(stride.x*.008,stride.y*.007,0)*movement*lerpf(1.0,.08,aim_pose)
	gun.position += Vector3(sprint_sway.x*.046,sprint_sway.y*.025,recoil*.06)
	gun.rotation.x = recoil*.04+sprint_sway.y*.035+aim_pitch*aim_pose
	gun.rotation.z = -sprint_sway.x*.10
	if game and game.reload_time>0:
		var reload_phase = sin((1-game.reload_time/game.RELOAD_DURATION)*PI)
		gun.position.y -= reload_phase*.18
		gun.rotation.z -= reload_phase*.25
	if game:animate_grenade_throw()

func uses_iron_sights() -> bool:
	return weapon_mode.is_empty()

func rifle_sight_pose() -> Transform3D:
	var line := RIFLE_FRONT_POST_TIP-RIFLE_REAR_APERTURE
	var basis := Basis(Vector3.RIGHT,atan2(-line.y,-line.z))
	var tip := basis*(RIFLE_FRONT_POST_TIP*gun.scale)
	return Transform3D(basis,Vector3(0,0,-RIFLE_POST_DISTANCE)-tip)

func reset_position() -> void:
	teleport_to(game.arena.player_start())

func teleport_to(pose: Transform3D) -> void:
	reset_aim()
	global_transform = pose
	velocity = Vector3.ZERO
	sprinting = false
	sprint_blend = 0
	crosshair_offset = Vector2.ZERO
	pitch = 0
	recoil = 0
	camera.rotation.x = 0

func set_map_outline(map_id: String) -> void:
	var profile: Array = preload("res://scripts/maps/map_lookdev.gd").PROFILES.get(map_id,[.88,.7])
	if map_id=="rain_market":profile=[.34,.08]
	var paint := outline.material_override as ShaderMaterial
	# Toy look: geometry silhouettes only; colour boundaries stay clean paint.
	paint.set_shader_parameter("color_edge_strength",0.0)
	paint.set_shader_parameter("ink_strength",profile[0]*.8)
