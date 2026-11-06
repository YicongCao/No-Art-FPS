extends SceneTree

func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	var map = load("res://scenes/maps/yard.tscn").instantiate()
	map.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(map)
	await process_frame
	var nav = map.get_node(map.navigation_path)
	nav.navigation_mesh = nav.navigation_mesh.duplicate()
	nav.bake_navigation_mesh(false)
	ResourceSaver.save(nav.navigation_mesh,"/tmp/no-art-yard-navigation.tres")
	print("YARD_NAV_REBAKED polygons=",nav.navigation_mesh.get_polygon_count())
	quit()
