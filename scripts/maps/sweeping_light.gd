extends RefCounted

const SHAFT = preload("res://assets/shaders/light_shaft.gdshader")

static func add_spot(parent: Node3D, label: String, at: Vector3, tint: Color,
		energy: float, reach: float, angle: float, shadows: bool) -> SpotLight3D:
	var light = SpotLight3D.new()
	light.name = label
	light.position = at
	light.light_color = tint
	light.light_energy = energy
	light.spot_range = reach
	light.spot_angle = angle
	light.shadow_enabled = shadows and not OS.has_feature("web")
	parent.add_child(light)
	return light

static func add_shaft(light: SpotLight3D, length: float, aperture: float,
		spread: float, density: float) -> void:
	var cone = CylinderMesh.new()
	cone.height = length
	cone.top_radius = aperture
	cone.bottom_radius = aperture + length*tan(deg_to_rad(spread))
	cone.radial_segments = 16
	cone.rings = 0
	cone.cap_top = false
	cone.cap_bottom = false
	var paint = ShaderMaterial.new()
	paint.shader = SHAFT
	paint.set_shader_parameter("tint",light.light_color)
	paint.set_shader_parameter("density",density)
	paint.set_shader_parameter("shaft_length",length)
	var mesh = MeshInstance3D.new()
	mesh.name = "Shaft"
	mesh.mesh = cone
	mesh.material_override = paint
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.rotation.x = PI*.5
	mesh.position.z = -length*.5
	light.add_child(mesh)
