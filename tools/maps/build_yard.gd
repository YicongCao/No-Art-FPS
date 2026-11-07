extends "res://scripts/maps/map_root.gd"

const Barrel = preload("res://scripts/explosive_barrel.gd")
const ContainerRoom = preload("res://scripts/container.gd")
const Destructible = preload("res://scripts/destructible.gd")
var structures: Array[Node3D] = []
var active_structure: Node3D
var scenery_batches: Dictionary = {}
var supported_scenery: Dictionary = {}
var finale_props: Array[Node3D] = []
var finale_hidden: Array[Node3D] = []
var finale_collisions: Dictionary = {}
var finale_batches: Dictionary = {}
var warehouse_structure: Node3D
var deck_structure: Node3D
var navigation_dirty = false
var navigation_baking = false
var original_navigation_mesh: NavigationMesh
var restore_navigation_pending = false
var barrels: Array[Node3D] = []
var containers: Array[Node3D] = []
var nav: NavigationRegion3D
var materials: Dictionary = {}
var boxes: Dictionary = {}
var spawn_points: Array[Vector3] = [Vector3(-23,0,-15),Vector3(11,0,-20),Vector3(-23,0,9),Vector3(11,0,10),Vector3(-10,0,21),Vector3(8,0,21),Vector3(26,0,17),Vector3(30,0,3),Vector3(30,0,-10),Vector3(19,0,-18),Vector3(-4,3.1,-11),Vector3(4,3.1,-11)]
var traffic_lights: Array[Node3D] = []
var traffic_phase = -1
var palms: Array[Node3D] = []
var loungers: Array[Node3D] = []
var pool: Node3D
const PALETTE = {"sand":"d5b471", "pavement":"c4bfb2", "net":"668579", "cream":"e5e0d2", "ink":"243440", "red":"b65745", "green":"4d7d70", "purple":"754c87", "blue":"304f9d", "yellow":"e9ba50", "asphalt":"59626a", "timber":"a97c4b", "light":"fff5d3"}

func enemy_zone(point: Vector3) -> String:
	if point.y>2.2 and point.z<-8 and point.x>-12 and point.x<9.5:return "deck"
	if point.x>24 and point.x<36 and point.z>-16 and point.z<9:return "warehouse"
	return "yard"

func patrol_points(zone: String) -> Array[Vector3]:
	if zone=="deck":return [Vector3(-4,3.1,-11),Vector3(-4,3.1,-20),Vector3(6,3.1,-20),Vector3(4,3.1,-11)]
	return [Vector3(30,0,3),Vector3(30,0,-10)]

func _ready() -> void:
	for key in PALETTE:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(PALETTE[key])
		mat.roughness = 0.9
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		materials[key] = mat
		if key in ["red","cream","yellow","ink"]:
			var painted = ShaderMaterial.new()
			painted.shader = preload("res://assets/shaders/wall_paint.gdshader")
			painted.set_shader_parameter("base_color",Color(PALETTE[key]))
			painted.set_shader_parameter("paint_count",0)
			materials[key] = painted
		boxes[key] = []
	build()
	batch_boxes()

func solid(pos: Vector3, size: Vector3, color: String, collision: bool = true) -> void:
	if active_structure and not active_structure.scenery:
		var visual = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = size
		mesh.material = materials[color]
		visual.mesh = mesh
		visual.position = pos
		add_child(visual)
		active_structure.register(visual)
	else:batch_box(color,Transform3D(Basis.from_scale(size),pos))
	if collision:collider(pos,size)
	elif active_structure and active_structure.scenery and not active_structure.keep_boundary:
		collider(pos,size,16)

func collider(pos: Vector3, size: Vector3, layer: int = 1) -> void:
	var body = StaticBody3D.new()
	body.collision_layer = layer
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	add_child(body)
	if active_structure:
		active_structure.register(body)
		if active_structure.scenery:active_structure.bounds = active_structure.bounds.merge(AABB(pos-size*.5,size))

func explosive_barrel(pos: Vector3) -> void:
	var barrel = Barrel.new()
	barrel.game = game
	barrel.position = pos
	add_child(barrel)
	barrels.append(barrel)

