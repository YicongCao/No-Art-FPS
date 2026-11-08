extends RefCounted

const PELLETS = [
	preload("res://assets/vfx/comedy/curl.png"),
	preload("res://assets/vfx/comedy/coil.png"),
	preload("res://assets/vfx/comedy/swirl.png"),
]
const SPLAT = preload("res://assets/vfx/comedy/splat.png")
const FLIGHT_SPEED = 76.0

static func sprite(texture: Texture2D, width: float) -> Sprite3D:
	var node = Sprite3D.new()
	node.texture = texture
	node.pixel_size = width/texture.get_width()
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func pellet(variant: int, width: float = .4) -> Sprite3D:
	var node = sprite(PELLETS[posmod(variant,PELLETS.size())],width)
	node.name = "ComedyPellet"
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return node

static func fly(parent: Node3D, variant: int, from: Vector3, to: Vector3) -> void:
	var reach = minf(from.distance_to(to),FLIGHT_SPEED*.15)
	if reach<.25:return
	var direction = from.direction_to(to)
	var node = pellet(variant)
	parent.add_child(node)
	var lead = minf(.55,reach)
	node.global_position = from+direction*lead
	var tween = node.create_tween()
	tween.tween_property(node,"global_position",from+direction*reach,maxf(.05,(reach-lead)/FLIGHT_SPEED))
	tween.tween_callback(node.queue_free)

static func kill(parent: Node3D, center: Vector3, reduced_motion: bool) -> void:
	var burst = sprite(SPLAT,1.22)
	burst.name = "ComedySplat"
	burst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(burst)
	burst.global_position = center
	burst.scale = Vector3.ONE*(1.0 if reduced_motion else .62)
	var pulse = burst.create_tween()
	if not reduced_motion:
		pulse.tween_property(burst,"scale",Vector3.ONE*1.13,.085).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_interval(.11)
	pulse.tween_property(burst,"scale",Vector3.ONE*.02,.30)
	pulse.tween_callback(burst.queue_free)
	if reduced_motion:return
	for i in range(3):
		var fleck = pellet(i,.19)
		parent.add_child(fleck)
		var radial = Vector3(cos(i*TAU/3),0,sin(i*TAU/3))
		fleck.global_position = center+radial*.25
		var pop = fleck.create_tween()
		pop.tween_property(fleck,"global_position",center+radial*.84+Vector3.UP*(.45+i*.12),.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pop.tween_property(fleck,"global_position",center+radial*1.13-Vector3.UP*.65,.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		pop.parallel().tween_property(fleck,"scale",Vector3.ONE*.04,.30)
		pop.tween_callback(fleck.queue_free)
