extends Node3D

var nav: NavigationRegion3D
var materials: Dictionary = {}
var boxes: Dictionary = {}
var spawn_points: Array[Vector3] = [Vector3(-23,0,-15),Vector3(11,0,-20),Vector3(-23,0,9),Vector3(11,0,10),Vector3(-10,0,21),Vector3(8,0,21),Vector3(26,0,17),Vector3(30,0,3),Vector3(30,0,-10),Vector3(19,0,-18),Vector3(-4,3.1,-11),Vector3(4,3.1,-11)]
var traffic_lights: Array[Node3D] = []
var traffic_phase = -1
const PALETTE = {"sand":"d5b471", "pavement":"c4bfb2", "net":"668579", "cream":"e5e0d2", "ink":"243440", "red":"b65745", "green":"4d7d70", "purple":"754c87", "blue":"304f9d", "yellow":"e9ba50", "asphalt":"59626a", "timber":"a97c4b", "light":"fff5d3"}

func enemy_zone(point: Vector3) -> String:
	if point.y>2.5 and point.z<-8 and point.x>-12 and point.x<9:return "deck"
	if point.x>24 and point.x<36 and point.z>-16 and point.z<9:return "warehouse"
	return "yard"

func patrol_points(zone: String) -> Array[Vector3]:
	if zone=="deck":return [Vector3(-4,3.1,-11),Vector3(4,3.1,-11)]
	return [Vector3(30,0,3),Vector3(30,0,-10)]

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
	for h in [.45,1.15]:solid(mid+Vector3(0,h,0),dim,color,true)


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
	for side in [-1,1]:
		var edge_x = x+side*(width*.5-.04)
		var bottom = Vector3(edge_x,0,start_z)
		var top = Vector3(edge_x,height,start_z-length)
		for i in range(6):
			var point = bottom.lerp(top,float(i)/5)
			solid(point+Vector3(0,.57,0),Vector3(.09,1.14,.09),"purple",true)
		for y in [.42,1.10]:beam(bottom+Vector3.UP*y,top+Vector3.UP*y,.095,"purple",true)

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
	solid(Vector3(6,-.25,0),Vector3(64,.5,48),"sand")
	# Cream pavement connects the starting plaza and central shooting lane.
	solid(Vector3(-1,.008,4),Vector3(7,.015,20),"pavement",false)
	solid(Vector3(4,.01,8),Vector3(15,.018,4),"pavement",false)
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
	stairs(-11,-1.5,3,7,2.6)
	stairs(7.6,-2,3,7,2.2)
	solid(Vector3(-8.8,3,-9.7),Vector3(5.6,.2,2.6),"purple")
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
	street()
	warehouse()
	# Expanded perimeter has no collision walls across the old map boundary.
	fence(Vector3(-26,0,-24),Vector3(38,0,-24))
	fence(Vector3(-26,0,24),Vector3(38,0,24))
	fence(Vector3(-26,0,-24),Vector3(-26,0,24))
	fence(Vector3(38,0,-24),Vector3(38,0,24))
	# Exterior scenery is deliberately simple, pale and sparse.
	solid(Vector3(0,-.8,0),Vector3(120,1,120),"cream",false)
	for i in range(18):
		var x = -31+(i%9)*9
		var z = -30 if i<9 else 31
		model("tree",Vector3(x,0,z),float(i),Vector3.ONE*(.8+float(i%3)*.3))
	for i in range(8):
		model("cloud",Vector3(-30+i*9,10+float(i%3)*2,-30-float(i%2)*8),0,Vector3.ONE*(1.0+float(i%3)*.3))
	for p in [Vector3(-15,0,3),Vector3(23,0,-19),Vector3(-20,0,-12),Vector3(13,0,-12),Vector3(13,0,8),Vector3(23,0,22),Vector3(-10,0,21),Vector3(-23,0,15)]:
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
		if color == "net":instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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