func model(kind: String, pos: Vector3, yaw: float = 0.0, size: Vector3 = Vector3.ONE) -> Node3D:
	var node = load("res://assets/models/" + kind + ".glb").instantiate()
	add_child(node)
	node.position = pos
	node.rotation.y = yaw
	node.scale = size
	if active_structure:
		active_structure.register(node)
		if active_structure.scenery:
			var bounds = AABB()
			for mesh in node.find_children("*","MeshInstance3D",true,false):
				var world_box: AABB = mesh.global_transform*mesh.get_aabb()
				bounds = world_box if not bounds.has_volume() else bounds.merge(world_box)
			if bounds.has_volume():collider(bounds.get_center(),bounds.size,16)
	elif kind!="cloud":finale_props.append(node)
	return node

func structure(region: AABB, color: String) -> Node3D:
	var node = Destructible.new()
	node.game = game
	node.arena = self
	node.bounds = region
	node.palette = Color(PALETTE[color])
	add_child(node)
	structures.append(node)
	return node

func start_scenery(at: Vector3, color: String, boundary: bool = false) -> Node3D:
	var support = active_structure
	active_structure = structure(AABB(at,Vector3.ONE*.01),color)
	active_structure.scenery = true
	active_structure.keep_boundary = boundary
	if support:
		if not supported_scenery.has(support):supported_scenery[support] = []
		supported_scenery[support].append(active_structure)
	return support

func batch_box(color: String, transform: Transform3D) -> void:
	if active_structure and active_structure.scenery:
		if not scenery_batches.has(active_structure):scenery_batches[active_structure] = {}
		var parts: Dictionary = scenery_batches[active_structure]
		if not parts.has(color):parts[color] = []
		parts[color].append(boxes[color].size())
	boxes[color].append(transform)

func container(color: String, pos: Vector3, turn: bool = false) -> void:
	var parent_structure = active_structure
	active_structure = structure(AABB(pos-Vector3(1.4 if turn else 3,0,3 if turn else 1.4),Vector3(2.8,2.9,6) if turn else Vector3(6,2.9,2.8)),color)
	if pos==Vector3(5,0,-.5):active_structure.bounds.size.y = 5.8
	if pos.y>1:
		# A stacked container shares the support's collapse and reset.
		structures.erase(active_structure)
		active_structure.queue_free()
		active_structure = structures[0]
		model("container_"+color,pos,PI/2 if turn else 0.0)
		collider(pos+Vector3(0,1.45,0),Vector3(2.8,2.9,6) if turn else Vector3(6,2.9,2.8))
		active_structure = parent_structure
		return
	var room = ContainerRoom.new()
	room.game = game
	room.paint = materials[color]
	room.position = pos
	room.rotation.y = -PI/2 if turn else 0.0
	add_child(room)
	containers.append(room)
	active_structure.register(room)
	# Shell colliders are baked; hinged doors live outside the static nav geometry.
	for panel in [
		[Vector3(0,-.04,0),Vector3(6,.08,2.8)],
		[Vector3(0,2.85,0),Vector3(6,.1,2.8)],
		[Vector3(-2.95,1.4,0),Vector3(.1,2.8,2.8)],
		[Vector3(0,1.4,-1.35),Vector3(6,2.8,.1)],
		[Vector3(0,1.4,1.35),Vector3(6,2.8,.1)]]:
		var extent: Vector3 = panel[1]
		collider(room.to_global(panel[0]),Vector3(extent.z,extent.y,extent.x) if turn else extent)
	active_structure = parent_structure

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
	if active_structure:active_structure.register(body)
	for side in [-1,1]:
		var edge_x = x+side*(width*.5-.04)
		var bottom = Vector3(edge_x,0,start_z)
		var top = Vector3(edge_x,height,start_z-length)
		for i in range(6):
			var point = bottom.lerp(top,float(i)/5)
			solid(point+Vector3(0,.57,0),Vector3(.09,1.14,.09),"purple",true)
		for y in [.42,1.10]:beam(bottom+Vector3.UP*y,top+Vector3.UP*y,.095,"purple",true)

