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
	for key in ["cream","sand","timber","ink","blue","green","red","purple","yellow","leaf"]:
		var material = StandardMaterial3D.new()
		material.resource_name = key
		material.albedo_color = Color({"cream":"e5e0d2","sand":"d5b471","timber":"a97c4b","ink":"243440","blue":"304f9d","green":"4d7d70","red":"b65745","purple":"754c87","yellow":"e9ba50","leaf":"7c9e44"}[key])
		material.roughness = .9
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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
		var no_collision = str(mesh.name).begins_with("stair_")
		for word in ["strap","band","shutter","pot","capstone","canopy","cactus"]:
			if word in str(mesh.name):no_collision = true
		if "cactus" in str(mesh.name) and ("_bed" in str(mesh.name) or "_trunk" in str(mesh.name)):no_collision = false
		if not no_collision:
			var body = StaticBody3D.new()
			body.name = "Collision"
			wrapper.add_child(body)
			var shape = CollisionShape3D.new()
			shape.name = "Shape"
			body.add_child(shape)
			if "ascent" in str(mesh.name) or "ramp" in str(mesh.name) or "slope" in str(mesh.name) or "doors_wall" in str(mesh.name) or "double_doors" in str(mesh.name) or "tunnel_rib" in str(mesh.name) or "b_window_wall" in str(mesh.name) or str(mesh.name)=="B_ctwest" or str(mesh.name)=="B_southwest" or str(mesh.name)=="B_tspawn_w" or "B_southwest_base" in str(mesh.name) or "B_ctwest_base" in str(mesh.name) or str(mesh.name)=="mid_wall_n" or "B_tspawn_w_base" in str(mesh.name):
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
	# Same low-poly cloud asset as the original yard; never part of walkable nav.
	for cloud_data in [[Vector3(-88,16,74),1.8,-50],[Vector3(-97,18,64),2.0,-50],[Vector3(-94,15,50),1.3,-50],[Vector3(-47,12,-18),1.6,0],[Vector3(16,12,-22),1.4,0],[Vector3(-12,11,44),1.7,0]]:
		var cloud = load("res://assets/models/cloud.glb").instantiate()
		cloud.name = "Cloud%d"%map.get_child_count()
		map.add_child(cloud)
		cloud.position = cloud_data[0]
		cloud.scale = Vector3.ONE*cloud_data[1]
		cloud.rotation_degrees.y = cloud_data[2]
	# Large wall markings are attached graphics, never floating C4 text.
	for sign_data in [["a",Vector3(8,1.8,-13.72),0.0],["b",Vector3(-59,-1.3,63.72),PI]]:
		var sign = MeshInstance3D.new();sign.name = "SiteMark_"+sign_data[0]
		var quad = QuadMesh.new();quad.size = Vector2(2.5,2.5);sign.mesh = quad
		var material = StandardMaterial3D.new()
		material.albedo_texture = load("res://assets/ui/dust-site-"+sign_data[0]+".svg")
		material.roughness = 1;sign.material_override = material
		sign.position = sign_data[1];sign.rotation.y = sign_data[2];map.add_child(sign)
	for point in [Vector3(-80,-.5,35),Vector3(-80,1.8,18),Vector3(-80,2.3,8)]:
		var lamp = OmniLight3D.new();lamp.position = point
		lamp.light_color = Color("ffe4ae");lamp.light_energy = .65;lamp.omni_range = 9
		lamp.shadow_enabled = false;map.add_child(lamp)
	var marks = Node3D.new();marks.name = "Markers";map.add_child(marks)
	var start = marker(marks,"PlayerStart",Vector3(-62,.05,-10));start.rotation.y = -PI*.5
	var opening: Array[NodePath] = []
	var routes = [
		[Vector3(-42,9,0),Vector3(-24,9,0)],
		[Vector3(-38,-8,2.5),Vector3(-18,-8,2.5)],
		[Vector3(-80,-26,-3.5),Vector3(-80,-34,-3.5)],
		[Vector3(-5,10,0),Vector3(10,10,0)],
		[Vector3(10,-6,0),Vector3(10,7,0)],
		[Vector3(-29,-34,-3.5),Vector3(-17,-34,-3.5)],
		[Vector3(-59,-52,-3.5),Vector3(-59,-61,-3.5)],
		[Vector3(-74,-53,-3.5),Vector3(-71,-43,-3.5)]
	]
	for i in range(routes.size()):
		var actor = marker(marks,"Guard%d"%i,position_from_source(routes[i][0]))
		for j in range(routes[i].size()):marker(actor,"Route%d"%j,position_from_source(routes[i][j])-actor.position)
		opening.append(map.get_path_to(actor))
	var objective_paths: Array[NodePath] = []
	for data in [["a_site",Vector3(4,.3,0)],["short",Vector3(-27,-34,-3.5)],["ct_court",Vector3(-57,-56,-3.5)]]:
		var objective = Node3D.new();objective.name = data[0];objective.set_script(Objective)
		map.add_child(objective);objective.position = position_from_source(data[1])+Vector3.UP*.45
		objective.objective_id = data[0]
		var model = load("res://assets/models/dust_flavor/c4.glb").instantiate();model.name = "Visual";objective.add_child(model)
		var stand = MeshInstance3D.new();stand.name = "Mount"
		var stand_mesh = BoxMesh.new();stand_mesh.size = Vector3(.5,.45,.3)
		stand.mesh = stand_mesh;stand.material_override = palette["timber"]
		stand.position.y = -.225;objective.add_child(stand)
		var light = MeshInstance3D.new();light.name = "Indicator"
		var light_mesh = SphereMesh.new();light_mesh.radius = .025;light_mesh.height = .05
		light_mesh.radial_segments = 6;light_mesh.rings = 3;light.mesh = light_mesh
		var light_mat = StandardMaterial3D.new();light_mat.albedo_color = Color("f2d084")
		light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		light.material_override = light_mat;light.position = Vector3(.11,.21,-.11);objective.add_child(light)
		objective_paths.append(map.get_path_to(objective))
	map.set_script(Runtime)
	map.map_id = "dust_flavor"
	map.sun_rotation_degrees = Vector3(-52,145,0)
	map.fall_limit = -6
	map.start_path = map.get_path_to(start)
	map.navigation_path = map.get_path_to(nav)
	map.opening_paths = opening
	map.objective_paths = objective_paths
	map.radar_bounds = Rect2(-90,-26,119,96)
	var triangles: Array[PackedVector2Array] = []
	var vertices = nm.vertices
	for i in range(nm.get_polygon_count()):
		var polygon = PackedVector2Array()
		var valid = true
		for index in nm.get_polygon(i):
			if vertices[index].y>3.1 or vertices[index].y< -3.25:valid = false
			polygon.append(Vector2(vertices[index].x,vertices[index].z))
		if valid:triangles.append(polygon)
	map.radar_polygons = triangles
	var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="357" height="288" viewBox="-90 -26 119 96"><rect x="-90" y="-26" width="119" height="96" rx="3" fill="#15212c"/>'
	for polygon in triangles:
		var points_text = ""
		for v in polygon:points_text += "%s,%s "%[v.x,v.y]
		svg += '<polygon points="'+points_text+'" fill="#c4b190" stroke="#c4b190" stroke-width="0.08"/>'
	svg += '<g fill="#fff8e8" font-family="sans-serif" font-size="5" font-weight="bold"><text x="4" y="-3">A</text><text x="-65" y="53">B</text></g></svg>'
	FileAccess.open("res://assets/ui/dust-radar.svg",FileAccess.WRITE).store_string(svg)
	for node in map.find_children("*","",true,false):node.scene_file_path = "";node.owner = map
	map.process_mode = Node.PROCESS_MODE_INHERIT
	var packed = PackedScene.new();assert(packed.pack(map)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/maps/dust_flavor.tscn")==OK)
	print("DUST_SCENE_SAVED: static collision/nav, 8 authored patrols, 3 objectives")
	quit()
