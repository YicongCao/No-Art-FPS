extends CharacterBody3D

const ShotLine = preload("res://scripts/shot_line.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const HeadshotFX = preload("res://scripts/headshot_fx.gd")
const ComedyFX = preload("res://scripts/comedy_fx.gd")
const TOY_MODEL = "res://assets/models/toy/enemy.glb"
const RUSHER_MODEL = "res://assets/models/toy/rusher.glb"
const RUSHER_ORANGE = Color("ee641c")
static var rim_pass: ShaderMaterial

var game: Node
var space_visual = false
var patrol_brain: Node
var visual: Node3D
var agent: NavigationAgent3D
const MAX_HEALTH = 3
const BODY_SHOT_DAMAGE = 2
const BODY_HIT_DURATION = .16
const NOTICE_DISTANCE = 18.0
const DISENGAGE_DISTANCE = 22.0
const REAR_AIM_DURATION = 1.1
var health = MAX_HEALTH
var dead = false
var fast = false
var container_room: Node3D
var home_zone = "yard"
var patrol_offset = 0
var tracking_player = false
var reinforcement_rally := Vector3.INF
var rush_state = "CHASE"
var rush_time = 0.0
var rush_direction = Vector3.ZERO
var knife_arm: Node3D
var knife: Node3D
var slash_hit = false
const CLOSE_SHOT_RANGE = 8.0
const KNIFE_FRONT_DOT = .5 # 60 degrees to either side of the player's forward direction.
var dodge_direction = Vector3.ZERO
var dodge_time = 0.0
var dodge_cooldown = 0.0
var burn_ticks = 0
var burn_time = 0.0
var rush_warning: StandardMaterial3D
var blade_meshes: Array[Node] = []
var orange: StandardMaterial3D
var age = 0.0
var think = 0.0
var attack = 1.8
var windup = 0.0
var aim_duration = 0.0
var rear_warned = false
var glint: Sprite3D
var killer_glow: ShaderMaterial
var highlighted := false
var aim_offset = Vector3.ZERO
var aim_line: ShotLine
var death_time = 0.0
var headshot_death := false
var headshot_direction := Vector3.ZERO
var headshot_origin := Vector3.INF
var headshot_normal := Vector3.ZERO
var headshot_lean := Vector3.ZERO
var headshot_start_rotation := Vector3.ZERO
var head_core: MeshInstance3D
var walk_phase = 0.0
var hurt = 0.0
var body_hit_time = 0.0
var armor_hit: ShaderMaterial
var wounded := false
var wounded_spark_time := 0.0
var enemy_gun: Node3D
var limbs: Array[Node3D] = []
var limb_origins: Array[Vector3] = []
var head_area: Area3D
var comedy_head: Sprite3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1|4
	floor_snap_length = .4
	var body_shape = CollisionShape3D.new()
	var body = CapsuleShape3D.new()
	body.height = 1.48
	body.radius = .29
	body_shape.shape = body
	body_shape.position.y = .76
	add_child(body_shape)
	head_area = Area3D.new()
	head_area.collision_layer = 8
	head_area.collision_mask = 0
	head_area.set_meta("enemy",self)
	var hs = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = .22
	hs.shape = sphere
	hs.position.y = 1.70
	head_area.add_child(hs)
	add_child(head_area)
	var model: PackedScene = game.rusher_model if fast else game.enemy_model
	visual = (model if model else load(game.visual_path("rusher_enemy" if fast else "rifle_enemy",RUSHER_MODEL if fast else TOY_MODEL))).instantiate()
	add_child(visual)
	space_visual = game.session.visual_profile != null and not game.session.visual_profile.legacy_toy_materials
	if not space_visual:add_toy_rim(visual)
	if fast and space_visual:
		var arm = visual.find_child("RightArm",true,false)
		knife_arm = Node3D.new()
		visual.add_child(knife_arm)
		knife_arm.position = arm.position
		arm.reparent(knife_arm)
		knife = visual.find_child("MeleeBlade",true,false)
		blade_meshes = knife.find_children("*","MeshInstance3D",true,false)
		rush_warning = StandardMaterial3D.new()
		rush_warning.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rush_warning.albedo_color = Color("ffe38c")
	elif fast:
		orange = StandardMaterial3D.new()
		orange.albedo_color = RUSHER_ORANGE
		orange.roughness = .34
		orange.next_pass = toy_rim()
		for part in ["Torso","Vest","Helmet","LeftArm","RightArm","LeftLeg","RightLeg"]:
			var mesh = visual.find_child(part,true,false)
			if mesh:mesh.material_override = orange
		knife_arm = Node3D.new()
		visual.add_child(knife_arm)
		knife_arm.position = Vector3(.3,1.4,0)
		for part in ["RightArm","RightHand"]:
			visual.find_child(part,true,false).reparent(knife_arm)
		knife = preload("res://assets/models/toy/rusher_blade.glb").instantiate()
		knife_arm.add_child(knife)
		knife.position = Vector3(0,-.46,-.18)
		knife.rotation.x = PI
		knife_arm.rotation = Vector3(-.36,0,-.16)
	else:
		enemy_gun = visual.find_child("EnemyGun",true,false)
		var broken_vest = visual.find_child("BrokenVest",true,false) as Node3D
		if broken_vest:broken_vest.hide()
	if game.state in ["RUNNING","LOADING"]:set_comedy_head(game.comedy_mode)
	for part in ["LeftLeg","RightLeg","LeftArm","RightArm"]:
		var limb = visual.find_child(part,true,false)
		if limb:
			limbs.append(limb)
			limb_origins.append(limb.position)
	agent = NavigationAgent3D.new()
	# The voxel bake raises paths above the physical floor. Without this offset,
	# a ground-level agent never reaches even its first waypoint (.5 m > .45 m).
	agent.path_height_offset = game.arena.nav.navigation_mesh.cell_height*2.0
	agent.path_desired_distance = .45
	agent.target_desired_distance = .55
	agent.radius = .6
	agent.height = 1.8
	agent.neighbor_distance = 3.5
	agent.max_neighbors = 12
	agent.time_horizon_agents = 1.0
	agent.max_speed = 12.5
	agent.avoidance_enabled = true
	agent.velocity_computed.connect(apply_safe_velocity)
	add_child(agent)
	attack += randf()*.8
	if game.arena.uses_patrol(home_zone):
		var posts = game.arena.patrol_points(home_zone)
		patrol_offset = 1 if position.distance_to(posts[0])<position.distance_to(posts[1]) else 0

static func toy_rim() -> ShaderMaterial:
	if rim_pass==null:
		rim_pass = ShaderMaterial.new()
		rim_pass.shader = preload("res://assets/shaders/toy_rim.gdshader")
	return rim_pass

# Imported materials are shared by every enemy instance, so this runs once per material.
static func add_toy_rim(model: Node3D) -> void:
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for index in mesh.get_surface_override_material_count():
			var paint := mesh.get_active_material(index) as StandardMaterial3D
			if paint and paint.next_pass==null and not paint.emission_enabled:paint.next_pass = toy_rim()

func animate_mechanical_knees(stride: float) -> void:
	for i in range(2):
		var side = "Left" if i==0 else "Right"
		var knee = visual.find_child(side+"Knee",true,false)
		var foot = visual.find_child(side+"Foot",true,false)
		if knee:knee.rotation.x = maxf(0,sin(walk_phase+float(i)*PI))*.5*stride
		if foot:foot.rotation.x = -sin(walk_phase+float(i)*PI)*.16*stride

func set_comedy_head(mode: String) -> void:
	if mode.is_empty() or comedy_head:return
	for part in ["Head","Helmet","Visor"]:visual.find_child(part,true,false).hide()
	var art = ComedyFX.ROACH_ART if mode=="roach" else ComedyFX.POOP_ART
	comedy_head = ComedyFX.sprite(art[1 if fast else 0],.55)
	comedy_head.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	comedy_head.position.y = 1.72
	visual.add_child(comedy_head)

func _physics_process(delta: float) -> void:
	if game.state=="RUNNING" and body_hit_time>0:
		update_body_hit(delta)
	if dead:
		if game.state!="RUNNING":return
		death_time += delta
		if headshot_death:
			var pulse := smoothstep(0,.07,death_time)*(1-smoothstep(.12,.38,death_time))
			visual.rotation.x = headshot_start_rotation.x+headshot_lean.x*pulse
			if is_instance_valid(head_core):
				head_core.visible = death_time<.22
				head_core.scale = Vector3.ONE*(1-smoothstep(.04,.22,death_time)*.85)
			if death_time<.075 and not game.reduced_motion:
				visual.rotation.z = headshot_start_rotation.z+headshot_lean.z*pulse
				return
		visual.rotation.z = lerpf(visual.rotation.z,1.48,delta*9)
		visual.position.y = lerpf(visual.position.y,-.35,delta*5)
		if death_time > 1.4:queue_free()
		return
	if game.state != "RUNNING":return
	if wounded:
		wounded_spark_time -= delta
		if wounded_spark_time<=0:
			wounded_spark_time = randf_range(.36,.58)
			if not game.reduced_motion:
				game.spark(global_position+Vector3(0,1.33,0)-global_basis.z*.21,Color("ff7b38"),.062,.09)
	if patrol_brain!=null:
		patrol_brain.advance(delta)
		return
	if burn_ticks>0:
		burn_time -= delta
		if burn_time<=0:
			burn_time = .25
			burn_ticks -= 1
			game.fire_effect(global_position+Vector3.UP,.5)
			take_damage(1)
			if dead:return
	if is_instance_valid(container_room) and container_room.progress<1:
		velocity = Vector3.ZERO
		agent.velocity = Vector3.ZERO
		return
	age += delta
	dodge_cooldown = maxf(0,dodge_cooldown-delta)
	hurt = maxf(0,hurt-delta)
	if fast:
		process_rusher(delta)
		return
	var to_player = game.player.global_position-global_position
	var distance = to_player.length()
	var sense_distance = DISENGAGE_DISTANCE if tracking_player else NOTICE_DISTANCE
	var noticed = distance<=sense_distance
	if noticed!=tracking_player:
		tracking_player = noticed
		think = 0
	if tracking_player and to_player.length_squared()>.1:
		rotation.y = lerp_angle(rotation.y,atan2(-to_player.x,-to_player.z),delta*8)
	var has_patrol = game.arena.uses_patrol(home_zone)
	if reinforcement_rally.is_finite() and global_position.distance_to(reinforcement_rally)<1.2:
		reinforcement_rally = Vector3.INF
	var rallying = reinforcement_rally.is_finite() and not tracking_player
	think -= delta
	if think <= 0:
		think = .35+randf()*.15
		if tracking_player and not has_patrol:
			var offset = Vector3.ZERO
			if distance < 13:
				var angle = age*.35+float(get_instance_id()%7)
				offset = Vector3(cos(angle),0,sin(angle))*8
			agent.target_position = game.player.global_position+offset
		elif rallying:
			agent.target_position = reinforcement_rally
		elif has_patrol:
			if tracking_player and distance>6 and game.arena.enemy_zone(game.player.global_position)==home_zone:
				agent.target_position = game.player.global_position
			else:
				var posts = game.arena.patrol_points(home_zone)
				if global_position.distance_to(posts[patrol_offset])<.8:
					patrol_offset = (patrol_offset+1)%posts.size()
				agent.target_position = posts[patrol_offset]
	var dir = Vector3.ZERO
	if tracking_player or has_patrol or rallying:
		var step = agent.get_next_path_position()-global_position
		step.y = 0
		if step.length_squared()>.0025 and not agent.is_navigation_finished():dir = step.normalized()
	if not tracking_player and not dir.is_zero_approx():
		rotation.y = lerp_angle(rotation.y,atan2(-dir.x,-dir.z),delta*8)
	var speed = 4.1 if rallying else 2.5
	if windup > 0:speed *= .25
	velocity.x = dir.x*speed
	velocity.z = dir.z*speed
	if not is_on_floor():velocity.y -= 20*delta
	agent.velocity = steer_around_neighbors(Vector3(velocity.x,0,velocity.z))
	var movement = Vector2(get_real_velocity().x,get_real_velocity().z).length()
	walk_phase += delta*movement*3
	var stride := minf(movement/speed,1.0)
	for i in range(limbs.size()):
		if i<2:
			limbs[i].rotation.x = sin(walk_phase+float(i%2)*PI)*.44*stride
		else:
			limbs[i].rotation.x = sin(walk_phase)*.06*stride
		limbs[i].position = limb_origins[i]
	if space_visual:animate_mechanical_knees(stride)
	if enemy_gun:enemy_gun.rotation.x = sin(walk_phase)*.06*stride
	visual.position.y = absf(sin(walk_phase))*.035
	visual.rotation.z = sin(age*40)*hurt*.25
	if global_position.y < -5:queue_free()
	advance_ranged_attack(delta,tracking_player)

func advance_ranged_attack(delta: float, can_aim: bool) -> void:
	if not patrol_brain or can_aim:attack -= delta
	if not can_aim or not game.rules.active or game.respawn_time>0:
		cancel_ranged_aim()
		return
	if windup<=0 and attack>0:return
	var starting = windup<=0
	if starting:
		aim_offset = Vector3(randf_range(-.25,.25),1.1,randf_range(-.25,.25))
	var origin = ranged_origin()
	var rear: bool = game.is_behind_player(origin)
	var target: Vector3 = game.player.global_position+aim_offset
	var sight = PhysicsRayQueryParameters3D.create(origin,target,1)
	if not get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
		cancel_ranged_aim()
		attack = .1
		return
	if starting:
		if not game.reserve_ranged_aim(self):
			attack = randf_range(.12,.24)
			return
		aim_duration = randf_range(.5,1.0)
		windup = aim_duration
		if not aim_line:
			aim_line = ShotLine.new()
			aim_line.name = "AimLine"
			add_child(aim_line)
	elif rear and game.rear_aiming_enemy()!=self:
		cancel_ranged_aim()
		attack = randf_range(.12,.24)
		return
	if rear and not rear_warned:
		rear_warned = true
		aim_duration = REAR_AIM_DURATION
		windup = aim_duration
		game.play_world_sound("enemy_raise",origin,-8)
	elif not starting:
		windup = maxf(0,windup-delta)
		if windup==0:
			cancel_ranged_aim()
			game.enemy_shoot(origin,shot_target(origin,target),self)
			attack = 2.3 if patrol_brain else 1.8+randf()*1.2
			return
	var progress = 1.0-windup/aim_duration
	aim_line.material_override.albedo_color = Color("d6dce390").lerp(Color("8a2a2aed"),progress)
	aim_line.set_segment(origin,target,lerpf(.018,.031,progress))
	update_glint(origin,progress)

# Misses clear the player's 0.3 m capsule but stay inside the near-miss whiz radius.
func shot_target(origin: Vector3, aimed: Vector3) -> Vector3:
	if randf()<game.enemy_hit_chance:return aimed
	var side := origin.direction_to(aimed).cross(Vector3.UP).normalized()
	var lateral := randf_range(.65,1.05)*(1.0 if randf()<.5 else -1.0)
	return aimed+side*lateral+Vector3.UP*randf_range(-.1,.55)

func set_killer_highlight(active: bool) -> void:
	if killer_glow==null:
		killer_glow = ShaderMaterial.new()
		killer_glow.shader = preload("res://assets/shaders/killer_highlight.gdshader")
	for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
		if mesh.material_overlay==armor_hit and armor_hit!=null:continue
		mesh.material_overlay = killer_glow if active else null
	highlighted = active

func update_glint(origin: Vector3, progress: float) -> void:
	if glint==null:
		glint = Sprite3D.new()
		glint.name = "MuzzleGlint"
		glint.texture = preload("res://assets/ui/muzzle-glint.svg")
		glint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glint.shaded = false
		glint.pixel_size = .006
		glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(glint)
	glint.global_position = origin
	var pulse := 1.0 if game.reduced_motion else .85+.15*sin(Time.get_ticks_msec()*.025)
	glint.scale = Vector3.ONE*lerpf(.45,1.15,progress)*pulse
	glint.modulate = Color(1,1,1,lerpf(.35,1.0,progress))
	glint.show()

func ranged_origin() -> Vector3:
	return visual.to_global(Vector3(.22,1.12,-.58))

func cancel_ranged_aim() -> void:
	game.ranged_aimers.erase(self)
	windup = 0
	rear_warned = false
	if aim_line:aim_line.hide()
	if glint:glint.hide()

func _exit_tree() -> void:
	if is_instance_valid(game):game.ranged_aimers.erase(self)

func steer_around_neighbors(desired: Vector3) -> Vector3:
	if desired.length_squared()<.01:return desired
	var heading = desired.normalized()
	var sidestep = 0.0
	for other in game.live_enemies():
		if other==self:continue
		var offset = other.global_position-global_position
		if absf(offset.y)>1.2:continue
		offset.y = 0
		var distance = offset.length()
		if distance<2.8 and distance>.01 and heading.dot(offset/distance)>.35:
			sidestep = maxf(sidestep,(1-distance/2.8)*1.8)
	# Give oncoming pairs the same passing convention, avoiding symmetric RVO stalls.
	return (desired+heading.cross(Vector3.UP)*sidestep).limit_length(desired.length())

func apply_safe_velocity(safe_velocity: Vector3) -> void:
	# Navigation callbacks also arrive while menus or test fixtures freeze actors.
	if dead or game.state!="RUNNING" or not is_physics_processing():return
	if is_instance_valid(container_room) and container_room.progress<1:return
	if not fast or rush_state=="CHASE":
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z
	move_and_slide()

func can_see_player() -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.4,0),game.player.global_position+Vector3(0,1.1,0),1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_hit(is_head: bool, body_one_shot: bool = false, point: Vector3 = Vector3.INF, direction: Vector3 = Vector3.ZERO, normal: Vector3 = Vector3.ZERO) -> void:
	if dead:return
	if is_head:
		headshot_origin = point
		headshot_direction = direction
		headshot_normal = normal
	take_damage(MAX_HEALTH if is_head or body_one_shot else BODY_SHOT_DAMAGE,is_head)