func wall_paint(artwork: Texture2D, center: Vector3, size: Vector2, colors: Array, normal: Vector3 = Vector3.BACK) -> void:
	# Configure the existing opaque material, so paint and wall never compete for depth.
	for color in colors:
		var surface: ShaderMaterial = materials[color]
		var index = int(surface.get_shader_parameter("paint_count"))
		assert(index<2,"Wall material supports two murals")
		var suffix = "_"+str(index)
		surface.set_shader_parameter("artwork"+suffix,artwork)
		surface.set_shader_parameter("paint_center"+suffix,center)
		surface.set_shader_parameter("paint_size"+suffix,size)
		surface.set_shader_parameter("paint_normal"+suffix,normal)
		surface.set_shader_parameter("paint_count",index+1)

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
	deck_structure = structure(AABB(Vector3(-12,0,-23.6),Vector3(21.5,7.3,22.1)),"purple")
	active_structure = deck_structure
	solid(Vector3(0,1.45,-11),Vector3(13,2.9,4),"yellow")
	# Full-width landing meets the terrace at z=-13.2, including both outer wings.
	solid(Vector3(0,3,-11),Vector3(18,.2,4.4),"purple")
	for x in [-5,-1,3]:
		solid(Vector3(x,1.3,-8.97),Vector3(2.0,2.6,.06),"cream",false)
		solid(Vector3(x+1,1.4,-8.92),Vector3(.06,2.8,.08),"ink",false)
	# Ramp tops meet the actual 3.1 m walking surface at each landing front.
	# The old 3.0 m ramps ended underneath the slab, exposing a vertical lip.
	stairs(-11,-1.5,3.1,6.9,2.6)
	stairs(7.6,-2,3.1,6.8,2.2)
	solid(Vector3(-10.3,3,-9.7),Vector3(2.6,.2,2.6),"purple")
	rail(Vector3(-6.5,3.1,-8.85),Vector3(6.5,3.1,-8.85))
	pool_terrace()
	# Blue lookout frame breaks the skyline.
	for x in [-1.5,1.5]:
		for z in [-12.5,-10]:solid(Vector3(x,4.55,z),Vector3(.15,3,.15),"blue",false)
	solid(Vector3(0,6.1,-11.25),Vector3(4,.22,3.5),"blue",false)
	solid(Vector3(0,4.55,-12.45),Vector3(3,.18,.16),"yellow",false)
	solid(Vector3(0,3.9,-9.9),Vector3(3,.85,.18),"blue",false)
	solid(Vector3(0,6.75,-11.2),Vector3(.06,1.2,.06),"ink",false)
	solid(Vector3(.5,7,-11.2),Vector3(1,.5,.035),"red",false)
	active_structure = null
	# Foreground cover and recognizable props.
	start_scenery(Vector3(-2,0,-1),"yellow")
	model("forklift",Vector3(-2,0,-1),-.25)
	collider(Vector3(-2,.7,-1),Vector3(1.7,1.4,2.5))
	active_structure = null
	for p in [Vector3(-6.75,0,2.834937),Vector3(-8.252952,0,3.085186),Vector3(9.352952,0,7.414814),Vector3(.75,0,-3.834937)]:
		explosive_barrel(p)
	for p in [Vector3(-13,0,-2),Vector3(12,0,3),Vector3(-4,0,10)]:
		start_scenery(p,"yellow")
		solid(p+Vector3(0,.55,0),Vector3(1.5,1.1,1.2),"yellow")
		solid(p+Vector3(0,1.13,0),Vector3(1.56,.08,1.26),"cream",false)
		active_structure = null
	street()
	warehouse()
	for p in [Vector3(-22,0,1),Vector3(-22,0,11),Vector3(11,0,21.5),Vector3(33,0,18),Vector3(33,0,-20),Vector3(-23,0,-21)]:
		start_scenery(p,"green")
		var palm = model("palm",p,float(p.x)*.2)
		palms.append(palm)
		collider(p+Vector3(0,1.7,0),Vector3(.5,3.4,.5))
		active_structure = null
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
		start_scenery(Vector3(x,0,z),"green")
		model("tree",Vector3(x,0,z),float(i),Vector3.ONE*(.8+float(i%3)*.3))
		active_structure = null
	for i in range(8):
		model("cloud",Vector3(-30+i*9,10+float(i%3)*2,-30-float(i%2)*8),0,Vector3.ONE*(1.0+float(i%3)*.3))
	for p in [Vector3(-15,0,3),Vector3(23,0,-19),Vector3(-20,0,-12),Vector3(13,0,-12),Vector3(13,0,8),Vector3(23,0,22),Vector3(-10,0,21),Vector3(-23,0,15)]:
		start_scenery(p,"ink")
		solid(p+Vector3(0,2.7,0),Vector3(.1,5.4,.1),"ink",false)
		solid(p+Vector3(.3,5.35,0),Vector3(.7,.12,.15),"cream",false)
		active_structure = null
	wall_paint(preload("res://assets/graffiti/sector-01.png"),Vector3(-6,1.48,-1.58),Vector2(5.55,2.18),["red"])
	wall_paint(preload("res://assets/graffiti/sixty-yard.png"),Vector3(0,1.48,-8.94),Vector2(7.1,2.35),["cream","yellow","ink"])

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
		instance.set_meta("palette",color)
		if color == "net":instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func pool_terrace() -> void:
	# Extend the landing into a loop around a shallow pool, keeping both stairs clear.
	for slab in [
		[Vector3(-5.5,3,-18.35),Vector3(7,.2,10.3)],
		[Vector3(6.5,3,-18.35),Vector3(5,.2,10.3)],
		[Vector3(1,3,-22.5),Vector3(6,.2,2)],
		[Vector3(1,3,-13.85),Vector3(6,.2,1.3)]]:
		solid(slab[0],slab[1],"cream")
	for x in [-8.6,8.6]:
		for z in [-14,-21.6]:solid(Vector3(x,1.5,z),Vector3(.25,3,.25),"blue")
	rail(Vector3(-9,3.1,-23.5),Vector3(9,3.1,-23.5),"blue")
	for x in [-9,9]:rail(Vector3(x,3.1,-23.5),Vector3(x,3.1,-12.8),"blue")
	pool = model("pool",Vector3(1,3.1,-18))
	# The pool is shallow, has a solid bottom and a ramp under the entry steps.
	collider(Vector3(1,2.56,-18),Vector3(6,.12,7))
	for x in [-1.83,3.83]:collider(Vector3(x,2.84,-18),Vector3(.34,.52,7))
	collider(Vector3(1,2.84,-21.33),Vector3(5.65,.52,.34))
	for x in [-.93,2.93]:collider(Vector3(x,2.84,-14.67),Vector3(1.79,.52,.34))
	var ramp = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var convex = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	for x in [.1,1.9]:
		points.append(Vector3(x,2.6,-16.2))
		points.append(Vector3(x,2.6,-14.45))
		points.append(Vector3(x,3.1,-14.45))
	convex.points = points
	shape.shape = convex
	ramp.add_child(shape)
	add_child(ramp)
	if active_structure:active_structure.register(ramp)
	var water = MeshInstance3D.new()
	water.name = "PoolWater"
	var plane = PlaneMesh.new()
	plane.size = Vector2(5.25,6.25)
	water.mesh = plane
	water.position = Vector3(1,3.015,-18)
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://assets/shaders/pool_water.gdshader")
	water.material_override = shader
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	if active_structure:active_structure.register(water)
	for p in [Vector3(-6.8,3.1,-15.8),Vector3(-6.8,3.1,-19.2),Vector3(7,3.1,-17.4)]:
		var support = start_scenery(p,"blue")
		var chair = model("lounger",p,PI/2 if p.x<0 else -PI/2)
		loungers.append(chair)
		collider(p+Vector3(0,.4,0),Vector3(2.2,.8,.85))
		active_structure = support
	for p in [Vector3(-8,3.1,-17.5),Vector3(8,3.1,-20.5)]:
		var support = start_scenery(p,"cream")
		model("parasol",p)
		collider(p+Vector3(0,1.25,0),Vector3(.12,2.5,.12))
		active_structure = support
	for p in [Vector3(-7.2,3.1,-17.5),Vector3(7,3.1,-19.7)]:
		var support = start_scenery(p,"yellow")
		solid(p+Vector3(0,.38,0),Vector3(.55,.76,.55),"yellow")
		solid(p+Vector3(0,.79,0),Vector3(.8,.08,.8),"cream")
		active_structure = support

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
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav.navigation_mesh = mesh
	# Navigation owns the existing collision geometry, so baking uses exactly the walkable world.
	add_child(nav)
	for child in get_children():
		if child is StaticBody3D:child.reparent(nav)
	nav.bake_navigation_mesh(false)
	original_navigation_mesh = nav.navigation_mesh.duplicate()

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
				batch_box("net",Transform3D(basis,(p+q)*.5))
			u += .8

