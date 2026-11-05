extends Node3D

var nav: NavigationRegion3D
var materials: Dictionary = {}
var boxes: Dictionary = {}
var spawn_points: Array[Vector3] = [Vector3(-15,0,-9),Vector3(15,0,-9),Vector3(-15,0,9),Vector3(15,0,9),Vector3(-9,0,12),Vector3(9,0,12)]
const PALETTE = {"sand":"f2d084", "cream":"e5e0d2", "ink":"243440", "red":"b65745", "green":"4d7d70", "purple":"754c87", "blue":"304f9d", "yellow":"e9ba50"}

func _ready() -> void:
	for key in PALETTE:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(PALETTE[key])
		mat.roughness = 0.9
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		materials[key] = mat
		boxes[key] = []
	build()
	batch_boxes()

func solid(pos: Vector3, size: Vector3, color: String, collision: bool = true) -> void:
	boxes[color].append(Transform3D(Basis.from_scale(size),pos))
	if collision:collider(pos,size)

func collider(pos: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	add_child(body)

func model(kind: String, pos: Vector3, yaw: float = 0.0, size: Vector3 = Vector3.ONE) -> Node3D:
	var node = load("res://assets/models/" + kind + ".glb").instantiate()
	add_child(node)
	node.position = pos
	node.rotation.y = yaw
	node.scale = size
	return node

func container(color: String, pos: Vector3, turn: bool = false) -> void:
	model("container_"+color,pos,PI/2 if turn else 0.0)
	collider(pos+Vector3(0,1.45,0),Vector3(2.8,2.9,6) if turn else Vector3(6,2.9,2.8))

func rail(a: Vector3, b: Vector3, color: String = "purple") -> void:
	var n = int(a.distance_to(b)/1.6)+1
	for i in range(n+1):
		var p = a.lerp(b,float(i)/n)
		solid(p+Vector3(0,.6,0),Vector3(.09,1.2,.09),color,false)
	var mid = (a+b)*.5
	var dim = (b-a).abs()+Vector3(.1,.08,.1)
	for h in [.45,1.15]:solid(mid+Vector3(0,h,0),dim,color,false)
	# Thin barrier keeps the player on the platform without complex mesh collisions.
	collider(mid+Vector3(0,.48,0),(b-a).abs()+Vector3(.08,.96,.08))

func stairs(x: float, start_z: float, height: float, length: float, width: float) -> void:
	var count = 16
	for i in range(count):
		var h = height*float(i+1)/count
		var z = start_z-length*(i+.5)/count
		solid(Vector3(x,h*.5,z),Vector3(width,h,length/count),"red",false)
		solid(Vector3(x,h+.015,z+length/count*.4),Vector3(width,.035,.08),"cream",false)
	# Convex ramp: consistent movement and navigation, independent of visual steps.
	var body = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var shape = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	for side in [-1,1]:
		points.append(Vector3(x+side*width*.5,0,start_z))
		points.append(Vector3(x+side*width*.5,0,start_z-length))
		points.append(Vector3(x+side*width*.5,height,start_z-length))
	shape.points = points
	cs.shape = shape
	body.add_child(cs)
	add_child(body)

func sign_text(value: String, pos: Vector3, size: int = 70, yaw: float = 0) -> void:
	var label = Label3D.new()
	label.text = value
	label.font_size = size
	label.pixel_size = .007
	label.modulate = Color("243440")
	label.outline_size = 0
	label.no_depth_test = false
	label.position = pos
	label.rotation.y = yaw
	add_child(label)

func build() -> void:
	solid(Vector3(0,-.25,0),Vector3(38,.5,30),"sand")
	# Cream pavement connects the starting plaza and central shooting lane.
	solid(Vector3(-1,.008,4),Vector3(7,.015,20),"cream",false)
	solid(Vector3(4,.01,8),Vector3(15,.018,4),"cream",false)
	for z in [-4,0,4,8,12]:solid(Vector3(-1,.022,z),Vector3(6.8,.015,.025),"sand",false)
	container("green",Vector3(5,0,-.5),true)
	container("cream",Vector3(5,2.9,-.5),true)
	container("red",Vector3(-6,0,-3))
	container("purple",Vector3(-12,0,6),true)
	container("red",Vector3(12,0,-7))
	container("cream",Vector3(-11,0,-10))
	# Long rear warehouse and elevated deck.
	solid(Vector3(0,1.45,-11),Vector3(13,2.9,4),"yellow")
	solid(Vector3(0,3,-11),Vector3(13.5,.2,4.4),"purple")
	for x in [-5,-1,3]:
		solid(Vector3(x,1.3,-8.97),Vector3(2.0,2.6,.06),"cream",false)
		solid(Vector3(x+1,1.4,-8.92),Vector3(.06,2.8,.08),"ink",false)
	stairs(-8,-2,3,7,2.6)
	stairs(9,-2,3,7,2.6)
	solid(Vector3(-7.1,3,-10),Vector3(2,.2,2),"purple")
	solid(Vector3(7.1,3,-10),Vector3(2,.2,2),"purple")
	rail(Vector3(-6.5,3.1,-8.85),Vector3(6.5,3.1,-8.85))
	rail(Vector3(-6.5,3.1,-13),Vector3(6.5,3.1,-13))
	# Blue lookout frame breaks the skyline.
	for x in [-1.5,1.5]:
		for z in [-12.5,-10]:solid(Vector3(x,4.55,z),Vector3(.15,3,.15),"blue",false)
	solid(Vector3(0,6.1,-11.25),Vector3(4,.22,3.5),"blue",false)
	solid(Vector3(0,4.55,-12.45),Vector3(3,.18,.16),"yellow",false)
	solid(Vector3(0,3.9,-9.9),Vector3(3,.85,.18),"blue",false)
	solid(Vector3(0,6.75,-11.2),Vector3(.06,1.2,.06),"ink",false)
	solid(Vector3(.5,7,-11.2),Vector3(1,.5,.035),"red",false)
	# Foreground cover and recognizable props.
	model("forklift",Vector3(-2,0,-1),-.25)
	collider(Vector3(-2,.7,-1),Vector3(1.7,1.4,2.5))
	for p in [Vector3(-8,0,5),Vector3(-8.9,0,5.5),Vector3(10,0,5),Vector3(2,0,-6)]:
		model("barrel",p)
		collider(p+Vector3(0,.55,0),Vector3(.7,1.1,.7))
	for p in [Vector3(-13,0,-2),Vector3(12,0,3),Vector3(-4,0,10)]:
		solid(p+Vector3(0,.55,0),Vector3(1.5,1.1,1.2),"yellow")
		solid(p+Vector3(0,1.13,0),Vector3(1.56,.08,1.26),"cream",false)
	# Fence: a physical boundary, with airy structure rather than a solid sky-blocking wall.
	for side in [-1,1]:
		collider(Vector3(side*18,2.5,0),Vector3(.18,5,29))
		for z in range(-14,15,3):solid(Vector3(side*17.9,1.4,z),Vector3(.12,2.8,.12),"blue",false)
		for y in [.5,1.4,2.5]:solid(Vector3(side*17.85,y,0),Vector3(.07,.07,28),"blue",false)
		for x in range(-18,19,3):solid(Vector3(x,1.4,side*14),Vector3(.12,2.8,.12),"blue",false)
		for y in [.5,1.4,2.5]:solid(Vector3(0,y,side*14),Vector3(36,.07,.07),"blue",false)
		# Invisible boundary collision; visible short curb.
		var boundary = StaticBody3D.new()
		var cs = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(36,5,.2)
		cs.shape = shape
		boundary.add_child(cs)
		boundary.position = Vector3(0,2.5,side*14)
		add_child(boundary)
	# Exterior scenery is deliberately simple, pale and sparse.
	for i in range(18):
		var x = -29+(i%9)*7
		var z = -22 if i<9 else 23
		model("tree",Vector3(x,0,z),float(i),Vector3.ONE*(.8+float(i%3)*.3))
	for i in range(8):
		model("cloud",Vector3(-30+i*9,10+float(i%3)*2,-30-float(i%2)*8),0,Vector3.ONE*(1.0+float(i%3)*.3))
	for p in [Vector3(-15,0,3),Vector3(14,0,-2),Vector3(-14,0,-12)]:
		solid(p+Vector3(0,2.7,0),Vector3(.1,5.4,.1),"ink",false)
		solid(p+Vector3(.3,5.35,0),Vector3(.7,.12,.15),"cream",false)
	solid(Vector3(-6,2.45,-1.56),Vector3(1.9,.4,.03),"yellow",false)
	sign_text("SECTOR 01",Vector3(-6,2.45,-1.52),45)
	solid(Vector3(0,2.4,-8.87),Vector3(2.5,.5,.04),"yellow",false)
	sign_text("THE SIXTY YARD",Vector3(0,2.4,-8.82),40)

func batch_boxes() -> void:
	for color in boxes:
		if boxes[color].is_empty():continue
		var mesh = BoxMesh.new()
		mesh.material = materials[color]
		var multi = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = boxes[color].size()
		for i in range(multi.instance_count):multi.set_instance_transform(i,boxes[color][i])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = multi
		add_child(instance)

func bake_navigation() -> void:
	nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .5
	mesh.agent_height = 2.0
	mesh.agent_max_climb = .25
	mesh.agent_max_slope = 40
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav.navigation_mesh = mesh
	# Navigation owns the existing collision geometry, so baking uses exactly the walkable world.
	add_child(nav)
	for child in get_children():
		if child is StaticBody3D:child.reparent(nav)
	nav.bake_navigation_mesh(false)
