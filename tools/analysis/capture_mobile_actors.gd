extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size = Vector2i(1280,720)
	var world = Node3D.new();root.add_child(world)
	var environment = WorldEnvironment.new();environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("819ab7")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c5d7e8")
	environment.environment.ambient_light_energy = .55
	world.add_child(environment)
	var sun = DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40,-35,0);sun.light_energy = .85;world.add_child(sun)
	var camera = Camera3D.new();world.add_child(camera);camera.position = Vector3(0,1.3,4.4);camera.look_at(Vector3(0,1.1,0));camera.fov = 42
	for kind in ["enemy","rusher"]:
		var old = load("res://assets/models/toy/%s.glb"%kind).instantiate()
		var compact = load("res://assets/models/toy/%s_mobile.glb"%kind).instantiate()
		world.add_child(old);world.add_child(compact)
		old.position.x = -.65;compact.position.x = .65
		old.rotation.y = PI;compact.rotation.y = PI
		preload("res://scripts/enemy.gd").add_toy_rim(old)
		preload("res://scripts/enemy.gd").apply_mobile_paint(compact)
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/updates/mobile-performance-2026-11-15/"+kind+"-geometry-comparison.png")
		old.free();compact.free()
	world.free()
	await process_frame
	quit()
