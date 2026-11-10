extends Node3D

const HALO = preload("res://assets/shaders/observatory_laser_halo.gdshader")
# Aligned with the objective lip and optical tube in tools/maps/build_snowline.py.
const LENS_ORIGIN = Vector3(0,7.90,2.33)
const OPTICAL_AXIS = Vector3(0,4.48,6.53)
const LEAF_COUNT = 8
const HINGE_RADIUS = 1.055
const BEAM_LENGTH = 56.0

var leaves: Array[Node3D] = []
var beam: Node3D
var halo_paint: ShaderMaterial

func _ready() -> void:
	position = LENS_ORIGIN
	# The local positive Z axis points outward from the glass.
	look_at(to_global(-OPTICAL_AXIS))
	var leaf_mesh := build_leaf()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("384766")
	steel.metallic = .32
	steel.roughness = .48
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark_steel := steel.duplicate() as StandardMaterial3D
	dark_steel.albedo_color = Color("2c3b5b")
	for index in range(LEAF_COUNT):
		var segment := Node3D.new()
		add_child(segment)
		segment.rotation.z = TAU * index / LEAF_COUNT
		var hinge := Node3D.new()
		segment.add_child(hinge)
		hinge.position.x = HINGE_RADIUS
		leaves.append(hinge)
		var plate := MeshInstance3D.new()
		hinge.add_child(plate)
		plate.mesh = leaf_mesh
		plate.material_override = steel if index % 2 == 0 else dark_steel

	beam = Node3D.new()
	beam.name = "SkyLaser"
	add_child(beam)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("ff2647")
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_tube(BEAM_LENGTH,.050,.065,red)
	halo_paint = ShaderMaterial.new()
	halo_paint.shader = HALO
	halo_paint.set_shader_parameter("beam_length",BEAM_LENGTH)
	add_tube(BEAM_LENGTH,.30,.54,halo_paint)
	var lens_light := OmniLight3D.new()
	lens_light.position.z = .12
	lens_light.light_color = Color("ff4359")
	lens_light.omni_range = 1.65
	lens_light.light_energy = 2.4
	beam.add_child(lens_light)
	pose(0.0,0.0)

func pose(openness: float, elapsed: float) -> void:
	for leaf in leaves:
		leaf.rotation.y = -1.55 * openness
	beam.visible = openness >= 1.0
	if beam.visible:halo_paint.set_shader_parameter("elapsed",elapsed)

func build_leaf() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_angle := PI / LEAF_COUNT - .018
	var center := Vector3(.025-HINGE_RADIUS,0,0)
	for section in range(4):
		var start := lerpf(-half_angle,half_angle,section / 4.0)
		var end := lerpf(-half_angle,half_angle,(section+1) / 4.0)
		for vertex in [center,Vector3(cos(end)-HINGE_RADIUS,sin(end),0),
				Vector3(cos(start)-HINGE_RADIUS,sin(start),0)]:
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(vertex)
	return surface.commit()

func add_tube(length: float, near_radius: float, far_radius: float, paint: Material) -> void:
	var tube := CylinderMesh.new()
	tube.height = length
	tube.bottom_radius = near_radius
	tube.top_radius = far_radius
	tube.radial_segments = 16
	tube.rings = 0
	tube.cap_top = false
	tube.cap_bottom = false
	var instance := MeshInstance3D.new()
	instance.mesh = tube
	instance.material_override = paint
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position.z = length * .5
	instance.rotation.x = PI * .5
	beam.add_child(instance)