func beam(a: Vector3, b: Vector3, width: float, color: String, collision: bool = false) -> void:
	var basis = Basis.looking_at(a.direction_to(b))
	var length = a.distance_to(b)
	if active_structure and not active_structure.scenery:
		var visual = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(width,width,length)
		mesh.material = materials[color]
		visual.mesh = mesh
		visual.transform = Transform3D(basis,(a+b)*.5)
		add_child(visual)
		active_structure.register(visual)
	else:batch_box(color,Transform3D(basis*Basis.from_scale(Vector3(width,width,length)),(a+b)*.5))
	if collision:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(width,width,length)
		shape.shape = box
		body.add_child(shape)
		body.transform = Transform3D(basis,(a+b)*.5)
		add_child(body)
		if active_structure:active_structure.register(body)

func fence(a: Vector3, b: Vector3) -> void:
	var support = start_scenery((a+b)*.5,"blue",true)
	var direction = a.direction_to(b)
	var length = a.distance_to(b)
	var count = ceili(length/3)
	for i in range(count+1):
		solid(a.lerp(b,float(i)/count)+Vector3.UP*1.4,Vector3(.12,2.8,.12),"blue",false)
	for h in [.4,2.5]:beam(a+Vector3.UP*h,b+Vector3.UP*h,.07,"blue")
	collider((a+b)*.5+Vector3.UP*2.5,(b-a).abs()+Vector3(.18,5,.18))
	chain_link(a,b)
	active_structure = support

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
		start_scenery(positions[index],"ink")
		var signal_node = model("traffic_light",positions[index],PI if index%2==0 else 0.0)
		traffic_lights.append(signal_node)
		collider(positions[index]+Vector3(0,1.6,0),Vector3(.25,3.2,.25))
		active_structure = null
	for p in [Vector3(-21,0,-18),Vector3(-21,0,-6),Vector3(-21,0,5),Vector3(-21,0,21),Vector3(32,0,21),Vector3(9,0,-21)]:
		start_scenery(p,"green")
		solid(p+Vector3(0,.25,0),Vector3(2.1,.5,2.1),"cream",true)
		model("tree",p+Vector3(0,.5,0),0,Vector3.ONE*1.2)
		collider(p+Vector3(0,1.2,0),Vector3(.4,1.8,.4))
		active_structure = null
	for p in [Vector3(-19.767767,0,-11.232233),Vector3(-21.4,0,-13.5),Vector3(-20.948889,0,-12.111772),Vector3(13.5,0,-17),Vector3(12.165064,0,-18.25),Vector3(23.232233,0,12.767767),Vector3(24.75,0,13.165064),Vector3(32.232231,0,9.232233),Vector3(-9.232233,0,9.032233),Vector3(29,0,-20)]:
		explosive_barrel(p)
	for p in [Vector3(-18,0,2),Vector3(29,0,11),Vector3(9,0,-17)]:
		start_scenery(p,"yellow")
		model("forklift",p,.35)
		collider(p+Vector3(0,.8,0),Vector3(2,1.6,2.6))
		active_structure = null
	# Distribute readable cover without sealing routes to the street.
	container("red",Vector3(-18,0,-16),true)
	container("green",Vector3(-18,0,9))
	container("purple",Vector3(-13,0,-21))