func play_headshot_kill() -> void:
	if headshot_death:return
	headshot_death = true
	body_hit_time = 0
	headshot_start_rotation = visual.rotation
	var incoming := headshot_direction
	if incoming.length_squared()<.01:incoming = game.player.camera.global_position.direction_to(global_position+Vector3.UP*1.7)
	var local_direction: Vector3 = global_basis.inverse()*incoming
	headshot_lean = Vector3(local_direction.z*.30,0,-local_direction.x*.22)
	if game.reduced_motion:headshot_lean *= .2
	var point := headshot_origin if headshot_origin.is_finite() else global_position+Vector3.UP*1.7
	var fx = HeadshotFX.new()
	fx.name = "HeadshotBurst"
	game.effects.add_child(fx)
	fx.setup(game,point,incoming,headshot_normal,fast,game.comedy_mode.is_empty(),global_position.y+.04)
	if not game.comedy_mode.is_empty():return
	for part in ["Helmet","Visor"]:
		var node = visual.find_child(part,true,false) as Node3D
		if node:node.hide()
	# The original dark mechanical head remains, exposed beneath the detached shell.
	var head = visual.find_child("Head",true,false) as Node3D
	if head:
		head_core = MeshInstance3D.new()
		head_core.name = "HeadshotCore"
		head_core.mesh = HeadshotFX.reactor_mesh
		head_core.material_override = CombatFX.paint_for(false)
		head_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.add_child(head_core)
		head_core.position = Vector3(0,.02,-.17)

