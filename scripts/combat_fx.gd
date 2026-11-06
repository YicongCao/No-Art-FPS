extends Node3D

var game: Node
var pieces: Array[Dictionary] = []
var age = 0.0
var duration = 1.6
var rng = RandomNumberGenerator.new()

func chunk(at: Vector3, extent: Vector3, color: Color, velocity: Vector3, floor_y: float = .08) -> void:
	var node = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = extent
	node.mesh = box
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .9
	node.material_override = material
	add_child(node)
	node.global_position = at
	pieces.append({"node":node,"velocity":velocity,"spin":Vector3(rng.randf_range(-4,4),rng.randf_range(-4,4),rng.randf_range(-4,4)),"floor":floor_y,"fall":true})

func flame(at: Vector3, extent: float, color: Color) -> void:
	var node = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0
	cone.bottom_radius = extent*.5
	cone.height = extent*1.7
	cone.radial_segments = 5
	node.mesh = cone
	node.material_override = game.effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.global_position = at
	pieces.append({"node":node,"velocity":Vector3(0,.5,0),"spin":Vector3.ZERO,"floor":-99.0,"fall":false})

func bloom(at: Vector3, extent: float, color: Color) -> void:
	var node = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = extent
	sphere.height = extent*2
	sphere.radial_segments = 8
	sphere.rings = 3
	node.mesh = sphere
	node.material_override = game.effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.global_position = at
	pieces.append({"node":node,"velocity":Vector3(0,.65,0),"spin":Vector3.ZERO,"floor":-99.0,"fall":false})

func _physics_process(delta: float) -> void:
	if game.state!="RUNNING":return
	age += delta
	for piece in pieces:
		var node = piece.node
		if piece.fall:
			piece.velocity.y -= 14*delta
			node.position += piece.velocity*delta
			node.rotation += piece.spin*delta
			if node.global_position.y<piece.floor:
				node.global_position.y = piece.floor
				piece.velocity *= Vector3(.65,-.15,.65)
		else:node.position += piece.velocity*delta
		node.scale = Vector3.ONE*(1-smoothstep(duration*.55,duration,age))
	if age>=duration:queue_free()
