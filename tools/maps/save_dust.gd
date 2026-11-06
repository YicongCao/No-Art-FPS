extends SceneTree
const Runtime = preload("res://scripts/maps/dust_map.gd")
const Objective = preload("res://scripts/modes/c4_objective.gd")
var map: Node3D

func _initialize() -> void:
	generate.call_deferred()

func marker(parent: Node3D, name: String, at: Vector3) -> Marker3D:
	var m = Marker3D.new()
	m.name = name
	parent.add_child(m)
	m.position = at
	return m

func position_from_source(p: Vector3) -> Vector3:
	return Vector3(p.x,p.z,-p.y)

func generate() -> void:
	map = Node3D.new()
	map.name = "DustFlavor"
	map.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(map)
	var visuals = load("res://assets/models/dust_flavor/architecture.glb").instantiate()
	map.add_child(visuals)
	var palette = {}
	for key in ["cream","sand","timber","ink","blue","green","red","purple","yellow"]:
		var material = StandardMaterial3D.new()
		material.resource_name = key
		material.albedo_color = Color({"cream":"e5e0d2","sand":"d5b471","timber":"a97c4b","ink":"243440","blue":"304f9d","green":"4d7d70","red":"b65745","purple":"754c87","yellow":"e9ba50"}[key])
		material.roughness = .9
		var path = "res://assets/materials/palette_"+key+".tres"
		ResourceSaver.save(material,path)
		material.take_over_path(path)
		palette[key] = material
	for mesh in visuals.find_children("*","MeshInstance3D",true,false):
		var wrapper = Node3D.new()
		wrapper.name = str(mesh.name)
		map.add_child(wrapper)
		wrapper.global_transform = mesh.global_transform
		var copy = MeshInstance3D.new()
		copy.name = "Visual"
		copy.mesh = mesh.mesh
		copy.material_override = palette[mesh.mesh.surface_get_material(0).resource_name]
		wrapper.add_child(copy)
		var no_collision = false
		for word in ["strap","band","shutter","pot","capstone"]:
			if word in str(mesh.name):no_collision = true
		if not no_collision:
			var body = StaticBody3D.new()
			body.name = "Collision"
			wrapper.add_child(body)
			var shape = CollisionShape3D.new()
			shape.name = "Shape"
			body.add_child(shape)
			if "ramp" in str(mesh.name) or "slope" in str(mesh.name) or "doors_wall" in str(mesh.name):
				shape.shape = mesh.mesh.create_trimesh_shape()
			else:
				var box = BoxShape3D.new()
				box.size = mesh.mesh.get_aabb().size
				shape.shape = box
				shape.position = mesh.mesh.get_aabb().get_center()
	visuals.queue_free()
	await process_frame
	# Continuous stair collision keeps the descending shortcut walkable.
	var stair = StaticBody3D.new()
	stair.name = "ShortStairRamp"
	map.add_child(stair)
	var cs = CollisionShape3D.new()
	var convex = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	for z in [6.0,11.0]:
		points.append(Vector3(-8,-1,z));points.append(Vector3(-4.04,-1,z))
		points.append(Vector3(-8,2.5,z));points.append(Vector3(-4.04,0,z))
	convex.points = points
	cs.shape = convex
	stair.add_child(cs)
	var nav = NavigationRegion3D.new()
	nav.name = "Navigation"
	map.add_child(nav)
	var nm = NavigationMesh.new()
	nm.agent_radius = .5;nm.agent_height = 2;nm.agent_max_climb = .25;nm.agent_max_slope = 40
	nm.cell_size = .25;nm.cell_height = .25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = "dust_navigation"
	map.add_to_group("dust_navigation",true)
	nav.navigation_mesh = nm
	nav.bake_navigation_mesh(false)
	var marks = Node3D.new();marks.name = "Markers";map.add_child(marks)
	var start = marker(marks,"PlayerStart",Vector3(-62,.05,-10));start.rotation.y = -PI*.5
	var opening: Array[NodePath] = []
	var routes = [
		[Vector3(-42,9,0),Vector3(-24,9,0)],
		[Vector3(-38,-8,2.5),Vector3(-18,-8,2.5)],
		[Vector3(-52,-8,2.5),Vector3(-54,-8,2.5)],
		[Vector3(-5,10,0),Vector3(10,10,0)],
		[Vector3(10,-6,0),Vector3(10,7,0)],
		[Vector3(-10,9,0),Vector3(-7,1,0)],
		[Vector3(12,-32,-3.5),Vector3(0,-32,-3.5)],
		[Vector3(12,-18,-1.3),Vector3(12,-27,-3.2)]
	]
	for i in range(routes.size()):
		var actor = marker(marks,"Guard%d"%i,position_from_source(routes[i][0]))
		for j in range(routes[i].size()):marker(actor,"Route%d"%j,position_from_source(routes[i][j])-actor.position)
		opening.append(map.get_path_to(actor))
	var objective_paths: Array[NodePath] = []
	for data in [["a_site",Vector3(4,.3,0)],["short",Vector3(-34,-8,2.5)],["ct_court",Vector3(6,-35,-3.5)]]:
		var objective = Node3D.new();objective.name = data[0];objective.set_script(Objective)
		map.add_child(objective);objective.position = position_from_source(data[1])+Vector3.UP*.45
		objective.objective_id = data[0]
		var model = load("res://assets/models/dust_flavor/c4.glb").instantiate();model.name = "Visual";objective.add_child(model)
		var label = Label3D.new();label.name = "Indicator";label.text = "C4";label.position.y = .65
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;label.font_size = 32;label.pixel_size = .0025
		label.modulate = Color("f2d084");objective.add_child(label)
		objective_paths.append(map.get_path_to(objective))
	map.set_script(Runtime)
	map.map_id = "dust_flavor"
	map.fall_limit = -10
	map.start_path = map.get_path_to(start)
	map.navigation_path = map.get_path_to(nav)
	map.opening_paths = opening
	map.objective_paths = objective_paths
	for node in map.find_children("*","",true,false):node.scene_file_path = "";node.owner = map
	map.process_mode = Node.PROCESS_MODE_INHERIT
	var packed = PackedScene.new();assert(packed.pack(map)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/maps/dust_flavor.tscn")==OK)
	print("DUST_SCENE_SAVED: static collision/nav, 8 authored patrols, 3 objectives")
	quit()