func chain_link(a: Vector3, b: Vector3) -> void:
	var direction = a.direction_to(b)
	var length = a.distance_to(b)
	var height = 2.15
	for sign in [-1.0,1.0]:
		var u = -height
		while u<length:
			var low = maxf(0,-u)
			var high = minf(height,length-u)
			if high>low:
				var p = a+direction*(u+low)+Vector3.UP*(.3+(low if sign>0 else height-low))
				var q = a+direction*(u+high)+Vector3.UP*(.3+(high if sign>0 else height-high))
				var basis = Basis.looking_at(p.direction_to(q))*Basis.from_scale(Vector3(.018,.018,p.distance_to(q)))
				boxes["net"].append(Transform3D(basis,(p+q)*.5))
			u += .8

func beam(a: Vector3, b: Vector3, width: float, color: String, collision: bool = false) -> void:
	var basis = Basis.looking_at(a.direction_to(b))
	var length = a.distance_to(b)
	boxes[color].append(Transform3D(basis*Basis.from_scale(Vector3(width,width,length)),(a+b)*.5))
	if collision:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(width,width,length)
		shape.shape = box
		body.add_child(shape)
		body.transform = Transform3D(basis,(a+b)*.5)
		add_child(body)

func fence(a: Vector3, b: Vector3) -> void:
	var direction = a.direction_to(b)
	var length = a.distance_to(b)
	var count = ceili(length/3)
	for i in range(count+1):
		solid(a.lerp(b,float(i)/count)+Vector3.UP*1.4,Vector3(.12,2.8,.12),"blue",false)
	for h in [.4,2.5]:beam(a+Vector3.UP*h,b+Vector3.UP*h,.07,"blue")
	collider((a+b)*.5+Vector3.UP*2.5,(b-a).abs()+Vector3(.18,5,.18))
	chain_link(a,b)

func street() -> void:
	# Two streets form a T junction: low curbs are visual, so movement stays step-free.
	solid(Vector3(18,.025,0),Vector3(8,.03,48),"asphalt",false)
	solid(Vector3(6,.028,17),Vector3(64,.03,7),"asphalt",false)
	for x in [13.8,22.2]:
		solid(Vector3(x,.09,-5.25),Vector3(.25,.18,37.5),"cream",false)
		solid(Vector3(x,.09,22.25),Vector3(.25,.18,3.5),"cream",false)
	for z in [13.3,20.7]:
		solid(Vector3(-6,.09,z),Vector3(39.6,.18,.25),"cream",false)
		solid(Vector3(30,.09,z),Vector3(15.6,.18,.25),"cream",false)
	for z in range(-22,10,4):solid(Vector3(18,.049,z),Vector3(.12,.014,1.8),"yellow",false)
	for x in range(-23,35,4):
		if x<13 or x>23:solid(Vector3(x,.05,17),Vector3(1.8,.014,.12),"yellow",false)
	for i in range(8):solid(Vector3(14.5+i,.05,11.5),Vector3(.5,.014,2.7),"cream",false)
	for i in range(7):solid(Vector3(25,.055,14+i),Vector3(2.7,.014,.5),"cream",false)
	solid(Vector3(18,.052,9.7),Vector3(7.6,.015,.22),"cream",false)
	for index in range(4):
		var positions = [Vector3(13,0,9.2),Vector3(23,0,21.5),Vector3(23,0,-12),Vector3(13,0,-4)]
		var signal_node = model("traffic_light",positions[index],PI if index%2==0 else 0.0)
		traffic_lights.append(signal_node)
		collider(positions[index]+Vector3(0,1.6,0),Vector3(.25,3.2,.25))
	for p in [Vector3(-21,0,-18),Vector3(-21,0,-6),Vector3(-21,0,5),Vector3(-21,0,21),Vector3(32,0,21),Vector3(9,0,-21)]:
		solid(p+Vector3(0,.25,0),Vector3(2.1,.5,2.1),"cream",true)
		model("tree",p+Vector3(0,.5,0),0,Vector3.ONE*1.2)
		collider(p+Vector3(0,1.2,0),Vector3(.4,1.8,.4))
	for p in [Vector3(-18,0,-13),Vector3(-18.9,0,-13.5),Vector3(-19.5,0,-12.5),Vector3(11,0,-17),Vector3(10,0,-17),Vector3(25,0,11),Vector3(26,0,11),Vector3(34,0,11),Vector3(-11,0,10.8),Vector3(29,0,-20)]:
		model("barrel",p)
		collider(p+Vector3(0,.6,0),Vector3(.78,1.2,.78))
	for p in [Vector3(-18,0,2),Vector3(29,0,11),Vector3(9,0,-17)]:
		model("forklift",p,.35)
		collider(p+Vector3(0,.8,0),Vector3(2,1.6,2.6))
	# Distribute readable cover without sealing routes to the street.
	container("red",Vector3(-18,0,-16),true)
	container("green",Vector3(-18,0,9))
	container("purple",Vector3(4,0,-20))

