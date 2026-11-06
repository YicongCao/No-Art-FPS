extends SceneTree
const Builder = preload("res://tools/maps/build_yard.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const Runtime = preload("res://scripts/arena.gd")

func _initialize() -> void:
	generate.call_deferred()

func paths(map: Node, nodes: Array) -> Array[NodePath]:
	var result: Array[NodePath] = []
	for node in nodes:result.append(map.get_path_to(node))
	return result

func marker(parent: Node3D, name: String, at: Vector3) -> Marker3D:
	var node = Marker3D.new()
	node.name = name
	parent.add_child(node)
	node.global_position = at
	return node

func generate() -> void:
	var map = Builder.new()
	map.name = "Yard"
	map.process_mode = Node.PROCESS_MODE_DISABLED
	map.set_process(false)
	map.set_physics_process(false)
	root.add_child(map)
	await process_frame
	map.bake_navigation()
	# Preserve the layout while placing all parts under their editable building.
	for building in map.structures:
		building.position = building.bounds.position
		building.bounds.position = Vector3.ZERO
		building.local_bounds = true
		for part in building.parts:part.reparent(building,true)
		building.saved_parts = paths(building,building.parts)
	map.nav.navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	map.nav.navigation_mesh.geometry_source_group_name = "yard_navigation"
	map.add_to_group("yard_navigation",true)
	map.nav.bake_navigation_mesh(false)
	var saved = {}
	for key in ["structures","barrels","containers","traffic_lights","palms","loungers","pool","warehouse_structure","deck_structure","nav","materials","finale_props","spawn_points"]:saved[key] = map.get(key)
	var actors = map.opening_actors()
	var respawns = map.respawn_candidates()
	var batches = map.find_children("*","MultiMeshInstance3D",true,false)
	var collision_nodes = map.find_children("*","StaticBody3D",true,false).filter(func(node):return not node.has_meta("structure") and not node is Barrel and node.global_position.y>=0)
	map.set_script(Runtime)
	map.map_id = "yard"
	map.navigation_path = map.get_path_to(saved.nav)
	map.structure_paths = paths(map,saved.structures)
	map.barrel_paths = paths(map,saved.barrels)
	map.container_paths = paths(map,saved.containers)
	map.opening_room_paths = paths(map,[saved.containers[0],saved.containers[2]])
	map.traffic_paths = paths(map,saved.traffic_lights)
	map.palm_paths = paths(map,saved.palms)
	map.lounger_paths = paths(map,saved.loungers)
	map.pool_path = map.get_path_to(saved.pool)
	map.warehouse_path = map.get_path_to(saved.warehouse_structure)
	map.deck_path = map.get_path_to(saved.deck_structure)
	map.palette_materials = saved.materials
	map.batch_paths = paths(map,batches)
	map.decoration_paths = paths(map,saved.finale_props)
	map.static_collision_paths = paths(map,collision_nodes)
	var marks = Node3D.new()
	marks.name = "Markers"
	map.add_child(marks)
	map.start_path = map.get_path_to(marker(marks,"PlayerStart",Vector3(0,.05,10.5)))
	for i in range(actors.size()):
		var m = marker(marks,"Opening%d"%i,actors[i].position)
		m.set_meta("fast",actors[i].fast)
		map.opening_paths.append(map.get_path_to(m))
	for i in range(saved.spawn_points.size()):map.reinforcement_paths.append(map.get_path_to(marker(marks,"Reinforcement%d"%i,saved.spawn_points[i])))
	for i in range(respawns.size()):map.respawn_paths.append(map.get_path_to(marker(marks,"Respawn%d"%i,respawns[i])))
	for region_data in [["deck",AABB(Vector3(-12,2.2,-24),Vector3(21.5,10,16)),saved.deck_structure,[Vector3(-4,3.1,-11),Vector3(-4,3.1,-20),Vector3(6,3.1,-20),Vector3(4,3.1,-11)]],["warehouse",AABB(Vector3(24,-2,-16),Vector3(12,10,25)),saved.warehouse_structure,[Vector3(30,0,3),Vector3(30,0,-10)]]]:
		var region = Node3D.new()
		region.name = region_data[0]
		marks.add_child(region)
		region.set_meta("bounds",region_data[1])
		region.set_meta("capacity",2)
		region.set_meta("structure_path",map.get_path_to(region_data[2]))
		for i in range(region_data[3].size()):marker(region,"Patrol%d"%i,region_data[3][i])
		map.region_paths.append(map.get_path_to(region))
	for node in map.find_children("*","",true,false):
		node.scene_file_path = ""
		node.owner = map
		for key in ["structure","container"]:
			if node.has_meta(key):node.remove_meta(key)
	map.process_mode = Node.PROCESS_MODE_INHERIT
	for key in saved.materials:
		var mat = saved.materials[key]
		var path = "res://assets/materials/yard_"+key+".tres"
		ResourceSaver.save(mat,path)
		mat.take_over_path(path)
	var packed = PackedScene.new()
	assert(packed.pack(map)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/maps/yard.tscn")==OK)
	print("YARD_SCENE_SAVED: ",map.get_child_count()," roots; editable structures and markers")
	quit()
