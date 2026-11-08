extends Node3D

const BOARD_SHADER = preload("res://assets/shaders/airport_split_flap.gdshader")
const WARNING_COLORS = [Color("ff3553"),Color("3d91ff")]
const OFF_COLOR = Color("212e45")
const PHASE_SECONDS = 60.0/104.0
const LENS_STATIONS = [-9,-5,-1,3,7]

var board_paint: ShaderMaterial
var lens_paints: Array[StandardMaterial3D] = []
var cargo_routes: Array[PackedVector3Array] = []
var cargo_bags: Array[Node3D] = []
var idle_seconds: float = 0.0

func setup(layout: Dictionary, belts: Array[StaticBody3D]) -> void:
	board_paint = ShaderMaterial.new()
	board_paint.shader = BOARD_SHADER
	board_paint.set_shader_parameter("board_atlas",load("res://assets/art/arena_signs/flight-board-atlas.svg"))
	for entry in layout.get("flight_boards",[]):
		var face = QuadMesh.new()
		face.size = Vector2(entry[1],entry[2])
		var board = display_mesh("FlightBoard",face,board_paint,point(entry[0]))
		board.rotation.y = entry[3]
	var lens = BoxMesh.new()
	lens.size = Vector3(.173,.056,.61)
	var side_lens = BoxMesh.new()
	side_lens.size = Vector3(.024,.116,.61)
	for side in [-1,1]:
		var paint = StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.albedo_color = OFF_COLOR
		lens_paints.append(paint)
		batch_lenses(lens,paint,belts,Vector2(side*1.77,.997))
		batch_lenses(side_lens,paint,belts,Vector2(side*1.86,.86))
	var suitcase = load("res://assets/models/baggage_below/suitcase.glb") as PackedScene
	for entry in layout.get("cargo_belts",[]):
		cargo_routes.append(PackedVector3Array([point(entry[0]),point(entry[1]),point(entry[2])]))
		for i in range(3):
			var bag = suitcase.instantiate() as Node3D
			bag.rotation.y = .22+i*.64
			bag.scale = Vector3.ONE * (1.03+i*.14)
			add_child(bag)
			cargo_bags.append(bag)
	pose(0.0,false)

func batch_lenses(mesh: Mesh, paint: Material, belts: Array[StaticBody3D], offset: Vector2) -> void:
	var batch = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = belts.size()*LENS_STATIONS.size()
	var index = 0
	for belt in belts:
		for z in LENS_STATIONS:
			batch.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(belt.position.x+offset.x,offset.y,z)))
			index += 1
	var lights = MultiMeshInstance3D.new()
	lights.multimesh = batch
	lights.material_override = paint
	lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lights)

func display_mesh(label: String, mesh: Mesh, paint: Material, at: Vector3) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = paint
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func point(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func pose(seconds: float, reduced_motion: bool) -> void:
	board_paint.set_shader_parameter("elapsed",seconds)
	board_paint.set_shader_parameter("reduced_motion",reduced_motion)
	for i in range(cargo_routes.size()):
		var route = cargo_routes[i]
		var incline = route[0].distance_to(route[1])
		var total = incline+route[1].distance_to(route[2])
		for j in range(3):
			var progress = fposmod(seconds*1.65+i*1.2+j*total/3.0,total)
			var bag = cargo_bags[i*3+j]
			bag.position = route[0].move_toward(route[1],progress) if progress < incline else route[1].move_toward(route[2],progress-incline)
			var fade = minf(smoothstep(0.0,.52,progress),1.0-smoothstep(total-.6,total,progress))
			bag.visible = fade > .08
			bag.scale = Vector3.ONE * (1.03+j*.14) * lerpf(.48,1.0,fade)

func warning_lights(active: bool, elapsed: float, reduced_motion: bool) -> Vector2:
	var red = 0.0
	var blue = 0.0
	if active:
		if reduced_motion:
			red = .5
			blue = .5
		elif elapsed>=0.0:
			var beat = elapsed/PHASE_SECONDS
			var brightness = lerpf(1.0,.58,smoothstep(0.0,.76,fposmod(beat,1.0)))
			red = brightness if floori(beat)%2==0 else .015
			blue = brightness if floori(beat)%2==1 else .015
	lens_paints[0].albedo_color = OFF_COLOR.lerp(WARNING_COLORS[0],red)
	lens_paints[1].albedo_color = OFF_COLOR.lerp(WARNING_COLORS[1],blue)
	return Vector2(red,blue)
