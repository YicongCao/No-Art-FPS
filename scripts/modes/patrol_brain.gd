extends Node

var actor: CharacterBody3D
var route: Array[Vector3] = []
var state = "PATROL"
var route_index = 0
var wait_time = 0.0
var last_known = Vector3.ZERO
var search_time = 0.0

func sees_player() -> bool:
	var offset = actor.game.player.global_position-actor.global_position
	if offset.length()>22:return false
	var facing = -actor.global_basis.z
	offset.y = 0
	return facing.dot(offset.normalized())>cos(deg_to_rad(55)) and actor.can_see_player()

func advance(delta: float) -> void:
	if actor.game.state!="RUNNING" or not actor.game.rules.active:return
	var visible = sees_player()
	if visible:
		last_known = actor.game.player.global_position
		state = "COMBAT"
		search_time = 4.0
	elif state=="COMBAT":state = "SEARCH"
	if state=="SEARCH":
		search_time -= delta
		if search_time<=0:state = "PATROL"
	var target = route[route_index] if state=="PATROL" else last_known
	if state=="PATROL" and actor.global_position.distance_to(target)<.7:
		actor.advance_ranged_attack(delta,false)
		wait_time += delta
		if wait_time>1.5:
			wait_time = 0
			route_index = (route_index+1)%route.size()
		actor.velocity = Vector3.ZERO
		actor.agent.velocity = Vector3.ZERO
		return
	actor.agent.target_position = target
	var next = actor.agent.get_next_path_position()
	var direction = next-actor.global_position
	direction.y = 0
	if actor.agent.is_navigation_finished():direction = Vector3.ZERO
	else:direction = direction.normalized()
	if direction.length_squared()>.01:
		actor.rotation.y = lerp_angle(actor.rotation.y,atan2(-direction.x,-direction.z),delta*6)
	if visible:
		var aim = last_known-actor.global_position
		actor.rotation.y = lerp_angle(actor.rotation.y,atan2(-aim.x,-aim.z),delta*6)
	actor.advance_ranged_attack(delta,visible)
	var speed = 2.5 if state=="PATROL" else 3.0
	if visible and actor.global_position.distance_to(last_known)<9:speed = 0
	actor.velocity.x = direction.x*speed
	actor.velocity.z = direction.z*speed
	if not actor.is_on_floor():actor.velocity.y -= 20*delta
	actor.agent.velocity = actor.steer_around_neighbors(Vector3(actor.velocity.x,0,actor.velocity.z))
	actor.walk_phase += delta*speed*3
	for i in range(actor.limbs.size()):actor.limbs[i].rotation.x = sin(actor.walk_phase+i%2*PI)*.42*(1 if speed>0 else 0)