func warehouse() -> void:
	# An actual hollow 12 x 25 m building. West has two five-metre doors, south a six-metre loading bay.
	solid(Vector3(30,.019,-3.5),Vector3(12,.025,25),"pavement",false)
	solid(Vector3(36,2.7,-3.5),Vector3(.3,5.4,25),"green")
	solid(Vector3(30,2.7,-16),Vector3(12,5.4,.3),"green")
	for segment in [Vector2(-16,-11.5),Vector2(-6.5,1.5),Vector2(6.5,9)]:
		solid(Vector3(24,2.7,(segment.x+segment.y)*.5),Vector3(.3,5.4,segment.y-segment.x),"cream")
	for z in [-9.0,4.0]:
		solid(Vector3(24,4.65,z),Vector3(.35,1.5,5),"green")
		for dz in [-2.5,2.5]:solid(Vector3(23.8,1.9,z+dz),Vector3(.14,3.8,.16),"yellow")
	for x in [25.5,34.5]:solid(Vector3(x,2.7,9),Vector3(3,5.4,.3),"green")
	solid(Vector3(30,4.65,9),Vector3(6,1.5,.3),"cream")
	for x in [27,33]:solid(Vector3(x,1.9,9.2),Vector3(.16,3.8,.14),"yellow")
	# Roof sections leave a long skylight; columns and rafters remain visible from inside.
	for x in [26.1,33.9]:solid(Vector3(x,5.5,-3.5),Vector3(4.2,.22,25.4),"blue")
	for z in [-15,-9,-3,3,8]:
		solid(Vector3(30,5.15,z),Vector3(12,.18,.18),"ink",false)
		for x in [24.35,35.65]:solid(Vector3(x,2.7,z),Vector3(.18,5.4,.18),"blue",true)
	for p in [Vector3(27,0,-13),Vector3(33.5,0,-12),Vector3(33,0,-4),Vector3(27,0,-2),Vector3(33,0,4)]:
		model("pallet",p)
		for level in range(2):
			for dx in [-.58,.58]:model("crate",p+Vector3(dx,.32+level*1.1,0))
		collider(p+Vector3(0,1.26,0),Vector3(2.3,2.52,1.2))
	for p in [Vector3(26.5,0,-5),Vector3(34,0,0)]:
		model("pallet",p)
		model("steel_bundle",p+Vector3(0,.35,0))
		model("steel_bundle",p+Vector3(0,1.02,0))
		collider(p+Vector3(0,.85,0),Vector3(1.3,1.7,3.2))
	for z in [-11,-3,5]:
		solid(Vector3(30,4.9,z),Vector3(2,.06,.3),"light",false)
		var light = OmniLight3D.new()
		light.position = Vector3(30,4.5,z)
		light.light_color = Color("ffe4ae")
		light.light_energy = .4
		light.omni_range = 7
		light.shadow_enabled = false
		add_child(light)
	solid(Vector3(30,4.55,9.18),Vector3(3.6,.55,.06),"yellow",false)
	sign_text("WAREHOUSE",Vector3(30,4.55,9.23),55)

func _process(_delta: float) -> void:
	# Static scenery remains quiet; only the traffic lenses change every few seconds.
	var phase = int(Time.get_ticks_msec()/1000)%12
	var key = 0 if phase<5 else (1 if phase<6 else (2 if phase<11 else 1))
	if key==traffic_phase:return
	traffic_phase = key
	for index in range(traffic_lights.size()):
		for color in ["red","yellow","green"]:
			var lamp = traffic_lights[index].find_child("lamp_"+color,true,false)
			if lamp==null:continue
			var active = (color=="yellow" and key==1) or (color=="green" and key==(0 if index%2==0 else 2)) or (color=="red" and key==(2 if index%2==0 else 0))
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(PALETTE[color]) if active else Color("253039")
			if active:
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lamp.material_override = material
