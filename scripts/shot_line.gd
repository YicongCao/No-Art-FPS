extends MeshInstance3D

func _ready() -> void:
	mesh = BoxMesh.new()
	mesh.size = Vector3.ONE
	var paint = StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = paint
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hide()

func set_segment(from: Vector3, to: Vector3, width: float) -> void:
	var offset = to-from
	var length = offset.length()
	if length<.001:
		hide()
		return
	var direction = offset/length
	var up = Vector3.RIGHT if absf(direction.y)>.98 else Vector3.UP
	var alignment = Basis.looking_at(direction,up).scaled_local(Vector3(width,width,length))
	global_transform = Transform3D(alignment,(from+to)*.5)
	show()