func apply_nonlethal_hit() -> void:
	if armor_hit==null:
		armor_hit = ShaderMaterial.new()
		armor_hit.shader = preload("res://assets/shaders/armor_hit.gdshader")
		var targets := ["Torso","BackPlate","LeftArm"] if fast else ["Torso","Vest","BrokenVest","RightPad"]
		for part in targets:
			var panel = visual.find_child(part,true,false) as MeshInstance3D
			if panel:panel.material_overlay = armor_hit
	var level := mini(MAX_HEALTH-health,2)
	armor_hit.set_shader_parameter("damage_level",level)
	body_hit_time = BODY_HIT_DURATION
	update_body_hit(0)
	spawn_armor_chips()
	if not wounded and level>=2:
		wounded = true
		wounded_spark_time = .18
		# Swap/snap off 3D outer toy armor to expose shattered ribs, conduits & inner frame!
		if fast:
			for piece in ["ChestPlate","LeftFin","LeftHorn"]:
				var part_node = visual.find_child(piece,true,false) as Node3D
				if part_node:part_node.hide()
		else:
			for piece in ["LeftPad","LeftPadTrim","Vest"]:
				var pad_node = visual.find_child(piece,true,false) as Node3D
				if pad_node:pad_node.hide()
			var right_pad = visual.find_child("RightPad",true,false) as Node3D
			if right_pad:right_pad.rotation += Vector3(.18,0,-.26)
			var broken_vest = visual.find_child("BrokenVest",true,false) as Node3D
			if broken_vest:broken_vest.show()
		# Visibly stagger torso & knock helmet askew (head hitbox on root stays untouched).
		var torso_node = visual.find_child("Torso",true,false) as Node3D
		if torso_node:torso_node.rotation = Vector3(.09,0,.08 if fast else -.08)
		var helmet = visual.find_child("Helmet",true,false) as Node3D
		if helmet:helmet.rotation = Vector3(-.07,-.10 if fast else .09,.19)
		# Add an exposed hot overload spark node on the breached armor socket.
		var ember := MeshInstance3D.new()
		ember.name = "WoundedSpark"
		var spark_mesh := BoxMesh.new()
		spark_mesh.size = Vector3(.085,.085,.045)
		var spark_mat := StandardMaterial3D.new()
		spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_mat.albedo_color = Color("ff9d3b")
		spark_mesh.material = spark_mat
		ember.mesh = spark_mesh
		ember.position = Vector3(0,1.34,-.17) if fast else Vector3(-.39,1.45,-.06)
		ember.rotation = Vector3(.4,.5,.6)
		visual.add_child(ember)

