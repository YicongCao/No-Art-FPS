extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var source = load("res://scenes/maps/sandgate.tscn")
	var a = source.instantiate();root.add_child(a);a.bake_navigation()
	var b = source.instantiate();root.add_child(b);b.bake_navigation()
	assert(a.nav.navigation_mesh!=b.nav.navigation_mesh)
	var editable = source.instantiate()
	var marker = editable.get_node(editable.start_path)
	marker.position.x += 1
	var moved = marker.position
	var pack = PackedScene.new();assert(pack.pack(editable)==OK)
	DirAccess.make_dir_recursive_absolute("res://artifacts/local")
	assert(ResourceSaver.save(pack,"res://artifacts/local/sandgate-roundtrip.tscn")==OK)
	var loaded = load("res://artifacts/local/sandgate-roundtrip.tscn").instantiate()
	root.add_child(loaded)
	assert(loaded.get_node(loaded.start_path).position==moved)
	assert(b.get_node(b.start_path).position!=moved)
	loaded.free();a.free();b.free();editable.free()
	print("MAP_SCENE_PASS: saved marker/prop transforms survive reload; navigation is instance-isolated")
	quit()
