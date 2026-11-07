extends CharacterBody3D

const ShotLine = preload("res://scripts/shot_line.gd")

var game: Node
var patrol_brain: Node
var visual: Node3D
var agent: NavigationAgent3D
const MAX_HEALTH = 3
const BODY_HIT_DURATION = .16
var health = MAX_HEALTH
var dead = false
var fast = false
var container_room: Node3D
var home_zone = "yard"
var patrol_offset = 0
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
var orange: StandardMaterial3D
var age = 0.0
var think = 0.0
var attack = 1.8
var windup = 0.0
var aim_duration = 0.0
var aim_offset = Vector3.ZERO
var aim_line: ShotLine
var death_time = 0.0
var walk_phase = 0.0
var hurt = 0.0
var body_hit_time = 0.0
var armor_hit: ShaderMaterial
var limbs: Array[Node3D] = []
var limb_origins: Array[Vector3] = []
var head_area: Area3D

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
	visual = (game.enemy_model if game.enemy_model else load("res://assets/models/enemy.glb")).instantiate()
	add_child(visual)
	if fast:
		visual.scale = Vector3(.92,1,.92)
		orange = StandardMaterial3D.new()
		orange.albedo_color = Color("f17c28")
		orange.roughness = .9
		for part in ["Torso","Vest","Helmet","LeftArm","RightArm","LeftLeg","RightLeg"]:
			var mesh = visual.find_child(part,true,false)
			if mesh:mesh.material_override = orange
		visual.find_child("EnemyGun",true,false).hide()
		knife_arm = Node3D.new()
		visual.add_child(knife_arm)
		knife_arm.position = Vector3(.3,1.4,0)
		for part in ["RightArm","RightHand"]:
			visual.find_child(part,true,false).reparent(knife_arm)
		knife = preload("res://assets/models/knife.glb").instantiate()
		knife_arm.add_child(knife)
		knife.position = Vector3(0,-.46,-.18)
		knife.rotation.x = PI
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

func _physics_process(delta: float) -> void:
	if game.state=="RUNNING" and body_hit_time>0:
		update_body_hit(delta)
	if dead:
		death_time += delta
		visual.rotation.z = lerpf(visual.rotation.z,1.48,delta*9)
		visual.position.y = lerpf(visual.position.y,-.35,delta*5)
		if death_time > 1.4:queue_free()
		return
	if game.state != "RUNNING":return
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
	if to_player.length_squared() > .1:
		rotation.y = lerp_angle(rotation.y,atan2(-to_player.x,-to_player.z),delta*8)
	think -= delta
	if think <= 0:
		think = .35+randf()*.15
		var offset = Vector3.ZERO
		if distance < 13:
			var angle = age*.35+float(get_instance_id()%7)
			offset = Vector3(cos(angle),0,sin(angle))*8
		if not game.arena.uses_patrol(home_zone):
			agent.target_position = game.player.global_position+offset
		elif game.arena.enemy_zone(game.player.global_position)==home_zone and distance>6:
			agent.target_position = game.player.global_position
		else:
			# Patrol the occupied floor instead of draining every room toward the player.
			var posts = game.arena.patrol_points(home_zone)
			if global_position.distance_to(posts[patrol_offset])<.8:
				patrol_offset = (patrol_offset+1)%posts.size()
			agent.target_position = posts[patrol_offset]
	var next = agent.get_next_path_position()
	var dir = next-global_position
	dir.y = 0
	if dir.length_squared() > .0025 and not agent.is_navigation_finished():dir = dir.normalized()
	else:dir = Vector3.ZERO
	var speed = 2.5
	if windup > 0:speed *= .25
	velocity.x = dir.x*speed
	velocity.z = dir.z*speed
	if not is_on_floor():velocity.y -= 20*delta
	agent.velocity = steer_around_neighbors(Vector3(velocity.x,0,velocity.z))
	var movement = Vector2(get_real_velocity().x,get_real_velocity().z).length()
	walk_phase += delta*movement*3
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(walk_phase+float(i%2)*PI)*.42*minf(movement/speed,1)
		limbs[i].position = limb_origins[i]
	visual.position.y = absf(sin(walk_phase))*.035
	visual.rotation.z = sin(age*40)*hurt*.25
	if global_position.y < -5:queue_free()
	advance_ranged_attack(delta,distance<24)

