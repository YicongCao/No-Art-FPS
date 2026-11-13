extends SceneTree
# Offline placement cleanup only; no relocation or floor probes in the shipped game.
func _initialize() -> void:
	check.call_deferred()
func clear_at(game: Node3D, prop: Node3D) -> bool:
	var space = game.get_world_3d().direct_space_state
	var at = prop.global_position
	for offset in [Vector3.ZERO,Vector3(.45,0,.25),Vector3(-.45,0,-.25)]:
		var ground = space.intersect_ray(PhysicsRayQueryParameters3D.create(at+offset+Vector3.UP*2.6,at+offset-Vector3.UP*.2,1))
		if ground.is_empty() or absf(ground.position.y-at.y)>.14:return false
	for mesh: MeshInstance3D in prop.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("Remnant"):continue
		var aabb = mesh.get_aabb()
		var probe = PhysicsShapeQueryParameters3D.new()
		var shape = BoxShape3D.new()
		shape.size = (aabb.size*.87).max(Vector3.ONE*.02)
		probe.shape = shape
		probe.transform = mesh.global_transform*Transform3D(Basis.IDENTITY,aabb.get_center()+Vector3.UP*.02)
		probe.collision_mask = 1
		if not space.intersect_shape(probe,1).is_empty():return false
	return true
func check() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for i in range(900):
		if game.title_frame_ready:break
		await process_frame
	game.qa_mode = true
	var source = "res://art_source/interactive_props/placements.json"
	var entries = JSON.parse_string(FileAccess.get_file_as_string(source))
	var offsets: Array[Vector3] = []
	for x in range(-8,9):
		for z in range(-8,9):offsets.append(Vector3(x*.5,0,z*.5))
	offsets.sort_custom(func(a,b):return a.length_squared()<b.length_squared())
	for id in entries:
		await game.select_session(load(game.title_session_path(id)),id)
		await physics_frame
		await process_frame
		var placed: Array[Vector3] = []
		for i in range(game.arena.interactive_props.props.size()):
			var prop = game.arena.interactive_props.props[i]
			var start = prop.position
			var found = false
			for offset in offsets:
				prop.position = start+offset
				if placed.any(func(p):return p.distance_to(prop.position)<1.2):continue
				if game.arena.player_start().origin.distance_to(prop.position)<2.3:continue
				if clear_at(game,prop):
					found = true
					placed.append(prop.position)
					break
			assert(found,"Could not find nearby safe authored placement: "+id+"/"+str(prop.name))
			if prop.position!=start:print("PLACEMENT_MOVE ",id,"/",prop.name," ",start," -> ",prop.position)
			entries[id][i].at = [prop.position.x,prop.position.y,prop.position.z]
	var f = FileAccess.open(source,FileAccess.WRITE)
	f.store_string(JSON.stringify(entries,"\t")+"\n")
	game.queue_free()
	await process_frame
	quit()
