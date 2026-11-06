extends Node3D

var game: Node
var paint: Material
var doors: Array[Node3D] = []
var shapes: Array[CollisionShape3D] = []
var opening = false
var progress = 0.0
var occupant: Node3D

func _ready() -> void:
	var visual = preload("res://assets/models/container_openable.glb").instantiate()
	add_child(visual)
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh.surface_get_material(0).resource_name=="paint":mesh.material_override = paint
	for door_name in ["DoorLeft","DoorRight"]:
		var pivot = visual.find_child(door_name,true,false)
		doors.append(pivot)
		var body = AnimatableBody3D.new()
		body.sync_to_physics = false
		body.collision_layer = 1
		body.collision_mask = 0
		body.set_meta("container",self)
		pivot.add_child(body)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(.18,2.66,1.31)
		shape.shape = box
		shape.position = Vector3(0,1.4,.675 if doors.size()==1 else -.675)
		body.add_child(shape)
		shapes.append(shape)
	var light = OmniLight3D.new()
	light.position = Vector3(.6,2.3,0)
	light.light_color = Color("ffe4ae")
	light.light_energy = .45
	light.omni_range = 4
	add_child(light)

func reset() -> void:
	opening = false
	progress = 0
	occupant = null
	for door in doors:door.rotation.y = 0
	for shape in shapes:shape.disabled = false

func open() -> void:
	if game.state!="RUNNING" or opening:return
	opening = true
	# Swing outside the doorway; disable moving colliders to avoid pushing actors.
	for shape in shapes:shape.disabled = true
	game.play_world_sound("reload",to_global(Vector3(3,1.4,0)),-10)

func _physics_process(delta: float) -> void:
	if game.state!="RUNNING":return
	if not opening:
		var local_player = to_local(game.player.global_position)
		# Trigger only in front of this doorway, not through its sides or roof.
		if local_player.x>2.7 and local_player.x<6.2 and absf(local_player.z)<1.8 and absf(local_player.y)<1.2:
			var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,to_global(Vector3(3.2,1.4,0)),1)
			if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():open()
	if not opening or progress>=1:return
	progress = minf(1,progress+delta/.7)
	var angle = smoothstep(0,1,progress)*deg_to_rad(110)
	doors[0].rotation.y = angle
	doors[1].rotation.y = -angle
	if progress>=1:
		# Open leaves remain solid and stop bullets, but leave the baked doorway clear.
		for shape in shapes:shape.disabled = false

func add_guard() -> void:
	occupant = game.spawn_enemy(to_global(Vector3(.5,0,0)),false)
	occupant.container_room = self
	occupant.rotation.y = rotation.y-PI*.5
