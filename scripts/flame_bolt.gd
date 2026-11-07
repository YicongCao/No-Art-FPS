extends MeshInstance3D

const ART = preload("res://assets/vfx/flame_bolt.png")
const LENGTH = 2.15
const HEIGHT = .44
const SPEED = 76.0
static var quad: QuadMesh
static var paint: StandardMaterial3D

func _ready() -> void:
	if quad==null:
		quad = QuadMesh.new()
		quad.size = Vector2.ONE
		paint = StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		paint.albedo_texture = ART
	mesh = quad
	material_override = paint
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hide()

func set_segment(tail: Vector3, tip: Vector3, eye: Vector3) -> void:
	var length = tail.distance_to(tip)
	if length<.01:
		hide()
		return
	var forward = (tip-tail)/length
	var center = (tail+tip)*.5
	var vertical = (eye-center).normalized().cross(forward)
	# Keep the bolt lean when viewed almost along its flight path.
	var height = clampf(length*vertical.length()*.42,.02,HEIGHT)
	if vertical.length_squared()<.0001:
		vertical = (Vector3.UP if absf(forward.y)<.98 else Vector3.RIGHT).cross(forward)
	vertical = vertical.normalized()
	# Keep the generated tip aligned to flight while turning the flat art toward the camera.
	global_transform = Transform3D(Basis(forward*length,vertical*height,forward.cross(vertical)),center)
	show()

func fly(from: Vector3, to: Vector3, camera: Camera3D) -> void:
	var direction = from.direction_to(to)
	var reach = minf(from.distance_to(to),SPEED*.15)
	if reach<.05:
		queue_free()
		return
	var place = func(travel: float) -> void:
		set_segment(from+direction*maxf(0,travel-LENGTH),from+direction*travel,camera.global_position)
	var lead = minf(reach,.7)
	place.call(lead)
	var tween = create_tween()
	tween.tween_method(place,lead,reach,maxf(.04,(reach-lead)/SPEED))
	tween.tween_callback(queue_free)