func advance_ranged_attack(delta: float, can_aim: bool) -> void:
	if not patrol_brain or can_aim:attack -= delta
	if not can_aim or game.respawn_time>0:
		cancel_ranged_aim()
		return
	if windup<=0 and attack>0:return
	var starting = windup<=0
	if starting:
		aim_offset = Vector3(randf_range(-.25,.25),1.1,randf_range(-.25,.25))
	var origin = visual.to_global(Vector3(.22,1.12,-.58))
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
	else:
		windup = maxf(0,windup-delta)
		if windup==0:
			cancel_ranged_aim()
			game.enemy_shoot(origin,target)
			attack = 2.3 if patrol_brain else 1.8+randf()*1.2
			return
	var progress = 1.0-windup/aim_duration
	aim_line.material_override.albedo_color = Color("d6dce390").lerp(Color("5e6873ed"),progress)
	aim_line.set_segment(origin,target,lerpf(.018,.031,progress))

func cancel_ranged_aim() -> void:
	game.ranged_aimers.erase(self)
	windup = 0
	if aim_line:aim_line.hide()

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

func take_hit(is_head: bool, body_one_shot: bool = false) -> void:
	var previous_health = health
	take_damage(MAX_HEALTH if is_head or body_one_shot else 1,is_head)
	if not is_head and health<previous_health:
		if armor_hit==null:
			armor_hit = ShaderMaterial.new()
			armor_hit.shader = preload("res://assets/shaders/armor_hit.gdshader")
			for part in ["Torso","Vest"]:
				var panel = visual.find_child(part,true,false) as MeshInstance3D
				if panel:panel.material_overlay = armor_hit
		armor_hit.set_shader_parameter("damage_level",mini(MAX_HEALTH-health,2))
		body_hit_time = BODY_HIT_DURATION
		update_body_hit(0)

func update_body_hit(delta: float) -> void:
	body_hit_time = maxf(0,body_hit_time-delta)
	var strength = body_hit_time/BODY_HIT_DURATION
	armor_hit.set_shader_parameter("flash",strength*strength)
	visual.rotation.x = .23*strength*strength

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
	health -= amount
	hurt = .2
	if health <= 0:
		dead = true
		cancel_ranged_aim()
		agent.avoidance_enabled = false
		collision_layer = 0
		collision_mask = 0
		head_area.collision_layer = 0
		game.on_kill(self,is_head,from_finale)

func start_slash() -> void:
	rush_state = "WINDUP"
	rush_time = .4
	rush_direction = game.player.global_position-global_position
	rush_direction.y = 0
	rush_direction = rush_direction.normalized()
	rotation.y = atan2(-rush_direction.x,-rush_direction.z)
	slash_hit = false
	game.play_world_sound("charge",global_position+Vector3.UP,-9)

func recover_charge() -> void:
	rush_state = "RECOVER"
	rush_time = .65
	velocity.x = 0
	velocity.z = 0
	orange.albedo_color = Color("f17c28")

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
			orange.albedo_color = Color("fff1b7") if int(rush_time*12)%2==0 else Color("f17c28")
			knife_arm.rotation.x = lerpf(0,-2.35,clampf(1-rush_time/.4,0,1))
			if rush_time<=0:
				if in_front:
					rush_state = "SLASH"
					rush_time = .24
					orange.albedo_color = Color("f17c28")
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
					game.damage_player(34,global_position+Vector3.UP)
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
	if rush_state=="CHASE":knife_arm.rotation.x = -.25+sin(walk_phase)*.18
	visual.position.y = -.12 if rush_state=="WINDUP" else absf(sin(walk_phase))*.035
	if rush_state!="DODGE":visual.rotation.z = sin(age*40)*hurt*.25
	if global_position.y < -5:queue_free()
