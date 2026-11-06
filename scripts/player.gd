extends CharacterBody3D

var camera: Camera3D
var gun: Node3D
var enabled = true
var pitch = 0.0
var recoil = 0.0
var bob = 0.0
var gun_origin = Vector3(.25,-.32,-.66)
var sensitivity = .0022
var game: Node
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
	gun = load("res://assets/models/rifle.glb").instantiate()
	camera.add_child(gun)
	gun.position = gun_origin
	gun.scale = Vector3.ONE*.70
	for n in gun.find_children("*","MeshInstance3D",true,false):
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and enabled:
		rotate_y(-event.relative.x*sensitivity)
		pitch = clampf(pitch-event.relative.y*sensitivity,-1.35,1.35)

func _physics_process(delta: float) -> void:
	if not enabled:return
	var input = Input.get_vector("left","right","forward","back") if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Vector2.ZERO
	var direction = basis*Vector3(input.x,0,input.y)
	velocity.x = move_toward(velocity.x,direction.x*7.0,35*delta)
	velocity.z = move_toward(velocity.z,direction.z*7.0,35*delta)
	if not is_on_floor():velocity.y -= 22*delta
	elif Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:velocity.y = 7
	move_and_slide()
	if position.y < -8:reset_position()

func _process(delta: float) -> void:
	recoil = move_toward(recoil,0,delta*6)
	bob += delta*minf(Vector2(velocity.x,velocity.z).length(),7)*1.4
	var movement = minf(Vector2(velocity.x,velocity.z).length()/7,1)
	if game and game.reduced_motion:movement = 0
	camera.rotation.x = pitch+recoil*.018
	gun.position = gun_origin+Vector3(sin(bob)*.008,cos(bob*2)*.007,0)*movement+Vector3(0,0,recoil*.06)
	gun.rotation.x = recoil*.04
	if game and game.reload_time>0:
		var reload_phase = sin((1-game.reload_time/game.RELOAD_DURATION)*PI)
		gun.position.y -= reload_phase*.18
		gun.rotation.z = reload_phase*-.25
	else:gun.rotation.z = 0

func reset_position() -> void:
	position = Vector3(0,.05,10.5)
	velocity = Vector3.ZERO
	rotation.y = 0
	pitch = 0