func spawn_armor_chips() -> void:
	if game==null or not is_instance_valid(game.effects):return
	var fx := CombatFX.new()
	fx.name = "EnemyArmorChips"
	fx.game = game
	fx.duration = .65
	game.effects.add_child(fx)
	var center := global_position+Vector3(0 if fast else -.22,1.36,0)-global_basis.z*.18
	var forward := -global_basis.z
	var side := global_basis.x
	var palette: Array = [Color("f0e7d4"),Color("ee641c"),Color("4ce8f8")] if fast else [Color("df3f35"),Color("f0e7d4"),Color("4e5d75")]
	var count := 5 if game.reduced_motion else 9
	for i in range(count):
		var spread := (float(i)/maxf(count-1,1)-.5)*2.0
		var vel := forward*fx.rng.randf_range(1.6,3.2)+side*(spread*2.6)+Vector3.UP*fx.rng.randf_range(1.8,3.4)
		var sz := Vector3(fx.rng.randf_range(.075,.135),fx.rng.randf_range(.065,.115),fx.rng.randf_range(.028,.048))
		fx.chunk(center+side*(spread*.14),sz,palette[i%palette.size()],vel,global_position.y+.04)
	for i in range(2 if game.reduced_motion else 4):
		fx.bloom(center+side*float(i-1.5)*.08,fx.rng.randf_range(.065,.105),Color("ffb347"))
	fx.show_pieces(true)

