extends SceneTree

const Batches = preload("res://scripts/maps/web_prop_batches.gd")
const UNCHANGED_ROOTS = ["Architecture", "InteractiveProps", "Moving", "Carousel", "Coaster", "HarborWater"]
const VIEW_ANGLES = [-0.55, 0.0, 0.55]
var game: Node3D
var rendered := DisplayServer.get_name() != "headless"
var capture_dir := OS.get_environment("WEB_BATCH_CAPTURE_DIR")

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		if game.title_frame_ready:
			break
		await process_frame
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	var roster: Array = game.TITLE_SESSIONS.keys() + game.CONCEPT_SESSIONS.keys()
	assert(Batches.CELLS.size() == roster.size())
	if rendered and not capture_dir.is_empty():
		assert(DirAccess.make_dir_recursive_absolute(capture_dir) == OK)
	# Revisit Sandgate at the end to exercise teardown and rebuilding on map switch.
	roster.append("sandgate")
	for id in roster:
		var previous: Node3D = game.arena
		await game.select_session(game.title_session_path(id), id)
		await process_frame
		assert(not is_instance_valid(previous), "The previous map must be unloaded")
		if not await check_map(id):
			quit(1)
			return
	# Allow the real-time audio mixer to drain during a fixed-step headless run.
	if not rendered:
		var deadline := Time.get_ticks_msec() + 450
		while Time.get_ticks_msec() < deadline:
			await process_frame
	game.queue_free()
	await process_frame
	print("WEB_PROP_ROSTER_PASS: nine maps and a map revisit; renderer=", DisplayServer.get_name())
	quit()

func check_map(id: String) -> bool:
	var arena: Node3D = game.arena
	assert(arena.map_id == id and game.nav_ready and arena.validate_navigation(), id)
	assert(not arena.has_node(Batches.BATCH_ROOT), "Native startup must not batch map props")
	game.clear_round()
	game.player.enabled = false
	game.hud.hide()
	game.player.gun.hide()
	var navigation: NavigationMesh = arena.nav.navigation_mesh
	var unchanged := {}
	for path in UNCHANGED_ROOTS:
		var branch := arena.get_node_or_null(path)
		if branch:
			for node: MeshInstance3D in branch.find_children("*", "MeshInstance3D", true, false):
				unchanged[node] = node.mesh
			if branch is MeshInstance3D:
				unchanged[branch] = branch.mesh
	var before := {}
	var source_surfaces := {}
	for source: MeshInstance3D in arena.find_children("*", "MeshInstance3D", true, false):
		if source.mesh:
			source_surfaces[source] = source.mesh.get_surface_count()
	var was_processing := arena.is_processing()
	if rendered:
		# Hold title-time animation (e.g. drifting snow and waving flags) across
		# the pair. Keep MapLookdev processing so ferry reflections still render.
		arena.set_process(false)
		before = await sample_views(id, "before")
	var lookdev := arena.get_node("MapLookdev")
	Batches.apply(arena, lookdev.surface_shaders.values())
	var parent := arena.get_node(Batches.BATCH_ROOT)
	var groups := parent.get_child_count()
	assert(groups > 0, "%s must instance at least one repeated mesh" % id)
	assert(arena.nav.navigation_mesh == navigation and not arena.navigation_dirty)
	for source in unchanged:
		assert(source.mesh == unchanged[source], "Protected source moved into a batch: %s" % arena.get_path_to(source))
	var original_surfaces := 0
	var batched_surfaces := 0
	var instances := 0
	var static_poses := {}
	for source in source_surfaces:
		if not source.mesh:
			original_surfaces += source_surfaces[source]
	for batch: MultiMeshInstance3D in parent.get_children():
		var count := batch.multimesh.instance_count
		assert(count >= 2)
		instances += count
		batched_surfaces += batch.multimesh.mesh.get_surface_count()
		if not arena.initial_batches.has(batch):
			assert(id == "sandgate", "Only Sandgate clouds are opted in as permanent visuals")
			if rendered:
				static_poses[batch] = []
				for slot in count:
					static_poses[batch].append(batch.multimesh.get_instance_transform(slot))
	assert(batched_surfaces < original_surfaces and (id == "sandgate") == arena.initial_batches.is_empty())
	Batches.apply(arena, lookdev.surface_shaders.values())
	assert(parent.get_child_count() == groups, "Batch setup is idempotent")
	var psnr := []
	var draws := []
	if rendered:
		var after := await sample_views(id, "after")
		arena.set_process(was_processing)
		for view in before:
			var comparison := (after[view][0] as Image).compute_image_metrics(before[view][0], false)
			var similarity := float(comparison.peak_snr)
			assert(similarity >= 35.0, "%s/%s changed visibly (PSNR %0.2f dB)" % [id, view, similarity])
			psnr.append(snappedf(minf(similarity, 100.0), 0.1))
			draws.append([before[view][1], after[view][1]])
		if id == "last_ferry":
			assert(lookdev.mirror and lookdev.water.get_shader_parameter("harbor_capture_active"))
			for batch in parent.get_children():
				assert(batch.layers & lookdev.REFLECTION_LAYER)

	var owners: Array = arena.structures.filter(func(prop): return not prop.batch_parts.is_empty())
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.clear_round()
	if not owners.is_empty():
		assert(owners.size() >= 2)
		owners[0].collapse(false)
		assert_slots(owners[0], false)
		for neighbor in owners.slice(1):
			assert_slots(neighbor, true)
	game.rules.elapsed = game.rules.duration
	game.rules.active = false
	game.start_finale()
	assert(game.finale_active)
	for prop in owners:
		assert_slots(prop, false)
	for batch in static_poses:
		for slot in static_poses[batch].size():
			assert(batch.multimesh.get_instance_transform(slot).is_equal_approx(static_poses[batch][slot]),
				"Background clouds must survive the finale")
	game.start_run()
	for prop in owners:
		assert_slots(prop, true)
	game.state = "RESULTS"
	game.menu_action("menu")
	game.hud.show()
	game.player.gun.show()
	print("WEB_PROP_MAP_PASS ", JSON.stringify({"map": id, "batches": groups, "instances": instances,
		"surfaces": [original_surfaces, batched_surfaces], "fixed_view_draws": draws, "psnr_db": psnr}))
	return true

