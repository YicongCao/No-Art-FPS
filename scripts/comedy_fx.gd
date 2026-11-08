extends RefCounted

const POOP_ART = [
	preload("res://assets/vfx/comedy/curl.png"),
	preload("res://assets/vfx/comedy/coil.png"),
	preload("res://assets/vfx/comedy/swirl.png"),
]
const SPLAT = preload("res://assets/vfx/comedy/splat.png")
const ROACH_ART = [
	preload("res://assets/vfx/comedy/roach/dash.png"),
	preload("res://assets/vfx/comedy/roach/fly.png"),
	preload("res://assets/vfx/comedy/roach/skid.png"),
]
const ROACH_KNOCKOUT = preload("res://assets/vfx/comedy/roach/knockout.png")
const SLIPPER = preload("res://assets/models/comedy/slipper.glb")
const WATER = Color("76e4ff")
const FLIGHT_SPEED = 76.0
static var droplet_mesh: SphereMesh
static var droplet_paint: StandardMaterial3D

static func sprite(texture: Texture2D, width: float) -> Sprite3D:
	var node = Sprite3D.new()
	node.texture = texture
	node.pixel_size = width/texture.get_width()
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func projectile(mode: String, direction: Vector3) -> Node3D:
	var node = Node3D.new()
	var up = Vector3.RIGHT if absf(direction.y)>.98 else Vector3.UP
	if not direction.is_zero_approx():node.basis = Basis.looking_at(direction,up)
	if mode=="roach":
		node.name = "SlipperBolt"
		var shoe = SLIPPER.instantiate()
		shoe.rotation = Vector3(-.88,.25,.30)
		node.add_child(shoe)
		for part in shoe.find_children("*","MeshInstance3D",true,false):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		node.name = "WaterBolt"
		if not droplet_mesh:
			droplet_mesh = SphereMesh.new()
			droplet_mesh.radial_segments = 8
			droplet_mesh.rings = 4
			droplet_paint = StandardMaterial3D.new()
			droplet_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			droplet_paint.albedo_color = WATER
		var drop = MeshInstance3D.new()
		drop.mesh = droplet_mesh
		drop.material_override = droplet_paint
		drop.scale = Vector3(.095,.095,.34)
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(drop)
	return node

static func fly(parent: Node3D, mode: String, from: Vector3, to: Vector3) -> void:
	var reach = minf(from.distance_to(to),FLIGHT_SPEED*.15)
	if reach<.25:return
	var direction = from.direction_to(to)
	var node = projectile(mode,direction)
	parent.add_child(node)
	var lead = minf(.55,reach)
	node.global_position = from+direction*lead
	var tween = node.create_tween()
	tween.tween_property(node,"global_position",from+direction*reach,maxf(.05,(reach-lead)/FLIGHT_SPEED))
	if mode=="roach":tween.parallel().tween_property(node.get_child(0),"rotation:z",1.1,.09)
	tween.tween_callback(node.queue_free)

static func blast_arc(node: Node3D, destination: Vector3, lift: float, spin: Vector3, duration: float) -> void:
	var origin = node.global_position
	var angle = node.rotation
	var extent = node.scale
	var move = func(t: float) -> void:
		node.global_position = origin.lerp(destination,t)+Vector3.UP*(4*lift*t*(1-t))
		node.rotation = angle+spin*t
		node.scale = extent*(1-.95*smoothstep(.72,1,t))
	var flight = node.create_tween()
	flight.tween_method(move,0.0,1.0,duration)
	flight.tween_callback(node.queue_free)

static func toilet_scatter(parent: Node3D, center: Vector3, mode: String, reduced_motion: bool) -> void:
	var art = ROACH_ART if mode=="roach" else POOP_ART
	var count = 10 if reduced_motion else 22
	for i in range(count):
		var particle = sprite(art[i%art.size()],.55+float(i%5)*.16)
		particle.name = "ToiletScatter"
		particle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		particle.flip_h = i%2==0
		parent.add_child(particle)
		var heading = float(i)*2.39996
		var radial = Vector3(cos(heading),0,sin(heading))
		particle.global_position = center+Vector3.UP*(1.4+float(i%3)*.23)+radial*.38
		var destination = center+radial*(3.0+float(i%7)*.85)+Vector3.UP*.25
		blast_arc(particle,destination,1.8+float(i%6)*.47,Vector3.ZERO,1.04+float(i%5)*.11)

static func kill(parent: Node3D, center: Vector3, mode: String, reduced_motion: bool) -> void:
	var roach = mode=="roach"
	var burst = sprite(ROACH_KNOCKOUT if roach else SPLAT,1.22)
	burst.name = "ComedyKnockout" if roach else "ComedySplat"
	burst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(burst)
	burst.global_position = center
	burst.scale = Vector3.ONE*(1.0 if reduced_motion else .62)
	var pulse = burst.create_tween()
	if not reduced_motion:
		pulse.tween_property(burst,"scale",Vector3.ONE*1.13,.085).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if roach:pulse.parallel().tween_property(burst,"global_position",center+Vector3.UP*.26,.085)
	pulse.tween_interval(.11)
	pulse.tween_property(burst,"scale",Vector3.ONE*.02,.30)
	pulse.tween_callback(burst.queue_free)
	if reduced_motion:return
	var art = ROACH_ART if roach else POOP_ART
	for i in range(art.size()):
		var fleck = sprite(art[i],.19)
		fleck.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(fleck)
		var radial = Vector3(cos(i*TAU/3),0,sin(i*TAU/3))
		fleck.global_position = center+radial*.25
		var pop = fleck.create_tween()
		pop.tween_property(fleck,"global_position",center+radial*.84+Vector3.UP*(.45+i*.12),.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pop.tween_property(fleck,"global_position",center+radial*1.13-Vector3.UP*.65,.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		pop.parallel().tween_property(fleck,"scale",Vector3.ONE*.04,.30)
		pop.tween_callback(fleck.queue_free)