func update_body_hit(delta: float) -> void:
	body_hit_time = maxf(0,body_hit_time-delta)
	var strength = body_hit_time/BODY_HIT_DURATION
	armor_hit.set_shader_parameter("flash",strength*strength)
	visual.rotation.x = .26*strength*strength

func ignite() -> void:
	if dead:return
	burn_ticks = 3
	burn_time = .25

func evade_shot(origin: Vector3) -> void:
	if not fast or dead or game.state!="RUNNING" or global_position.distance_to(origin)<=CLOSE_SHOT_RANGE:return
	if dodge_cooldown>0 or rush_state=="DODGE":return
	var forward = global_position-origin
	forward.y = 0
	var side = forward.normalized().cross(Vector3.UP)
	for sign in [1.0,-1.0]:
		var direction = side*sign
		var shape = CapsuleShape3D.new()
		shape.radius = .33
		shape.height = 1.8
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = global_position+Vector3.UP*.9
		query.motion = direction*1.6
		query.collision_mask = 1|4
		query.exclude = [get_rid()]
		var space = get_world_3d().direct_space_state
		var travel = space.cast_motion(query)
		var ahead = global_position+direction*1.6
		var ground = PhysicsRayQueryParameters3D.create(ahead+Vector3.UP*.3,ahead-Vector3.UP*.7,1)
		if travel[0]<.95 or space.intersect_ray(ground).is_empty():continue
		dodge_direction = direction
		dodge_time = .16
		dodge_cooldown = .28
		rush_state = "DODGE"
		game.play_world_sound("hit",global_position+Vector3.UP,-19)
		return

