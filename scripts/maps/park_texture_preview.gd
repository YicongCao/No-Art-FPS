extends RefCounted

const PIXEL_PAINT = preload("res://assets/shaders/park_pixel_material.gdshader")
const BARREL = preload("res://scripts/explosive_barrel.gd")
const TILES = "res://assets/textures/park_experiment/"
const SURFACES = {
	"grounds":{"cream":"pavers","sand":"gravel","brick":"brick","grout":"mortar"},
	"entry":{"teal":"ceramic","teal_dark":"ceramic","edge":"enamel","blue":"metal","gold":"enamel","cream":"mortar","white":"canvas","brick":"canvas"},
	"skate":{"cream":"pavers","blue":"concrete","blue_light":"concrete","deep_blue":"concrete","brick":"brick","gold":"enamel","purple":"rubber"},
	"quarter_pipe":{"gold":"wood","blue":"concrete","edge":"brushed_steel","purple":"rubber"},
	"skate_bank":{"gold":"wood","blue":"concrete"},
	"grind_rail":{"blue":"brushed_steel","gold":"enamel","purple":"cast_iron"},
	"carousel_roof":{"brick":"canvas","white":"canvas","gold":"enamel","gold_light":"enamel","blue":"metal","purple":"metal"},
	"carousel_deck":{"gold_light":"wood","purple":"metal","gold":"enamel"},
	"horse":{"white":"lacquer","cream":"lacquer","ink":"rubber","blue":"lacquer","brick":"lacquer","gold_light":"brushed_steel"},
	"coaster_track":{"blue":"metal","deep_blue":"brushed_steel","cream":"wood","gold":"enamel"},
	"coaster_car":{"deep_blue":"rubber","gold":"lacquer","blue":"lacquer","ink":"rubber","purple":"lacquer","steel":"brushed_steel"},
	"station_foundation":{"cream":"pavers","purple":"metal","gold":"enamel"},
	"station_stairs":{"gold":"enamel","gold_light":"brushed_steel","purple":"cast_iron"},
	"station_roof":{"purple":"cast_iron","blue":"metal","deep_blue":"metal"},
	"kiosk":{"teal":"ceramic","teal_dark":"ceramic","cream":"wood","edge":"lacquer","gold":"canvas","white":"canvas"},
	"bench":{"gold":"wood","blue":"metal"},
	"planter":{"brick":"brick","cream":"pavers","leaf":"turf","leaf_light":"turf"},
	"lamp":{"cream":"lamp_glass","blue":"metal","edge":"enamel"},
	"palm":{"trunk":"bark","leaf_light":"foliage","leaf":"foliage","cream":"bark"},
	"fence":{"brick":"brick","blue":"metal","ink":"cast_iron"},
	"barrel":{"cream":"metal","red":"enamel","ink":"cast_iron"},
	"portable_toilet":{"mint":"lacquer","dark":"rubber","teal":"lacquer","red":"enamel","cream":"lacquer","gold":"enamel","porcelain":"ceramic"},
	"column_charge":{"dark":"rubber","gold":"brushed_steel","orange":"lacquer","ruby":"lamp_glass"},
}
# Repeats per metre, texture contrast, roughness, and metallic response.
const PROFILES = {
	"pavers":Vector4(.36,.72,.76,.0), "gravel":Vector4(.63,.72,.96,.0),
	"brick":Vector4(.41,.87,.83,.0), "concrete":Vector4(.48,.79,.75,.0),
	"wood":Vector4(.58,.80,.50,.0), "metal":Vector4(.71,.76,.32,.31),
	"canvas":Vector4(.56,.62,.89,.0), "enamel":Vector4(.96,.67,.30,.24),
	"ceramic":Vector4(.60,.87,.31,.0), "bark":Vector4(1.2,.67,.91,.0),
	"foliage":Vector4(.95,.72,.68,.0), "turf":Vector4(1.1,.78,.93,.0),
	"lacquer":Vector4(.85,.81,.25,.05), "rubber":Vector4(.95,.55,.76,.0),
	"brushed_steel":Vector4(1.25,.78,.26,.48), "lamp_glass":Vector4(.95,.58,.23,.0),
	"cast_iron":Vector4(.93,.69,.53,.23), "mortar":Vector4(.81,.73,.92,.0),
}

var meshes: Array[Dictionary] = []
var paints: Dictionary = {}

func set_enabled(arena: Node3D, enabled: bool) -> void:
	if enabled and meshes.is_empty():meshes = collect(arena)
	for entry in meshes:apply(entry,enabled)

func apply_prop(prop: Node3D) -> void:
	for entry in collect(prop):apply(entry,true)

func collect(root: Node3D) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for child in root.find_children("*","MeshInstance3D",true,false):
		var node := child as MeshInstance3D
		var model: Node = node
		while model!=root and model.scene_file_path.is_empty():
			model = model.get_parent()
		if not model.scene_file_path.ends_with(".glb"):continue
		var asset := model.scene_file_path.get_file().get_basename()
		for prefix in ["horse","station_stairs","fence"]:
			if asset.begins_with(prefix+"_"):
				asset = prefix
				break
		var styles: Dictionary = SURFACES[asset]
		var barrel := model.get_parent() as BARREL
		var override := node.material_override as StandardMaterial3D
		var original: Array[Material] = []
		var textured: Array[Material] = []
		for index in range(node.mesh.get_surface_count()):
			var surface := node.mesh.surface_get_material(index)
			var source := node.get_active_material(index) as StandardMaterial3D
			var tile: String = styles[surface.resource_name]
			original.append(node.get_surface_override_material(index))
			textured.append(paint(source,tile))
		var paint_override: ShaderMaterial
		if override:
			paint_override = textured[0]
		if barrel and override==barrel.paint:
			paint_override = paint_override.duplicate()
		else:
			barrel = null
		entries.append({"node":node,"original":original,"textured":textured,
			"override":override,"paint_override":paint_override,"barrel":barrel})
	return entries

func apply(entry: Dictionary, enabled: bool) -> void:
	var node: MeshInstance3D = entry.node
	node.material_override = entry.paint_override if enabled else entry.override
	if not entry.override:
		var materials: Array = entry.textured if enabled else entry.original
		for index in range(materials.size()):
			node.set_surface_override_material(index,materials[index])
	if entry.barrel:
		entry.barrel.experimental_paint = entry.paint_override if enabled else null
		if enabled:entry.barrel.set_paint_color(entry.barrel.paint.albedo_color)

func paint(source: StandardMaterial3D, tile: String) -> ShaderMaterial:
	var key := [tile,source.albedo_color]
	if paints.has(key):return paints[key]
	var material := ShaderMaterial.new()
	material.shader = PIXEL_PAINT
	material.set_shader_parameter("base_color",source.albedo_color)
	material.set_shader_parameter("profile",PROFILES[tile])
	material.set_shader_parameter("pixel_tile",load(TILES+tile+".png"))
	material.set_shader_parameter("lamp_glow",.11 if tile=="lamp_glass" else 0.0)
	paints[key] = material
	return material
