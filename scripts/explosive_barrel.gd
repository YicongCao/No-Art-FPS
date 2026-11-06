extends StaticBody3D

const RADIUS = 7.5
var game: Node
var visual: Node3D
var paint: StandardMaterial3D
var fuse = -1.0
var spent = false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape = get_node_or_null("CollisionShape3D")
	if shape==null:
		shape = CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		add_child(shape)
	var cylinder = CylinderShape3D.new()
	cylinder.radius = .44
	cylinder.height = 1.24
	shape.shape = cylinder
	shape.position.y = .62
	visual = get_node_or_null("Visual")
	if visual==null:
		visual = preload("res://assets/models/barrel.glb").instantiate()
		visual.name = "Visual"
		add_child(visual)
	paint = StandardMaterial3D.new()
	paint.albedo_color = Color("c34c35")
	paint.roughness = .9
	var band = StandardMaterial3D.new()
	band.albedo_color = Color("e9ba50")
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("barrel") and not "red" in str(mesh.name):mesh.material_override = paint
		elif "red" in mesh.name:mesh.material_override = band

func reset() -> void:
	spent = false
	fuse = -1
	collision_layer = 1
	visual.show()
	visual.scale = Vector3.ONE
	paint.albedo_color = Color("c34c35")

func ignite(delay: float = .65) -> void:
	if game==null or spent or game.state!="RUNNING" or not game.rules.active:return
	if fuse<0:
		fuse = delay
		game.play_world_sound("fuse",global_position+Vector3.UP*.6,-12)
	else:fuse = minf(fuse,delay)

func _physics_process(delta: float) -> void:
	if game==null or game.state!="RUNNING" or not game.rules.active or spent or fuse<0:return
	fuse -= delta
	paint.albedo_color = Color("fff1b7") if int(fuse*18)%2==0 else Color("e84723")
	visual.scale = Vector3.ONE*(1.0+.05*sin(fuse*40))
	if fuse<=0:explode()

func explode() -> void:
	if game==null or spent or game.state!="RUNNING" or not game.rules.active:return
	spent = true
	fuse = -1
	collision_layer = 0
	visual.hide()
	var center = global_position+Vector3.UP*.65
	game.barrel_blast(center,RADIUS,self)
