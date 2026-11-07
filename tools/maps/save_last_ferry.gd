extends SceneTree

const Ferry = preload("res://scripts/maps/last_ferry.gd")
const Destructible = preload("res://scripts/destructible.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const MODEL_PATH = "res://assets/models/ferry/"
const COVER_SIZES = {
	"crates_teal":Vector3(2.83,1.38,2.16), "crates_purple":Vector3(2.83,1.38,2.16),
	"locker":Vector3(1.73,1.98,1.43), "lifeboat":Vector3(1.8,1.07,4.72),
}
var ferry: Node3D

func _initialize() -> void:
	generate.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node)
	node.owner = ferry
	return node

func model(parent: Node3D, label: String, asset: String, position: Vector3 = Vector3.ZERO) -> Node3D:
	var instance = load(MODEL_PATH+asset+".glb").instantiate()
	instance.position = position
	return add(parent,instance,label)

func collision(parent: Node3D, shape: Shape3D, position: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = position
	body.collision_mask = 0
	add(parent,body,"Body%d"%parent.get_child_count())
	var collider = CollisionShape3D.new()
	collider.shape = shape
	add(body,collider,"Collision")
	return body

func box(parent: Node3D, position: Vector3, size: Vector3) -> StaticBody3D:
	var shape = BoxShape3D.new()
	shape.size = size
	return collision(parent,shape,position)

func floor_prism(parent: Node3D, top: PackedVector3Array, depth: float) -> void:
	var shape = ConvexPolygonShape3D.new()
	var points = top.duplicate()
	for point in top:points.append(point-Vector3.UP*depth)
	shape.points = points
	collision(parent,shape)

func rail(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var offset = Vector3(b.z-a.z,0,a.x-b.x).normalized()*.095
	var height = Vector3.UP*1.85
	var shape = ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([a-offset,a+offset,b-offset,b+offset,
		a-offset+height,a+offset+height,b-offset+height,b+offset+height])
	collision(parent,shape)

func add_deck(outline: Array) -> void:
	model(ferry,"Hull","deck")
	var top = PackedVector3Array()
	for edge in outline:top.append(Vector3(edge[0],0,edge[1]))
	floor_prism(ferry,top,.42)
	for i in range(top.size()):
		var a = top[i]*Vector3(.981,1,.985)
		var b = top[(i+1)%top.size()]*Vector3(.981,1,.985)
		rail(ferry,a,b)

func add_bridge(layout: Dictionary) -> void:
	model(ferry,"Catwalk","bridge")
	var x: float = layout.x
	var height: float = layout.height
	var top = PackedVector3Array()
	for edge in layout.outline:top.append(Vector3(x+edge[0],height,edge[1]))
	floor_prism(ferry,top,.36)
	for i in range(top.size()):
		var a = top[i]
		var b = top[(i+1)%top.size()]
		if a.z!=b.z or absf(a.z)<float(layout.end):rail(ferry,a,b)
	for side in [-1,1]:
		var start: float = float(layout.end)*side
		var finish: float = float(layout.ramp_end)*side
		var half: float = layout.ramp_width*.5
		var left = Vector3(x-half,height,start)
		var right = Vector3(x+half,height,start)
		var foot_left = Vector3(x-half,0,finish)
		var foot_right = Vector3(x+half,0,finish)
		floor_prism(ferry,PackedVector3Array([left,right,foot_right,foot_left]),.24)
		rail(ferry,left+Vector3.RIGHT*.08,foot_left+Vector3.RIGHT*.08)
		rail(ferry,right-Vector3.RIGHT*.08,foot_right-Vector3.RIGHT*.08)
		for z in [-2.15,2.15]:
			box(ferry,Vector3(x+side*3.5,1.15,z),Vector3(.36,2.3,.36))

func add_cover(items: Array) -> void:
	for item in items:
		var scenery = Destructible.new()
		scenery.position = vec(item.at)
		scenery.scenery = true
		scenery.local_bounds = true
		scenery.palette = Color("4d9690") if item.asset=="crates_teal" else Color("e9b34e")
		add(ferry,scenery,item.name)
		var visual = model(scenery,"Model",item.asset)
		var size: Vector3 = COVER_SIZES[item.asset]
		var body = box(scenery,Vector3.UP*size.y*.5,size)
		scenery.bounds = AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
		scenery.saved_parts.append(scenery.get_path_to(visual))
		scenery.saved_parts.append(scenery.get_path_to(body))
		ferry.structure_paths.append(ferry.get_path_to(scenery))

func add_harbor(layout: Dictionary) -> void:
	var lighthouse = model(ferry,"Lighthouse","lighthouse",vec(layout.lighthouse))
	var beam = MeshInstance3D.new()
	var band = QuadMesh.new()
	band.size = Vector2(22,2)
	beam.mesh = band
	beam.position = Vector3(-11,11.39,.05)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lamp = ShaderMaterial.new()
	lamp.shader = preload("res://assets/shaders/ferry_beacon.gdshader")
	beam.material_override = lamp
	add(lighthouse,beam,"Beacon")
	model(ferry,"FarPier","pier",vec(layout.pier))
	var water = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(700,700)
	water.mesh = plane
	water.position.y = -3.72
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var surface = ShaderMaterial.new()
	surface.shader = preload("res://assets/shaders/ferry_water.gdshader")
	water.material_override = surface
	add(ferry,water,"HarborWater")
	var sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://assets/shaders/ferry_night.gdshader")
	var sky = Sky.new()
	sky.sky_material = sky_material
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e7def7")
	env.ambient_light_energy = .63
	ferry.environment_override = env

func marker(parent: Node3D, label: String, at: Array) -> Marker3D:
	var point = Marker3D.new()
	point.position = vec(at)
	return add(parent,point,label)

func markers(parent: Node3D, label: String, positions: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in range(positions.size()):
		var point = marker(parent,label+str(i),positions[i])
		if label=="Opening":point.set_meta("fast",i>=6)
		paths.append(ferry.get_path_to(point))
	return paths

func generate() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/last_ferry_layout.json"))
	ferry = Ferry.new()
	ferry.name = "LastFerry"
	ferry.map_id = "last_ferry"
	ferry.fall_limit = -4.5
	ferry.sun_color = Color("ffe5bb")
	ferry.sun_rotation_degrees = Vector3(-49,-23,0)
	ferry.sun_energy = .32
	ferry.sun_shadow_bias = .24
	ferry.process_mode = Node.PROCESS_MODE_DISABLED
	add_harbor(layout)
	add_deck(layout.outline)
	add_bridge(layout.bridge)
	model(ferry,"Wheelhouse","deckhouse",vec(layout.deckhouse))
	box(ferry,vec(layout.deckhouse)+Vector3.UP*1.43,Vector3(5.86,2.86,5.3))
	model(ferry,"MainMast","mast",vec(layout.mast))
	box(ferry,vec(layout.mast)+Vector3.UP*5.95,Vector3(.82,11.9,.82))
	add_cover(layout.props)
	for i in range(layout.barrels.size()):
		var barrel = Barrel.new()
		barrel.position = vec(layout.barrels[i])
		add(ferry,barrel,"Barrel%d"%i)
		ferry.barrel_paths.append(ferry.get_path_to(barrel))
	var route = add(ferry,Node3D.new(),"Markers")
	var start = marker(route,"PlayerStart",layout.start)
	start.rotation.y = -.07
	ferry.start_path = ferry.get_path_to(start)
	ferry.opening_paths = markers(route,"Opening",layout.opening)
	ferry.reinforcement_paths = markers(route,"Reinforcement",layout.spawns)
	ferry.respawn_paths = markers(route,"Respawn",layout.respawns)
	ferry.route_paths = markers(route,"Tour",layout.tour)+markers(route,"Crossing",layout.crossing)

	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .5
	mesh.agent_height = 2
	mesh.agent_max_climb = .25
	mesh.agent_max_slope = 39
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = "ferry_navigation"
	nav.navigation_mesh = mesh
	add(ferry,nav,"Navigation")
	ferry.navigation_path = ferry.get_path_to(nav)
	ferry.add_to_group("ferry_navigation",true)
	root.add_child(ferry)
	nav.bake_navigation_mesh(false)
	assert(mesh.get_polygon_count()>0,"Ferry navigation bake is empty")
	ferry.process_mode = Node.PROCESS_MODE_INHERIT
	for node in ferry.find_children("*","",true,false):
		if node.has_meta("structure"):node.remove_meta("structure")
	var scene = PackedScene.new()
	assert(scene.pack(ferry)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/last_ferry.tscn")==OK)
	print("FERRY_SCENE_READY ",mesh.get_polygon_count()," navigation polygons")
	quit()
