extends SceneTree

var game: Node3D
var evidence: Array = []
const OUT = "res://docs/updates/interactive-props-2026-11-13/"

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440,810)
	for frame in range(900):
		if game.title_frame_ready:break
		await process_frame
	game.qa_mode = true
	DirAccess.make_dir_recursive_absolute(OUT)
	var catalog = load("res://scripts/maps/interactive_prop_catalog.gd")
	var camera = Camera3D.new()
	game.add_child(camera)
	camera.fov = 63
	for id in catalog.PLACEMENTS:
		await game.select_session(load(game.title_session_path(id)),id)
		game.start_run()
		game.begin_running()
		game.set_physics_process(false)
		game.player.enabled = false
		game.invulnerable = 999
		game.clear_round()
		var manager = game.arena.interactive_props
		assert(manager.props.size()==9)
		await physics_frame
		await process_frame
		var report = {"map":id,"groups":9,"targets":0,"placement_warnings":[],"embedded_targets":[]}
		for prop in manager.props:
			assert(not prop.targets.is_empty())
			report.targets += prop.targets.size()
			var at: Vector3 = prop.global_position
			var floor_hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*2.6,at-Vector3.UP*.2,1))
			if floor_hit.is_empty() or absf(floor_hit.position.y-at.y)>.14:
				report.placement_warnings.append({"prop":str(prop.name),"at":str(at),"ground":str(floor_hit.get("position","missing"))})
			for target in prop.targets:
				var shape = target.body.get_child(0)
				var probe = PhysicsShapeQueryParameters3D.new()
				var small = BoxShape3D.new()
				small.size = shape.shape.size*.85
				probe.shape = small
				probe.transform = shape.global_transform
				probe.collision_mask = 1
				var overlaps = game.get_world_3d().direct_space_state.intersect_shape(probe,1)
				if not overlaps.is_empty():report.embedded_targets.append({"prop":str(prop.name),"target":target.id,"body":str(overlaps[0].collider.get_path())})
		assert(report.placement_warnings.is_empty(),"Props must stand on their authored support height")
		assert(report.embedded_targets.is_empty(),"Targets must not intersect existing scenery")
		var first = manager.props[0]
		var focus: Vector3 = first.global_position+Vector3(1.5,.85,0)
		game.hud.hide()
		game.player.gun.hide()
		camera.make_current()
		camera.global_position = focus+Vector3(1.4,1.2,4.5)
		camera.look_at(focus)
		await capture(id+"-before")
		report["draw_calls_intact"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var old_navigation = game.arena.nav.navigation_mesh
		var shots_before: int = game.rules.shots
		var kills_before: int = game.rules.kills
		# Exercise real physics rays and resolve_shot in normal mode, not just hit().
		for prop in manager.props:
			for target in prop.targets:
				if target.broken:continue
				var shape: CollisionShape3D = target.body.get_child(0)
				var center: Vector3 = shape.global_position
				var query = PhysicsRayQueryParameters3D.create(center+Vector3(0,0,.5),center,32)
				var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
				assert(not hit.is_empty(),"Normal shot layer must find small props")
				game.resolve_shot(hit,query.from,hit.position,false)
				game.resolve_shot(hit,query.from,hit.position,false)
				assert(prop.targets.any(func(t):return t.broken))
		assert(game.arena.nav.navigation_mesh==old_navigation and not game.arena.navigation_dirty)
		assert(game.rules.shots==shots_before and game.rules.kills==kills_before)
		assert(get_nodes_in_group("prop_debris").size()<=10)
		await capture(id+"-after")
		manager.restore()
		for prop in manager.props:
			assert(prop.broken_count==0)
			for target in prop.targets:assert(target.mesh.visible and target.body.collision_layer==32 and not target.broken)
		# Frenzy destroys a two-hit object in one hit. Reset cancels delayed can cascades.
		var target = first.targets[0]
		first.hit(target.id,first.global_position+Vector3.UP,true)
		assert(target.broken)
		manager.restore()
		await create_timer(.5).timeout
		for prop in manager.props:assert(prop.broken_count==0)
		for prop in manager.props:
			if prop.kind!="cans":continue
			prop.hit(0,prop.global_position+Vector3.UP,false)
			game.pause_run()
			await create_timer(.6).timeout
			assert(prop.targets.filter(func(t):return t.id>=3).all(func(t):return not t.broken))
			game.menu_action("resume")
			await create_timer(.6).timeout
			assert(prop.targets.filter(func(t):return t.id>=3).all(func(t):return t.broken))
		manager.restore()
		# Grenade uses LOS and the normal-mode prop blast path.
		var target_point: Vector3 = first.targets[0].body.get_child(0).global_position
		var wall = StaticBody3D.new()
		var blocker = CollisionShape3D.new()
		var block = BoxShape3D.new()
		block.size = Vector3(1.4,2.5,.12)
		blocker.shape = block
		wall.add_child(blocker)
		game.add_child(wall)
		wall.global_position = target_point+Vector3(0,0,.35)
		await physics_frame
		await process_frame
		first.blast(target_point+Vector3(0,0,.8),2)
		assert(first.broken_count==0,"A solid wall must block grenade damage")
		wall.free()
		await physics_frame
		game.grenade_blast(target_point+Vector3(0,0,.4),"")
		assert(first.broken_count>0,"A nearby unobstructed grenade must break props in normal mode")
		game.start_run()
		game.begin_running()
		game.set_physics_process(false)
		for prop in manager.props:assert(prop.broken_count==0)
		game.rules.elapsed = game.rules.duration
		game.rules.active = false
		game.start_finale()
		assert(manager.props.all(func(p):return not p.visible))
		manager.restore()
		assert(manager.props.all(func(p):return p.visible and p.broken_count==0))
		evidence.append(report)
		game.pause_run()
		game.menu_action("menu")
		game.hud.show()
		game.player.gun.show()
		game.player.camera.make_current()
		print("INTERACTIVE_MAP_PASS ",JSON.stringify(report))
	var f = FileAccess.open(OUT+("checks-headless.json" if DisplayServer.get_name()=="headless" else "checks.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(evidence,"\t")+"\n")
	print("INTERACTIVE_PROPS_PASS: 9 maps, normal/frenzy rays, grenade LOS, reset and unchanged navigation")
	game.music.stop()
	game.clear_round()
	await create_timer(.6).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
