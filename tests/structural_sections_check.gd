extends SceneTree

const TARGETS = {
	"yard": [
		["EastStairs",Vector3(7.6,.05,.5),Vector3(7.6,.8,-4.4)],
		["warehouse",Vector3(18,.05,-2.5),Vector3(24,2.6,-2.5)]],
	"amusement_park": [
		["SouthStationStairs",Vector3(25.6,.05,15),Vector3(25.6,1.15,9)]],
	"last_ferry": [
		["AftRamp",Vector3(-1.6,.05,14),Vector3(-1.6,1.35,7.2)],
		["Wheelhouse",Vector3(1,.05,-15.2),Vector3(1,1.5,-21)]],
	"night_studio": [
		["Props/Acoustic22_77",Vector3(7.9,.05,-3.3),Vector3(11,1.6,-3.3)],
		["Props/EastAccessRamp",Vector3(8.75,.05,-.3),Vector3(8.75,.85,-5.7)],
		["Props/SouthWall1",Vector3(-5.5,.05,12.4),Vector3(-5.5,1.5,17)],
		["Props/ControlPartition",Vector3(-16.2,.11,-12.5),Vector3(-16.2,2.2,-14.24)]]
}
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(800):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	var arena = game.arena
	var map_id: String = arena.map_id
	game.qa_mode = true
	TranslationServer.set_locale("zh")
	assert(game.hud.tr("DESTROY ALL")=="狂暴模式")
	for ch in "狂暴模式":assert(game.hud.font.has_char(ch.unicode_at(0)))
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	var rebuilt: Array[Node] = []
	for target in TARGETS[map_id]:
		var part = arena.warehouse_structure if target[0]=="warehouse" else arena.get_node(target[0])
		game.player.position = target[1]
		await physics_frame
		if not game.destroy_active:
			shoot_at(target[2])
			assert(part.hits==0 and not part.collapsed,"Normal shots cannot destroy "+str(part.name))
			game.rules.elapsed = 45
			game._physics_process(0)
			assert(game.destroy_active)
			if map_id=="night_studio":await capture("notice")
		shoot_at(target[2])
		assert(part.hits==1 and not part.collapsed,"First shot did not hit "+str(part.name))
		shoot_at(target[2])
		assert(part.hits==2 and part.burn_time>0,"Second shot did not prime "+str(part.name))
		for _tick in range(40):await physics_frame
		assert(part.collapsed,"Did not collapse "+str(part.name))
		for body in part.collision_states:assert(body.collision_layer==0)
		for item in part.parts:assert(not item.visible)
		rebuilt.append(part)
		if part.structural_section:await capture(str(part.name))
		print("BREAK_PART_PASS ",map_id," ",part.name)
	if map_id=="yard":
		assert(not arena.get_node("WestStairs").collapsed and not arena.deck_structure.collapsed)
	if map_id=="amusement_park":
		assert(not arena.get_node("NorthStationStairs").collapsed and arena.get_node("StationFoundation").visible)
	if map_id=="last_ferry":
		assert(not arena.get_node("ForeRamp").collapsed and arena.get_node("Catwalk").visible)
	if map_id=="night_studio":
		assert(not game.achievements.unlocked_badge("studio"))
		var ray = PhysicsRayQueryParameters3D.create(Vector3(-5.5,1.4,16.3),Vector3(-5.5,1.4,18),1)
		var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty() and hit.position.z>17.19,"Outer shell leaves its safety boundary")
	game.rules.elapsed = 60
	game.rules.active = false
	game.start_finale()
	assert(game.finale_active)
	game.start_run()
	for _tick in range(300):
		await physics_frame
		if not arena.navigation_dirty and not arena.navigation_baking:break
	assert(not arena.restore_navigation_pending and not arena.navigation_dirty and not arena.navigation_baking)
	for part in rebuilt:
		assert(not part.collapsed and part.hits==0)
		for body in part.collision_states:assert(body.collision_layer==part.collision_states[body])
		for item in part.parts:assert(item.visible)
	print("BREAK_MAP_PASS ",map_id)
	if DisplayServer.get_name()=="headless":
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	game.queue_free()
	await process_frame
	quit()

func shoot_at(point: Vector3) -> void:
	var direction = game.player.camera.global_position.direction_to(point)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.player.crosshair_offset = Vector2.ZERO
	game.fire_time = 0
	game.shoot()

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/rage-%s-%s.png"%[game.arena.map_id,label])
