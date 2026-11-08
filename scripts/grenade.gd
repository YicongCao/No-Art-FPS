extends CharacterBody3D

const FUSE = 1.1
const GRAVITY = 19.0
const RADIUS = .115
const WARNING_TIMES = [.55,.23]
const MODELS = {
	"": preload("res://assets/models/grenades/frag.glb"),
	"comedy": preload("res://assets/models/grenades/stink.glb"),
	"roach": preload("res://assets/models/grenades/roach.glb"),
}
const GLOVE = preload("res://assets/models/grenades/glove.glb")

var game: Node
var style = ""
var fuse = FUSE
var warning_index = 0
var resting = false
var detonated = false
var visual: Node3D
var warning_light: MeshInstance3D
var trail_start: Vector3
var trail_time = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collider = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = RADIUS
	collider.shape = sphere
	add_child(collider)
	visual = MODELS[style].instantiate()
	add_child(visual)
	var lamp = BoxMesh.new()
	lamp.size = Vector3.ONE*.052
	warning_light = MeshInstance3D.new()
	warning_light.mesh = lamp
	warning_light.position.y = .138
	warning_light.material_override = game.effect_material(Color("ffb856"))
	warning_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(warning_light)
	warning_light.hide()
	trail_start = global_position

func step(delta: float) -> void:
	if detonated:return
	fuse = maxf(0,fuse-delta)
	if not resting:
		velocity.y -= GRAVITY*delta
		var contact = move_and_collide(velocity*delta,false,.002)
		if contact:
			var normal = contact.get_normal()
			velocity = velocity.bounce(normal)*.55
			if normal.y>.65:
				velocity.y *= .62
				resting = velocity.length()<1.35
		if not game.reduced_motion:visual.rotation += Vector3(9,4,2)*delta
		if not game.reduced_motion and fuse>FUSE-.24:
			trail_time += delta
			if trail_time>=.045:
				var segment = global_position-trail_start
				if Vector2(segment.x,segment.z).length()>.025:
					game.trace(trail_start,global_position,Color("ffe4a2"),.025,.14)
				trail_start = global_position
				trail_time = 0
	if warning_index<WARNING_TIMES.size() and fuse<=WARNING_TIMES[warning_index]:
		game.play_world_sound("tick",global_position,-13,1.12+warning_index*.34)
		warning_index += 1
	warning_light.visible = warning_index>0 and (game.reduced_motion or fmod(fuse,.16)<.08)
	if fuse<=.000001:
		detonated = true
		game.grenade_blast(global_position,style)
		hide()
		queue_free()