func take_damage(amount: int, is_head: bool = false, from_finale: bool = false) -> void:
	if dead or not (game.rules.active or from_finale):return
	var previous_health = health
	health -= amount
	hurt = .2
	if health <= 0:
		dead = true
		cancel_ranged_aim()
		agent.avoidance_enabled = false
		collision_layer = 0
		collision_mask = 0
		head_area.collision_layer = 0
		if not from_finale:game.on_kill(self,is_head)
	elif health < previous_health and not from_finale:
		apply_nonlethal_hit()

func start_slash() -> void:
	rush_state = "WINDUP"
	rush_time = .4
	rush_direction = game.player.global_position-global_position
	rush_direction.y = 0
	rush_direction = rush_direction.normalized()
	rotation.y = atan2(-rush_direction.x,-rush_direction.z)
	slash_hit = false
	game.play_world_sound("charge",global_position+Vector3.UP,-9)

func set_rush_warning(active: bool) -> void:
	if space_visual:
		for mesh in blade_meshes:mesh.material_overlay = rush_warning if active else null
	elif orange:
		orange.albedo_color = Color("fff1b7") if active else RUSHER_ORANGE

func recover_charge() -> void:
	rush_state = "RECOVER"
	rush_time = .65
	velocity.x = 0
	velocity.z = 0
	set_rush_warning(false)