func warehouse() -> void:
	for p in [Vector3(28.5,0,-9.5),Vector3(27.334936,0,-8.95)]:explosive_barrel(p)
	# An actual hollow 12 x 25 m building. West has two five-metre doors, south a six-metre loading bay.
	solid(Vector3(30,.019,-3.5),Vector3(12,.025,25),"pavement",false)
	warehouse_structure = structure(AABB(Vector3(23.6,0,-16.4),Vector3(12.9,5.8,25.8)),"green")
	active_structure = warehouse_structure
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
		var support = start_scenery(p,"timber")
		model("pallet",p)
		for level in range(2):
			for dx in [-.58,.58]:model("crate",p+Vector3(dx,.32+level*1.1,0))
		collider(p+Vector3(0,1.26,0),Vector3(2.3,2.52,1.2))
		active_structure = support
	for p in [Vector3(26.5,0,-5),Vector3(34,0,0)]:
		var support = start_scenery(p,"blue")
		model("pallet",p)
		model("steel_bundle",p+Vector3(0,.35,0))
		model("steel_bundle",p+Vector3(0,1.02,0))
		collider(p+Vector3(0,.85,0),Vector3(1.3,1.7,3.2))
		active_structure = support
	for z in [-11,-3,5]:
		solid(Vector3(30,4.9,z),Vector3(2,.06,.3),"light",false)
		var light = OmniLight3D.new()
		light.position = Vector3(30,4.5,z)
		light.light_color = Color("ffe4ae")
		light.light_energy = .4
		light.omni_range = 7
		light.shadow_enabled = false
		add_child(light)
		active_structure.register(light)
	active_structure = null
	wall_paint(preload("res://assets/graffiti/warehouse.png"),Vector3(23.85,2.75,-2.5),Vector2(6.7,4.05),["cream"],Vector3.LEFT)

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

