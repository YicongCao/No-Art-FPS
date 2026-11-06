extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var source = load("res://scenes/maps/yard.tscn")
	var a = source.instantiate();root.add_child(a);a.bake_navigation()
	var b = source.instantiate();root.add_child(b);b.bake_navigation()
	assert(a.nav.navigation_mesh!=b.nav.navigation_mesh)
	var batch_a = a.get_node(a.batch_paths[0]).multimesh
	var batch_b = b.get_node(b.batch_paths[0]).multimesh
	assert(batch_a!=batch_b)
	var editable = source.instantiate()
	var marker = editable.get_node(editable.start_path)
	marker.position.x += 1
	var moved = marker.position
	var palm = editable.get_node(editable.palm_paths[0])
	palm.position.x += .75
	var palm_at = palm.position
	var pack = PackedScene.new();assert(pack.pack(editable)==OK)
	DirAccess.make_dir_recursive_absolute("res://artifacts/local")
	assert(ResourceSaver.save(pack,"res://artifacts/local/yard-roundtrip.tscn")==OK)
	var loaded = load("res://artifacts/local/yard-roundtrip.tscn").instantiate()
	root.add_child(loaded)
	assert(loaded.get_node(loaded.start_path).position==moved)
	assert(loaded.palms[0].position==palm_at)
	assert(b.get_node(b.start_path).position!=moved)
	loaded.free();a.free();b.free();editable.free()
	print("MAP_SCENE_PASS: saved marker/prop transforms survive reload; nav and batches are instance-isolated")
	quit()
