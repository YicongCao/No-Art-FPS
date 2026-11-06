extends CharacterBody3D

var game: Node
var visual: Node3D
var agent: NavigationAgent3D
var health = 3
var dead = false
var fast = false
var home_zone = "yard"
var patrol_offset = 0
var rush_state = "CHASE"
var rush_time = 0.0
var rush_direction = Vector3.ZERO
var charge_marker: MeshInstance3D
var orange: StandardMaterial3D
var age = 0.0
var think = 0.0
var attack = 1.8
var windup = 0.0
var death_time = 0.0
var walk_phase = 0.0
var hurt = 0.0
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
	visual = load("res://assets/models/enemy.glb").instantiate()
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
		charge_marker = MeshInstance3D.new()
		var strip = BoxMesh.new()
		strip.size = Vector3(.22,.025,8.125)
		charge_marker.mesh = strip
		charge_marker.material_override = game.effect_material(Color("ffb24a"))
		charge_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(charge_marker)
		charge_marker.position = Vector3(0,.04,-4.0625)
		charge_marker.hide()
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
	if home_zone!="yard":
		var posts = game.arena.patrol_points(home_zone)
		patrol_offset = 1 if position.distance_to(posts[0])<position.distance_to(posts[1]) else 0

func _physics_process(delta: float) -> void:
	if dead:
		death_time += delta
		visual.rotation.z = lerpf(visual.rotation.z,1.48,delta*9)
		visual.position.y = lerpf(visual.position.y,-.35,delta*5)
		if death_time > 1.4:queue_free()
		return
	if game.state != "RUNNING":return
	age += delta
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
		if home_zone=="yard":
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
	attack -= delta
	if windup > 0:
		windup -= delta
		if windup <= 0:
			if can_see_player():game.enemy_shoot(global_position+Vector3(0,1.25,0))
			attack = 1.8+randf()*1.2
	elif attack <= 0 and distance < 24 and can_see_player():
		windup = .65
		game.spark(global_position+Vector3(0,1.5,0),Color("e9ba50"),.14,.65)

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
	if not fast or rush_state=="CHASE":
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z
	# A telegraphed charge stays straight; body collisions stop it at other actors.
	move_and_slide()
	if fast and rush_state=="CHARGE":
		var offset = game.player.global_position-global_position
		if Vector2(offset.x,offset.z).length()<.95 and absf(offset.y)<1.2 and can_see_player():
			game.damage_player(42)
			recover_charge()
		elif is_on_wall():recover_charge()

func can_see_player() -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.4,0),game.player.global_position+Vector3(0,1.1,0),1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_hit(is_head: bool) -> void:
	take_damage(3 if is_head else 1,is_head)

func take_damage(amount: int, is_head: bool = false) -> void:
	if dead or not game.rules.active:return
	health -= amount
	hurt = .2
	if health <= 0:
		dead = true
		agent.avoidance_enabled = false
		if charge_marker:charge_marker.hide()
		collision_layer = 0
		collision_mask = 0
		head_area.collision_layer = 0
		game.on_kill(self,is_head)

func start_charge() -> void:
	rush_state = "WINDUP"
	rush_time = .75
	rush_direction = game.player.global_position-global_position
	rush_direction.y = 0
	rush_direction = rush_direction.normalized()
	rotation.y = atan2(-rush_direction.x,-rush_direction.z)
	charge_marker.show()
	game.play_world_sound("charge",global_position+Vector3.UP,-9)

func recover_charge() -> void:
	rush_state = "RECOVER"
	rush_time = .9
	charge_marker.hide()
	velocity.x = 0
	velocity.z = 0
	orange.albedo_color = Color("f17c28")

func process_rusher(delta: float) -> void:
	var to_player = game.player.global_position-global_position
	var distance = to_player.length()
	attack -= delta
	var direction = Vector3.ZERO
	var speed = 0.0
	match rush_state:
		"CHASE":
			think -= delta
			if think<=0:
				think = .25
				agent.target_position = game.player.global_position
			direction = agent.get_next_path_position()-global_position
			direction.y = 0
			direction = direction.normalized() if direction.length()>.15 else Vector3.ZERO
			speed = 3.4
			if direction.length_squared()>.01:rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*10)
			if attack<=0 and distance<10 and absf(to_player.y)<1.2 and game.respawn_time<=0 and can_see_player():
				start_charge()
				speed = 0
		"WINDUP":
			rush_time -= delta
			orange.albedo_color = Color("fff1b7") if int(rush_time*12)%2==0 else Color("f17c28")
			if rush_time<=0:
				rush_state = "CHARGE"
				rush_time = .65
				charge_marker.hide()
				orange.albedo_color = Color("f17c28")
		"CHARGE":
			rush_time -= delta
			direction = rush_direction
			speed = 12.5
			# Stop at ledges instead of charging off the upper deck.
			var ahead = global_position+direction*.8
			var ground = PhysicsRayQueryParameters3D.create(ahead+Vector3.UP*.4,ahead-Vector3.UP*.9,1)
			if rush_time<=0 or get_world_3d().direct_space_state.intersect_ray(ground).is_empty():
				recover_charge()
				speed = 0
		"RECOVER":
			rush_time -= delta
			if rush_time<=0:
				rush_state = "CHASE"
				attack = 1.2
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	if not is_on_floor():velocity.y -= 20*delta
	var desired = Vector3(velocity.x,0,velocity.z)
	agent.velocity = steer_around_neighbors(desired) if rush_state=="CHASE" else desired
	var movement = Vector2(get_real_velocity().x,get_real_velocity().z).length()
	walk_phase += delta*movement*3
	for i in range(limbs.size()):limbs[i].rotation.x = sin(walk_phase+float(i%2)*PI)*.55*minf(movement/3.4,1)
	visual.position.y = -.12 if rush_state=="WINDUP" else absf(sin(walk_phase))*.035
	visual.rotation.z = sin(age*40)*hurt*.25
	if global_position.y < -5:queue_free()
