extends RefCounted

const PIXEL_PAINT = preload("res://assets/shaders/park_pixel_material.gdshader")
const MODELS = "res://assets/models/park_experiment/"
const TILES = "res://assets/textures/park_experiment/"
const OBJECTS = {
	"Grounds": ["grounds",{"cream":"pavers","sand":"gravel","brick":"brick"}],
	"Entry/Entrance": ["entry",{"teal":"ceramic","blue":"metal","gold":"enamel","white":"canvas","brick":"canvas"}],
	"SkateApron": ["skate",{"cream":"pavers","blue":"concrete","blue_light":"concrete","deep_blue":"concrete","brick":"brick","gold":"enamel"}],
	"Quarter-25/Quarter-25": ["quarter_pipe",{"gold":"wood","blue":"concrete"}],
	"SkateBank/SkateBank": ["skate_bank",{"gold":"wood","blue":"concrete"}],
	"Carousel/CarouselCanopy": ["carousel_roof",{"brick":"canvas","white":"canvas","gold":"enamel","blue":"metal","purple":"metal"}],
	"Carousel/Turntable/Deck": ["carousel_deck",{"gold_light":"wood","purple":"metal","gold":"enamel"}],
	"StationFoundation": ["station_foundation",{"cream":"pavers","purple":"metal","gold":"enamel"}],
	"Station/StationCanopy": ["station_roof",{"blue":"metal","deep_blue":"metal"}],
	"Kiosk0/Kiosk0": ["kiosk",{"teal":"ceramic","cream":"wood","gold":"canvas","white":"canvas"}],
	"Bench0/Bench0": ["bench",{"gold":"wood","blue":"metal"}],
	"Planter0/Planter0": ["planter",{"brick":"brick","cream":"pavers"}],
}
const TILE_PARAMETERS = {
	"pavers":Vector2(.36,.72), "gravel":Vector2(.63,.72), "brick":Vector2(.41,.87),
	"concrete":Vector2(.48,.79), "wood":Vector2(.58,.80), "metal":Vector2(.71,.76),
	"canvas":Vector2(.56,.62), "enamel":Vector2(.96,.67), "ceramic":Vector2(.60,.87),
}

var meshes: Array[Dictionary] = []
var paints: Dictionary = {}

func set_enabled(arena: Node3D, enabled: bool) -> void:
	if enabled and meshes.is_empty():prepare(arena)
	for entry in meshes:
		var node: MeshInstance3D = entry.node
		node.mesh = entry.uv_mesh if enabled else entry.original_mesh
		var materials: Array = entry.textured if enabled else entry.overrides
		for index in range(materials.size()):
			node.set_surface_override_material(index,materials[index])

func prepare(arena: Node3D) -> void:
	for path in OBJECTS:
		var target := arena.get_node(NodePath(path))
		var node := target.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var spec: Array = OBJECTS[path]
		var variant_scene := load(MODELS+spec[0]+".glb") as PackedScene
		var variant := variant_scene.instantiate()
		var uv_node := variant.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var uv_mesh := uv_node.mesh
		var originals: Dictionary = {}
		var overrides: Array[Material] = []
		for i in range(node.mesh.get_surface_count()):
			var source := node.mesh.surface_get_material(i)
			originals[source.resource_name] = node.get_active_material(i)
			overrides.append(node.get_surface_override_material(i))
		var textured: Array[Material] = []
		for i in range(uv_mesh.get_surface_count()):
			var source := uv_mesh.surface_get_material(i)
			var name := source.resource_name
			var baseline: Material = originals.get(name,source)
			var tile: String = spec[1].get(name,"")
			textured.append(baseline if tile.is_empty() else paint(baseline as StandardMaterial3D,tile))
		meshes.append({"node":node,"original_mesh":node.mesh,"uv_mesh":uv_mesh,
			"overrides":overrides,"textured":textured})
		variant.free()

func paint(source: StandardMaterial3D, tile: String) -> ShaderMaterial:
	var key := tile+"_"+source.albedo_color.to_html()
	if paints.has(key):return paints[key]
	var params: Vector2 = TILE_PARAMETERS[tile]
	var material := ShaderMaterial.new()
	material.shader = PIXEL_PAINT
	material.set_shader_parameter("base_color",source.albedo_color)
	material.set_shader_parameter("surface_roughness",source.roughness)
	material.set_shader_parameter("pixel_tile",load(TILES+tile+".png"))
	material.set_shader_parameter("repeats_per_metre",params.x)
	material.set_shader_parameter("texture_strength",params.y)
	paints[key] = material
	return material