func assert_slots(prop: Node3D, visible: bool) -> void:
	assert(prop.collapsed != visible)
	for body in prop.collision_states:
		assert(body.collision_layer == (prop.collision_states[body] if visible else 0))
	for path in prop.batch_parts:
		var batch := game.arena.get_node(path) as MultiMeshInstance3D
		for slot in prop.batch_parts[path]:
			assert(slot >= 0 and slot < batch.multimesh.instance_count)
			if rendered:
				var expected: Transform3D = game.arena.initial_batches[batch][slot]
				if not visible:
					expected.basis = Basis.from_scale(Vector3.ZERO)
				assert(batch.multimesh.get_instance_transform(slot).is_equal_approx(expected))

func sample_views(id: String, label: String) -> Dictionary:
	var views := {}
	var camera: Camera3D = game.player.camera
	var start := camera.global_transform
	game.rules.elapsed = 50.0
	for frenzy in [false, true]:
		game.set_destroy_active(frenzy)
		for angle in VIEW_ANGLES:
			camera.global_transform = Transform3D(start.basis.rotated(Vector3.UP, angle), start.origin)
			for _frame in range(5):
				await process_frame
			await RenderingServer.frame_post_draw
			var view := "%s-%s" % ["frenzy" if frenzy else "normal", angle]
			var image := root.get_texture().get_image()
			views[view] = [image, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
			if angle == 0.0 and not capture_dir.is_empty():
				assert(image.save_png(capture_dir.path_join("%s-%s-%s.png" % [id, view, label])) == OK)
	camera.global_transform = start
	game.set_destroy_active(false)
	game.rules.elapsed = 0.0
	return views
