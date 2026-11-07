extends Node3D

enum Shape { CHUNK, FLAME, BLOOM }

static var meshes: Dictionary = {}
static var paints: Dictionary = {}

var game: Node
var pieces: Dictionary = {}
var batches: Dictionary = {}
var age = 0.0
var duration = 1.6
var rng = RandomNumberGenerator.new()

func chunk(at: Vector3, extent: Vector3, color: Color, velocity: Vector3, floor_y: float = .08) -> void:
	var spin = Vector3(rng.randf_range(-4,4),rng.randf_range(-4,4),rng.randf_range(-4,4))
	add_piece(Shape.CHUNK,at,extent,color,velocity,spin,floor_y)

func flame(at: Vector3, extent: float, color: Color) -> void:
	add_piece(Shape.FLAME,at,Vector3.ONE*extent,color,Vector3(0,.5,0))

func bloom(at: Vector3, extent: float, color: Color) -> void:
	add_piece(Shape.BLOOM,at,Vector3.ONE*extent,color,Vector3(0,.65,0))

func add_piece(shape: Shape, at: Vector3, extent: Vector3, color: Color, velocity: Vector3, spin: Vector3 = Vector3.ZERO, floor_y: float = 0.0) -> void:
	if not pieces.has(shape):pieces[shape] = []
	pieces[shape].append({"at":to_local(at),"extent":extent,"color":color,"velocity":velocity,"spin":spin,"rotation":Vector3.ZERO,"floor":floor_y-global_position.y})

static func mesh_for(shape: Shape) -> PrimitiveMesh:
	if not meshes.has(shape):
		match shape:
			Shape.CHUNK:
				meshes[shape] = BoxMesh.new()
			Shape.FLAME:
				var cone = CylinderMesh.new()
				cone.top_radius = 0
				cone.bottom_radius = .5
				cone.height = 1.7
				cone.radial_segments = 5
				meshes[shape] = cone
			Shape.BLOOM:
				var sphere = SphereMesh.new()
				sphere.radius = 1
				sphere.height = 2
				sphere.radial_segments = 8
				sphere.rings = 3
				meshes[shape] = sphere
	return meshes[shape]

static func paint_for(lit: bool) -> StandardMaterial3D:
	if not paints.has(lit):
		var paint = StandardMaterial3D.new()
		paint.vertex_color_use_as_albedo = true
		paint.vertex_color_is_srgb = true
		paint.roughness = .9
		if not lit:paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paints[lit] = paint
	return paints[lit]

func show_pieces() -> void:
	for shape in pieces:
		var falling = shape==Shape.CHUNK
		var instances: Array = pieces[shape]
		var batch = MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.mesh = mesh_for(shape)
		batch.instance_count = instances.size()
		var bounds = AABB(instances[0].at,Vector3.ZERO)
		var padding = 0.0
		for i in range(instances.size()):
			var piece = instances[i]
			batch.set_instance_transform(i,Transform3D(Basis.from_scale(piece.extent),piece.at))
			batch.set_instance_color(i,piece.color)
			bounds = bounds.expand(piece.at)
			if falling:bounds = bounds.expand(Vector3(piece.at.x,piece.floor,piece.at.z))
			padding = maxf(padding,piece.extent.length()+piece.velocity.length()*duration)
		# Keep the batch visible across its motion without rebuilding its bounds each tick.
		batch.custom_aabb = bounds.grow(padding)
		var visual = MultiMeshInstance3D.new()
		visual.multimesh = batch
		visual.material_override = paint_for(falling)
		if not falling or OS.has_feature("web"):visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)
		batches[shape] = batch

func _physics_process(delta: float) -> void:
	if game.state!="RUNNING":return
	age += delta
	if age>=duration:
		queue_free()
		return
	var scale = 1-smoothstep(duration*.55,duration,age)
	for shape in batches:
		var batch: MultiMesh = batches[shape]
		var instances: Array = pieces[shape]
		for i in range(instances.size()):
			var piece = instances[i]
			var basis = Basis.IDENTITY
			if shape==Shape.CHUNK:
				piece.velocity.y -= 14*delta
				piece.at += piece.velocity*delta
				piece.rotation += piece.spin*delta
				if piece.at.y<piece.floor:
					piece.at.y = piece.floor
					piece.velocity *= Vector3(.65,-.15,.65)
				basis = Basis.from_euler(piece.rotation)
			else:piece.at += piece.velocity*delta
			batch.set_instance_transform(i,Transform3D(basis.scaled_local(piece.extent*scale),piece.at))
