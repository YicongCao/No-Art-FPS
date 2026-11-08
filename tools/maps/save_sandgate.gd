extends SceneTree

const Sandgate = preload("res://scripts/maps/sandgate.gd")
const Destructible = preload("res://scripts/destructible.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
var arena: Node3D

func _initialize() -> void:
	build.call_deferred()

func vec(raw: Array) -> Vector3:
	return Vector3(raw[0],raw[1],raw[2])

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node,true)
	node.owner = arena
	return node

func model(parent: Node3D, asset: String, label: String) -> Node3D:
	var scene: PackedScene = load("res://assets/models/sandgate/"+asset+".glb")
	return add(parent,scene.instantiate(),label)

func collider(parent: Node3D, shape: Shape3D, at: Vector3, angle: float = 0.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_mask = 0
	body.position = at
	body.rotation.y = angle
	add(parent,body,"Body")
	var boundary = CollisionShape3D.new()
	boundary.shape = shape
	add(body,boundary,"Shape")
	return body

func box(parent: Node3D, at: Vector3, size: Vector3, angle: float = 0.0) -> void:
	var shape = BoxShape3D.new()
	shape.size = size
	collider(parent,shape,at,angle)

func marker_paths(parent: Node3D, label: String, entries: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var marker = Marker3D.new()
		marker.position = vec(entry)
		if entry.size()>3 and entry[3]:marker.set_meta("fast",true)
		add(parent,marker,label+str(i))
		paths.append(arena.get_path_to(marker))
	return paths

func place_prop(parent: Node3D, item: Dictionary) -> void:
	var prop = Destructible.new()
	prop.position = vec(item.at)
	prop.rotation.y = item.angle
	prop.local_bounds = true
	prop.scenery = item.kind!="wall"
	prop.structural_section = item.kind=="wall"
	prop.palette = Color("c26148") if item.kind in ["stall","wall"] else Color("edb748")
	var size = vec(item.size)
	prop.bounds = AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
	add(parent,prop,item.name)
	model(prop,item.name,"Model")
	if item.kind=="stall":
		# Counter collision keeps the lane honest. Cloth stays overhead.
		box(prop,Vector3.UP*.48,Vector3(size.x,.96,size.z))
	else:
		box(prop,Vector3.UP*size.y*.5,size)
	for child in prop.get_children():prop.saved_parts.append(prop.get_path_to(child))
	arena.structure_paths.append(arena.get_path_to(prop))

func build() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/sandgate_layout.json"))
	arena = Sandgate.new()
	arena.name = "Sandgate"
	arena.map_id = "sandgate"
	arena.sun_rotation_degrees = Vector3(-49,35,0)
	arena.sun_energy = .24
	arena.sun_color = Color("fff1db")
	arena.fall_limit = -3.8
	var daylight = Environment.new()
	daylight.background_mode = Environment.BG_COLOR
	daylight.background_color = Color("527dc6")
	daylight.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	daylight.ambient_light_color = Color("e1e7ff")
	daylight.ambient_light_energy = .54
	arena.environment_override = daylight
	var architecture = add(arena,Node3D.new(),"Architecture")
	for zone in layout.zones:model(architecture,zone,zone.capitalize().replace(" ",""))
	var collision = add(arena,Node3D.new(),"Collision")
	for item in layout.boxes:box(collision,vec(item[0]),vec(item[1]),item[2])
	for outline in layout.ramps:
		var vertices = PackedVector3Array()
		for point in outline:
			var p = vec(point)
			vertices.append(p)
			vertices.append(p+Vector3.DOWN*.28)
		var shape = ConvexPolygonShape3D.new()
		shape.points = vertices
		collider(collision,shape,Vector3.ZERO)
	var props = add(arena,Node3D.new(),"Props")
	for item in layout.props:place_prop(props,item)
	for i in range(layout.barrels.size()):
		var barrel = Barrel.new()
		barrel.position = vec(layout.barrels[i])
		add(arena,barrel,"Barrel%d"%i)
		arena.barrel_paths.append(arena.get_path_to(barrel))
	var clouds: PackedScene = load("res://assets/models/cloud.glb")
	for i in range(layout.clouds.size()):
		var cloud = add(arena,clouds.instantiate(),"Cloud%d"%i)
		cloud.position = vec(layout.clouds[i])
		cloud.scale = Vector3.ONE*(1.2+.18*i)
		cloud.rotation.y = i*.8
	var markers = add(arena,Node3D.new(),"Markers")
	arena.start_path = marker_paths(markers,"Start",[layout.start])[0]
	arena.get_node(arena.start_path).rotation.y = .045
	arena.opening_paths = marker_paths(markers,"Opening",layout.opening)
	arena.reinforcement_paths = marker_paths(markers,"Reinforcement",layout.spawns)
	arena.respawn_paths = marker_paths(markers,"Respawn",layout.respawns)
	arena.route_paths = marker_paths(markers,"Tour",layout.routes)
	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .5
	mesh.agent_height = 2.0
	mesh.agent_max_climb = .25
	mesh.agent_max_slope = 37
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = "sandgate_navigation"
	mesh.filter_baking_aabb = AABB(Vector3(-24.2,-1.85,-20.2),Vector3(48.4,5.0,40.4))
	nav.navigation_mesh = mesh
	add(arena,nav,"Navigation")
	arena.navigation_path = arena.get_path_to(nav)
	arena.add_to_group("sandgate_navigation",true)
	root.add_child(arena)
	nav.bake_navigation_mesh(false)
	for _tick in range(40):
		await physics_frame
		var map = arena.get_world_3d().navigation_map
		if NavigationServer3D.map_get_iteration_id(map)>0 and NavigationServer3D.map_get_closest_point_owner(map,arena.player_start().origin)==nav.get_rid():break
	if not arena.validate_navigation():
		quit(1)
		return
	for node in arena.find_children("*","CollisionObject3D",true,false):
		if node.has_meta("structure"):node.remove_meta("structure")
	var scene = PackedScene.new()
	assert(scene.pack(arena)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/sandgate.tscn")==OK)
	print("SANDGATE_SCENE_READY ",mesh.get_polygon_count()," navigation polygons")
	quit()