func restore_structures() -> void:
	var changed = false
	for node in structures:
		changed = changed or node.collapsed
		node.restore()
	if changed:
		restore_navigation_pending = true
		request_navigation_update()

func request_navigation_update() -> void:
	if game.finale_active:return
	navigation_dirty = true

func explode_finale_decor() -> void:
	var centers: Dictionary = {}
	for prop in finale_props:
		if not prop.visible:continue
		finale_hidden.append(prop)
		prop.hide()
		centers[Vector2i(floori(prop.position.x/5),floori(prop.position.z/5))] = prop.position+Vector3.UP
	for node in get_children():
		if node is StaticBody3D and not node.has_meta("structure") and node.position.y>=0:
			finale_collisions[node] = node.collision_layer
			node.collision_layer = 0
			centers[Vector2i(floori(node.position.x/5),floori(node.position.z/5))] = node.position
		elif node is MultiMeshInstance3D:
			var transforms: Dictionary = {}
			for i in range(node.multimesh.instance_count):
				var transform: Transform3D = boxes[node.get_meta("palette")][i]
				if transform.origin.y<=.12:continue
				transforms[i] = transform
				centers[Vector2i(floori(transform.origin.x/5),floori(transform.origin.z/5))] = transform.origin
				node.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ZERO),transform.origin))
			if not transforms.is_empty():finale_batches[node] = transforms
	# All props disappear; nearby pieces share one bounded burst per five-metre cell.
	for point in centers.values():game.finale_explosion(point,1.1,Color("e9ba50"))

func restore_finale_decor() -> void:
	for prop in finale_hidden:prop.show()
	finale_hidden.clear()
	for node in finale_collisions:node.collision_layer = finale_collisions[node]
	finale_collisions.clear()
	for node in finale_batches:
		for i in finale_batches[node]:node.multimesh.set_instance_transform(i,finale_batches[node][i])
	finale_batches.clear()

func _physics_process(_delta: float) -> void:
	if not navigation_dirty or navigation_baking or not nav:return
	navigation_dirty = false
	if restore_navigation_pending:
		# A restart always restores the known intact navigation topology. Keep
		# its immutable startup copy separate from asynchronous runtime baking.
		restore_navigation_pending = false
		nav.navigation_mesh = original_navigation_mesh.duplicate()
		return
	navigation_baking = true
	bake_changed_geometry.call_deferred()

func bake_changed_geometry() -> void:
	# Collision layer changes reach the physics server at frame boundaries.
	# Parsing too early can bake the just-collapsed geometry again on restart.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not nav.bake_finished.is_connected(navigation_finished):nav.bake_finished.connect(navigation_finished)
	# Single-thread Web exports have no background baking worker.
	nav.bake_navigation_mesh(not OS.has_feature("web"))

func navigation_finished() -> void:
	navigation_baking = false

func zone_intact(zone: String) -> bool:
	if zone=="deck":return not deck_structure.collapsed
	if zone=="warehouse":return not warehouse_structure.collapsed
	return true

func opening_actors() -> Array[Dictionary]:
	var actors: Array[Dictionary] = []
	for p in [Vector3(-4,0,1.5),Vector3(11,0,1),Vector3(30,0,3),Vector3(30,0,-10),Vector3(-4,3.1,-11),Vector3(4,3.1,-11)]:
		actors.append({"position":p,"fast":p==Vector3(11,0,1)})
	return actors

func prepare_rooms() -> void:
	for i in [0,2]:containers[i].add_guard()

func respawn_candidates() -> Array[Vector3]:
	return [Vector3(0,.05,10.5),Vector3(-14,.05,1),Vector3(14,.05,8)]

func region_capacity(zone: String, total: int) -> int:
	var reserved = (2 if zone_intact("deck") else 0)+(2 if zone_intact("warehouse") else 0)
	return total-reserved if zone=="yard" else (2 if zone_intact(zone) else 0)
