extends SceneTree

const STEP = 1.0/60.0
const Grenade = preload("res://scripts/grenade.gd")
const Structure = preload("res://scripts/destructible.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.title_frame_ready:await process_frame
	game.qa_mode = true
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	start_round("")
	if game.rules.mission:
		game.request_grenade()
		assert(game.grenade_stock==0 and game.grenade_throw_time==0)
		print("GRENADE_MISSION_PASS")
		await finish_check()
		return
	var key = InputEventKey.new()
	key.physical_keycode = KEY_G
	assert(InputMap.event_is_action(key,"grenade"))
	for style in ["","comedy","roach"]:
		start_round(style)
		assert(game.grenade_stock==3)
		var icon_rect: Rect2 = game.hud.grenade_stock_rect(0)
		var cartridge: Rect2 = game.hud.cartridge_rect(0)
		assert(is_equal_approx(icon_rect.position.y,cartridge.position.y))
		assert(is_equal_approx(icon_rect.size.y,cartridge.size.y))
		if style.is_empty():await capture("hud-ready")
		game.request_grenade()
		var ammo: int = game.ammo
		game.shoot()
		assert(game.ammo==ammo and game.grenade_stock==3)
		await step(5)
		assert(game.grenade_stock==3 and game.player.held_grenade.visible)
		assert(game.hud.grenade_eject_time==0)
		await capture("throw-"+(style if not style.is_empty() else "frag"))
		await step(3)
		assert(game.grenade_stock==2 and game.grenades.size()==1)
		assert(game.hud.grenade_eject_time>0)
		if style.is_empty():await capture("hud-eject")
		var grenade = game.grenades[0]
		assert(grenade.style==style and grenade.visual.scene_file_path==Grenade.MODELS[style].resource_path)
		game.pause_run()
		var remaining: float = grenade.fuse
		game._physics_process(.35)
		assert(grenade.fuse==remaining)
		game.menu_action("resume")
		await step(66)
		assert(game.grenades.is_empty())
		assert(game.grenade_stock==2)

	game.ammo = 4
	game.reload_weapon()
	var remaining_reload: float = game.reload_time
	game.request_grenade()
	game._physics_process(STEP)
	assert(game.grenade_throw_time>0 and game.reload_time<remaining_reload and game.ammo==4)
	start_round("")
	var floor_at = Vector3(4,50,12)
	box(floor_at-Vector3.UP*.25,Vector3(42,.5,42))
	game.player.position = floor_at
	game.player.rotation = Vector3.ZERO
	await physics_frame
	game.request_grenade()
	await step(8)
	var grenade = game.grenades[0]
	var origin: Vector3 = grenade.position
	await step(65)
	var travel: float = Vector2(grenade.position.x-origin.x,grenade.position.z-origin.z).length()
	assert(travel>=10 and travel<=14.6,"Flat throw traveled %.2f m"%travel)
	await step(1)
	assert(game.grenades.is_empty())
	var wall = box(floor_at+Vector3(0,1.3,-3),Vector3(6,3,.2))
	await physics_frame
	game.request_grenade()
	await step(8)
	grenade = game.grenades[0]
	await step(18)
	assert(grenade.velocity.z>0 and grenade.global_position.z>wall.global_position.z)
	game.invulnerable = 0
	game.damage_player(999)
	assert(game.grenade_stock==1 and game.respawn_time>0 and game.grenades.has(grenade))
	await step(58)
	assert(game.grenades.is_empty())
	for _tick in range(130):game._physics_process(STEP)
	assert(game.grenade_stock==1 and game.respawn_time==0)
	game.request_grenade()
	game.invulnerable = 0
	game.damage_player(999)
	await step(16)
	assert(game.grenade_stock==1 and game.grenades.is_empty(),"Death before release preserves inventory")
	assert(game.hud.grenade_eject_time==0)
	game.respawn_time = 0
	game.player.enabled = true
	game.health = game.MAX_HEALTH
	game.invulnerable = 10
	await step(50)
	game.request_grenade()
	await step(8)
	assert(game.grenade_stock==0)
	await step(45)
	game.request_grenade()
	assert(game.grenade_throw_time==0 and game.grenade_stock==0)
	game.rules.elapsed = 59.999
	game._physics_process(STEP)
	assert(game.finale_active and game.grenades.is_empty() and game.grenade_stock==0)
	game.finish_run()
	game.menu_action("menu")
	start_round("")
	assert(game.grenade_stock==3)

	var center = Vector3(36,51,12)
	var near = foe(center+Vector3(0,-1,-4))
	var outer = foe(center+Vector3(0,-1,7))
	var distant = foe(center+Vector3(0,-1,-8))
	var covered = foe(center+Vector3(2,-1,0))
	var above = foe(center+Vector3(0,1.5,0))
	var shield = box(center+Vector3(1,0,0),Vector3(.2,2,1.5))
	box(center+Vector3(0,1.2,0),Vector3(1.5,.2,1.5))
	var structure = Structure.new()
	structure.game = game
	structure.arena = game.arena
	structure.scenery = true
	structure.bounds = AABB(center+Vector3(-6.3,-.5,-.5),Vector3(.6,1,1))
	game.add_child(structure)
	game.arena.structures.append(structure)
	var panel = box(center+Vector3(-6,0,0),Vector3(.6,1,1))
	panel.collision_layer = game.SCENERY_TARGET_LAYER
	structure.register(panel)
	game.player.position = center+Vector3(0,-1,4)
	game.invulnerable = 0
	var barrel = game.arena.barrels[0]
	var barrel_start: Vector3 = barrel.global_position
	barrel.global_position = center+Vector3(-1,-.65,6)
	await physics_frame
	game.grenade_blast(center,"")
	assert(near.dead and outer.health==outer.MAX_HEALTH-1 and covered.health==covered.MAX_HEALTH and above.health==above.MAX_HEALTH)
	assert(distant.health==distant.MAX_HEALTH)
	assert(game.rules.kills==1 and game.rules.headshots==0 and game.health==game.MAX_HEALTH-30)
	assert(barrel.fuse>0 and structure.hits==0)
	barrel.global_position = barrel_start
	shield.queue_free()
	game.destroy_active = true
	await physics_frame
	game.grenade_blast(center,"roach")
	assert(structure.hits==1)
	structure.ignite_hit(panel.position)
	assert(structure.hits==2 and structure.burn_time>0)
	game.arena.structures.erase(structure)
	structure.queue_free()
	panel.queue_free()

	start_round("comedy")
	var booth = game.comedy_toilet
	assert(is_instance_valid(booth))
	var charge = booth.charge_bodies[0]
	await physics_frame
	game.grenade_blast(charge.global_position+Vector3.UP*.5,"comedy")
	assert(booth.spent)
	await capture("stink-blast")
	print("GRENADE_PASS: three styles, release stock, fuse pause, travel and wall bounce, death/respawn, empty, finale, cover and floor, self damage, barrel and toilet chains, frenzy scenery")
	await finish_check()

func finish_check() -> void:
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	quit()

func start_round(style: String) -> void:
	game.comedy_mode = style
	game.start_run()
	game.begin_running()
	game.rules.continuous_spawns = false
	for enemy in game.enemies.get_children():
		game.enemies.remove_child(enemy)
		enemy.queue_free()

func foe(at: Vector3) -> Node3D:
	var actor = game.spawn_enemy(at,false)
	actor.set_physics_process(false)
	return actor

func box(at: Vector3, extent: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = at
	var shape = BoxShape3D.new()
	shape.size = extent
	var collision = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	game.add_child(body)
	return body

func step(count: int) -> void:
	for _tick in range(count):
		await physics_frame
		game.update_grenades(STEP)

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/grenade-"+name+".png")
