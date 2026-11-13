extends "res://scripts/combat_fx.gd"
## Shared toy-shell shards and a depth-tested, camera-facing precision flash.
const FULL_LIMIT = 6
static var shell_mesh: ArrayMesh
static var flash_mesh: ArrayMesh
static var reactor_mesh: BoxMesh
var flash: MeshInstance3D
var reduced := false
var full_burst := true

static func prepare_resources() -> void:
	if shell_mesh:return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(-.5,-.5,-.24),Vector3(.5,-.5,-.24),Vector3(.5,.5,-.24),Vector3(-.5,.5,-.24),Vector3(-.38,-.38,.34),Vector3(.38,-.38,.34),Vector3(.38,.38,.34),Vector3(-.38,.38,.34)]
	for face in [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]:
		for i in [0,2,1,0,3,2]:surface.add_vertex(points[face[i]])
	surface.generate_normals()
	shell_mesh = surface.commit()
	surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(3):
		var radius: float = [1.0,.82,.43][layer]
		var color: Color = [Color("46334b"),Color("ffc65b"),Color("fff9df")][layer]
		for i in range(8):
			var a := float(i)*TAU/8
			var b := float(i+1)*TAU/8
			surface.set_color(color)
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(Vector3(0,0,layer*.002))
			surface.add_vertex(Vector3(cos(b),sin(b),0)*radius*(1.0 if (i+1)%2==0 else .24)+Vector3.BACK*layer*.002)
			surface.add_vertex(Vector3(cos(a),sin(a),0)*radius*(1.0 if i%2==0 else .24)+Vector3.BACK*layer*.002)
	flash_mesh = surface.commit()
	reactor_mesh = BoxMesh.new()
	reactor_mesh.size = Vector3(.12,.10,.045)

func setup(owner_game: Node, at: Vector3, direction: Vector3, normal: Vector3, fast: bool, mechanical: bool = true, floor_height: float = NAN) -> void:
	game = owner_game
	prepare_resources()
	reduced = game.reduced_motion
	full_burst = mechanical and get_tree().get_nodes_in_group("headshot_full").size()<FULL_LIMIT
	if full_burst:add_to_group("headshot_full")
	add_to_group("headshot_feedback")
	duration = .65 if full_burst else .12
	global_position = at
	var toward_eye: Vector3 = at.direction_to(game.player.camera.global_position)
	var outward := normal.normalized() if normal.length_squared()>.01 else toward_eye
	flash = MeshInstance3D.new()
	flash.mesh = flash_mesh
	flash.material_override = paint_for(false)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flash)
	flash.position = outward*.045
	if full_burst:
		var forward := direction.normalized() if direction.length_squared()>.01 else -toward_eye
		var side: Vector3 = game.player.camera.global_basis.x
		var palette := [Color("ef732f"),Color("fff0d5"),Color("5ecfdb")] if fast else [Color("41516c"),Color("d94c42"),Color("fff0d5")]
		var count := 3 if reduced else 9
		for i in range(count):
			var spread := float(i%3)-1.0
			var large := i<3
			var extent := Vector3(.22,.16,.12) if large else Vector3(.065,.045,.035)
			if fast:extent *= Vector3(.85,1.2,.7)
			var velocity := side*(spread*2.6+rng.randf_range(-.35,.35))+Vector3.UP*rng.randf_range(2.1,3.5)+forward*rng.randf_range(.7,1.5)
			if reduced:velocity *= .45
			chunk(at+side*spread*.09,extent,palette[i%3],velocity,at.y-1.65 if is_nan(floor_height) else floor_height)
		if not reduced:
			for i in range(3):bloom(at+side*(i-1)*.085,.045,Color("ffdf8c"))
		show_pieces(true)
		batches[Shape.CHUNK].mesh = shell_mesh
		for child in get_children():
			if child is GeometryInstance3D:child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	update_flash()

func update_flash() -> void:
	if not is_instance_valid(flash):return
	flash.visible = age<.11
	if not flash.visible:return
	var eye: Camera3D = game.player.camera
	flash.global_basis = eye.global_basis
	# Keep the close-range flash compact without enlarging it at long range.
	var radius := minf(.28,global_position.distance_to(eye.global_position)*.042)
	var fade := pow(maxf(0,1-age/.11),.65)
	flash.scale = Vector3.ONE*radius*fade*(.65 if reduced else 1.0)

func _physics_process(delta: float) -> void:
	if game.state!="RUNNING":return
	super._physics_process(delta)
	if batches.has(Shape.BLOOM) and age>.16:batches[Shape.BLOOM].visible_instance_count = 0
	update_flash()
