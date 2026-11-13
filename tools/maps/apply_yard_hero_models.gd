extends SceneTree
## Replace visual children only. Keep authored colliders, navigation, pivots and reset paths.
const KIT := ["forklift", "container_cream", "container_green", "container_red", "container_purple", "container_openable"]
const MAP := "res://scenes/maps/yard.tscn"
var changed := 0
var mesh_cache := {}

func _initialize() -> void:
	var map: Node = load(MAP).instantiate()
	var before := gameplay_snapshot(map)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var baseline: Node = load(args[0]).instantiate()
		assert(gameplay_snapshot(baseline) == before, "Saved scene gameplay data differs from baseline")
		baseline.free()
		map.free()
		print("YARD_SAVED_LAYOUT_PASS nonvisual_nodes=", before.size())
		quit()
		return
	for asset in KIT:
		var imported: Node = load("res://assets/models/%s.glb" % asset).instantiate()
		var source := imported.find_child(asset, true, false)
		assert(source != null, asset)
		for target in map.find_children(asset, "Node3D", true, false):
			# The inner authored asset root has immediate meshes or door pivots.
			if not target.get_children().any(func(n): return n is MeshInstance3D): continue
			var styles := {}
			for mesh: MeshInstance3D in target.find_children("*", "MeshInstance3D", true, false):
				for i in mesh.mesh.get_surface_count():
					var material: Material = mesh.mesh.surface_get_material(i)
					styles[material.resource_name] = [material, mesh.material_override, mesh.layers, mesh.cast_shadow]
			sync_meshes(source, target, map, styles)
			changed += 1
		imported.free()
	assert(changed > 0)
	var after := gameplay_snapshot(map)
	assert(before == after, "Visual update altered gameplay data")
	var packed := PackedScene.new()
	assert(packed.pack(map) == OK)
	assert(ResourceSaver.save(packed, MAP) == OK)
	var out := "res://artifacts/local/scene-evolution/score_attack/layout-proof.json"
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify({"visual_roots_updated": changed,
		"nonvisual_nodes": before.size(), "unchanged": before == after,
		"before_sha256": JSON.stringify(before).sha256_text(),
		"after_sha256": JSON.stringify(after).sha256_text(),
		"scope": "All non-mesh node transforms; collider geometry/layers; nav vertices/polygons; stored script data including destruction/reset paths. No gameplay nodes are replaced."}, "  "))
	map.free()
	print("YARD_HERO_VISUALS_PASS roots=", changed, " nonvisual_nodes=", before.size())
	quit()

func sync_meshes(source: Node, target: Node, owner_root: Node, styles: Dictionary) -> void:
	for child in target.get_children():
		if child is MeshInstance3D:
			target.remove_child(child)
			child.free()
	for child in source.get_children():
		if child is MeshInstance3D:
			assert(child.mesh.get_surface_count() == 1, "Export one material per visual part")
			var fresh: MeshInstance3D = child.duplicate()
			var cache_key := str(child.mesh.get_instance_id())
			for surface in child.mesh.get_surface_count():
				var key: String = child.mesh.surface_get_material(surface).resource_name
				assert(styles.has(key), "Unexpected material: " + key)
				cache_key += ":" + str(styles[key][0].get_instance_id())
			if not mesh_cache.has(cache_key):
				var shared: ArrayMesh = child.mesh.duplicate()
				for surface in shared.get_surface_count():
					var key: String = shared.surface_get_material(surface).resource_name
					shared.surface_set_material(surface, styles[key][0])
				mesh_cache[cache_key] = shared
			fresh.mesh = mesh_cache[cache_key]
			for surface in child.mesh.get_surface_count():
				var key: String = child.mesh.surface_get_material(surface).resource_name
				assert(styles.has(key), "Unexpected material: " + key)
				fresh.material_override = styles[key][1]
				fresh.layers = styles[key][2]
				fresh.cast_shadow = styles[key][3]
			target.add_child(fresh)
			fresh.owner = owner_root
		else:
			var pivot := target.get_node_or_null(NodePath(child.name))
			assert(pivot != null and pivot is Node3D and child is Node3D)
			assert(pivot.transform.is_equal_approx(child.transform), "Changed pivot: " + str(child.name))
			sync_meshes(child, pivot, owner_root, styles)

func stable(value: Variant) -> Variant:
	if value is Material:
		return [value.get_class(), value.resource_name, value.resource_path.get_file()]
	if value is Resource:
		return [value.get_class(), value.resource_path]
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = stable(value[key])
		return result
	if value is Array:
		return value.map(stable)
	return var_to_str(value)

func gameplay_snapshot(map: Node) -> Dictionary:
	var result := {}
	for node in [map] + map.find_children("*", "", true, false):
		if node is MeshInstance3D: continue
		var row := {"type": node.get_class()}
		if node is Node3D: row["transform"] = var_to_str(node.transform)
		if node is CollisionObject3D:
			row["layers"] = [node.collision_layer, node.collision_mask]
		if node is CollisionShape3D:
			row["disabled"] = node.disabled
			row["shape"] = node.shape.get_class()
			row["faces"] = var_to_str(node.shape.get_debug_mesh().get_faces()).sha256_text()
		if node is NavigationRegion3D:
			var nav: NavigationMesh = node.navigation_mesh
			row["vertices"] = var_to_str(nav.get_vertices()).sha256_text()
			var polygons := []
			for i in nav.get_polygon_count(): polygons.append(var_to_str(nav.get_polygon(i)))
			row["polygons"] = JSON.stringify(polygons).sha256_text()
		for prop in node.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE:
				row["export:" + prop.name] = stable(node.get(prop.name))
		result[str(map.get_path_to(node))] = row
	return result
