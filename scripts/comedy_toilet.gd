extends Node3D

const BOOTH = preload("res://assets/models/comedy/portable_toilet.glb")
const CHARGE = preload("res://assets/models/comedy/column_charge.glb")
const ComedyFX = preload("res://scripts/comedy_fx.gd")
const PLACEMENTS = {
	"yard": Vector4(6.6,.0,5.5,-.15),
	"amusement_park": Vector4(4.8,.0,12.1,.08),
	"last_ferry": Vector4(6.8,.0,5.2,-.12),
	"night_studio": Vector4(-6.7,.0,3.35,.12),
}
const CHARGE_POSITIONS = [Vector3(-1.32,0,.40),Vector3(-2.04,0,.57),Vector3(-1.64,0,-.33)]
var game: Node3D
var spent = false
var booth_hits = 0
var booth: Node3D
var charge_bodies: Array[StaticBody3D] = []
var booth_body: StaticBody3D
var obstacle: NavigationObstacle3D

func _ready() -> void:
	var cabin = BoxShape3D.new()
	cabin.size = Vector3(1.78,2.45,1.65)
	booth_body = target_body("Booth",Vector3(0,1.225,0),cabin)
	booth = BOOTH.instantiate()
	add_child(booth)
	var cylinder = CylinderShape3D.new()
	cylinder.radius = .344
	cylinder.height = 1.15
	for at in CHARGE_POSITIONS:
		var charge = target_body("Charge%d"%charge_bodies.size(),at+Vector3.UP*.575,cylinder)
		var mesh = CHARGE.instantiate()
		mesh.position.y = -.575
		charge.add_child(mesh)
		charge.set_meta("charge",true)
		charge_bodies.append(charge)

	# Steer agents around the temporary prop without rebaking a full Web map.
	obstacle = NavigationObstacle3D.new()
	obstacle.height = 2.45
	obstacle.vertices = PackedVector3Array([
		Vector3(-2.39,0,-.86),Vector3(.9,0,-.86),
		Vector3(.9,0,.92),Vector3(-2.39,0,.92),
	])
	add_child(obstacle)

func target_body(label: String, at: Vector3, shape: Shape3D) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_mask = 0
	body.set_meta("comedy_toilet",self)
	var collider = CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body

func shot_hit(charge: bool, burning: bool) -> bool:
	if spent or game.state!="RUNNING" or not game.rules.active:return false
	if charge:
		explode()
		return true
	if burning:
		booth_hits += 1
		if booth_hits>=2:explode()
		return true
	return false

func explode(from_finale: bool = false) -> void:
	if spent:return
	spent = true
	booth_body.collision_layer = 0
	obstacle.avoidance_enabled = false
	for charge in charge_bodies:
		charge.collision_layer = 0
		charge.hide()
	if from_finale:
		booth.hide()
		game.finale_explosion(global_position+Vector3.UP,2.1,Color("47a99d"))
		return
	var door: Node3D = booth.find_child("Door",true,false)
	var roof: Node3D = booth.find_child("Roof",true,false)
	door.reparent(game.effects,true)
	roof.reparent(game.effects,true)
	booth.hide()
	ComedyFX.blast_arc(door,to_global(Vector3(3.8,.22,5.8)),2.6,Vector3(3.7,1.3,-2.1),1.12)
	ComedyFX.blast_arc(roof,to_global(Vector3(-3.1,.24,-3.5)),4.1,Vector3(-2.4,3.2,1.8),1.22)
	game.toilet_blast(global_position)