func process_rusher(delta: float) -> void:
	var to_player = game.player.global_position-global_position
	var distance = to_player.length()
	var to_enemy = Vector3(-to_player.x,0,-to_player.z).normalized()
	var player_forward: Vector3 = -game.player.global_basis.z
	var in_front = player_forward.dot(to_enemy)>=KNIFE_FRONT_DOT
	attack -= delta
	var direction = Vector3.ZERO
	var speed = 0.0
	match rush_state:
		"DODGE":
			dodge_time -= delta
			direction = dodge_direction
			speed = 10.0
			visual.rotation.z = -dodge_direction.dot(global_basis.x)*.22
			if dodge_time<=0:
				rush_state = "CHASE"
				think = 0
		"CHASE":
			think -= delta
			if think<=0:
				think = .25
				agent.target_position = game.player.global_position
			direction = agent.get_next_path_position()-global_position
			direction.y = 0
			direction = direction.normalized() if direction.length()>.15 else Vector3.ZERO
			speed = 5.8
			if direction.length_squared()>.01:rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*10)
			if attack<=0 and in_front and distance<1.85 and absf(to_player.y)<1.0 and game.respawn_time<=0 and can_see_player():
				start_slash()
				speed = 0
		"WINDUP":
			rush_time -= delta
			set_rush_warning(int(rush_time*12)%2==0)
			knife_arm.rotation.x = lerpf(0,-2.35,clampf(1-rush_time/.4,0,1))
			if rush_time<=0:
				if in_front:
					rush_state = "SLASH"
					rush_time = .24
					set_rush_warning(false)
				else:
					recover_charge()
		"SLASH":
			rush_time -= delta
			var swing = clampf(1-rush_time/.24,0,1)
			knife_arm.rotation.x = lerpf(-2.35,.65,swing)
			if swing>=.45 and not slash_hit:
				slash_hit = true
				var flat = Vector3(to_player.x,0,to_player.z)
				if in_front and flat.length()<2.1 and absf(to_player.y)<1 and rush_direction.dot(flat.normalized())>.5 and can_see_player():
					game.damage_player(34,global_position+Vector3.UP,self,"melee")
			if rush_time<=0:recover_charge()
		"RECOVER":
			rush_time -= delta
			knife_arm.rotation.x = .65*maxf(0,rush_time/.65)
			if rush_time<=0:
				rush_state = "CHASE"
				attack = .15
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	if not is_on_floor():velocity.y -= 20*delta
	var desired = Vector3(velocity.x,0,velocity.z)
	agent.velocity = steer_around_neighbors(desired) if rush_state=="CHASE" else desired
	var movement = Vector2(get_real_velocity().x,get_real_velocity().z).length()
	walk_phase += delta*movement*3
	for i in range(limbs.size()):
		if limbs[i].name!="RightArm":limbs[i].rotation.x = sin(walk_phase+float(i%2)*PI)*.55*minf(movement/5.8,1)
	if rush_state=="CHASE":
		if space_visual:animate_mechanical_knees(minf(movement/5.8,1))
		knife_arm.rotation.x = -.36+sin(walk_phase)*.18
		knife_arm.rotation.z = -.16
	else:
		knife_arm.rotation.z = 0.0
	visual.position.y = -.12 if rush_state=="WINDUP" else absf(sin(walk_phase))*.035
	if rush_state!="DODGE":visual.rotation.z = sin(age*40)*hurt*.25
	if global_position.y < -5:queue_free()
