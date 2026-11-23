extends RefCounted
## Instance repeated map visuals without changing collision, navigation, or destruction.

const Destructible = preload("res://scripts/destructible.gd")
const ConceptProp = preload("res://scripts/maps/concept_prop.gd")
const BATCH_ROOT = "WebPropBatches"
# Use smaller cells in dense interiors; wide outdoor/deck cells group sparse repeats.
const CELLS = {
	"bb_office": 12.0, "night_studio": 12.0, "amusement_park": 22.0,
	"sandgate": 36.0, "last_ferry": 24.0, "hogwarts": 24.0,
	"snowline": 24.0, "palm_house": 24.0, "ginza_station": 22.0,
}
const PARK_FAMILIES = ["Bench", "Kiosk", "Lamp", "Palm", "Planter"]
const FERRY_PROPS = ["PortCrates", "StarboardCrates", "ForeCrates", "AftCrates",
	"PortLocker", "StarboardLocker", "BowLocker", "PortLifeboat", "StarboardLifeboat"]

static func apply(arena: Node3D, opaque_shaders: Array) -> void:
	var id: String = arena.map_id
	if not CELLS.has(id) or arena.has_node(BATCH_ROOT):
		return
	var groups := {}
	var to_map := arena.global_transform.affine_inverse()
	var side: float = CELLS[id]
	# Keep the measured office/studio cell layout. Center sparse cells around their lanes.
	var offset := 0.0 if id in ["bb_office", "night_studio", "sandgate"] else side * 0.5
	for prop in arena.structures:
		var model := scenery_model(id, prop)
		if model:
			collect(groups, model, prop, to_map, side, offset, opaque_shaders)
	if id == "sandgate":
		# Background clouds are permanent, not finale decorations.
		for node in arena.get_children():
			if numbered_family(str(node.name), "Cloud"):
				collect(groups, node, null, to_map, side, offset, opaque_shaders)

	var parent := Node3D.new()
	parent.name = BATCH_ROOT
	arena.add_child(parent)
	var meshes := {}
	for key in groups:
		var entries: Array = groups[key]
		if entries.size() < 2:
			continue
		var style: Array = key[0]
		if not meshes.has(style):
			# Do not mutate the imported mesh shared by other scenes and cells.
			var copy: ArrayMesh = style[0].duplicate()
			for surface in copy.get_surface_count():
				copy.surface_set_material(surface, style[1][surface])
			meshes[style] = copy
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = meshes[style]
		instances.instance_count = entries.size()
		var batch := MultiMeshInstance3D.new()
		batch.layers = style[2]
		batch.cast_shadow = style[3]
		batch.lod_bias = style[4]
		batch.multimesh = instances
		parent.add_child(batch)
		var path := arena.get_path_to(batch)
		var transforms: Array[Transform3D] = []
		for i in entries.size():
			var entry: Array = entries[i]
			instances.set_instance_transform(i, entry[2])
			transforms.append(entry[2])
			if entry[0]:
				entry[0].batch_parts.get_or_add(path, []).append(i)
			entry[1].mesh = null
		if style[5]:
			arena.initial_batches[batch] = transforms # Destructibles only.

static func scenery_model(id: String, prop: Node3D) -> Node3D:
	if id == "sandgate" or prop.get_script() not in [Destructible, ConceptProp]:
		return null
	if not prop.scenery or prop.structural_section or prop.keep_boundary or not prop.batch_parts.is_empty():
		return null
	var name := str(prop.name)
	var model_path := "Model"
	if id == "amusement_park":
		# The rides are scenery as well, but their visuals animate independently.
		if not PARK_FAMILIES.any(func(prefix): return numbered_family(name, prefix)):
			return null
		model_path = name
	elif id == "last_ferry" and name not in FERRY_PROPS:
		return null
	var model := prop.get_node_or_null(model_path) as Node3D
	return model if model in prop.parts else null

static func numbered_family(name: String, prefix: String) -> bool:
	return name.begins_with(prefix) and name.substr(prefix.length()).is_valid_int()

static func collect(groups: Dictionary, model: Node3D, prop: Node3D, to_map: Transform3D,
		side: float, offset: float, opaque_shaders: Array) -> void:
	var sources := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		sources.push_front(model)
	for source: MeshInstance3D in sources:
		if not source.is_visible_in_tree() or not source.mesh is ArrayMesh or source.skin:
			continue
		if source.mesh.get_blend_shape_count() or source.material_overlay or source.transparency > 0.0:
			continue
		if (source.custom_aabb != AABB() or source.extra_cull_margin > 0.0
				or source.visibility_range_begin > 0.0 or source.visibility_range_end > 0.0):
			continue
		var pose := to_map * source.global_transform
		if pose.basis.determinant() <= 0.0:
			continue # MultiMesh cannot flip back-face culling per instance.
		var materials := opaque_materials(source, opaque_shaders)
		if materials.is_empty():
			continue
		var at := (pose * source.get_aabb()).get_center()
		var cell := Vector2i(floori((at.x + offset) / side), floori((at.z + offset) / side))
		var style := [source.mesh, materials, source.layers, source.cast_shadow, source.lod_bias, prop != null]
		groups.get_or_add([style, cell], []).append([prop, source, pose])

static func opaque_materials(source: MeshInstance3D, opaque_shaders: Array) -> Array[Material]:
	var materials: Array[Material] = []
	for surface in source.mesh.get_surface_count():
		var material := source.get_active_material(surface)
		if not material or material.next_pass:
			return []
		if material is BaseMaterial3D:
			if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				return []
		elif not material is ShaderMaterial or material.shader not in opaque_shaders:
			return []
		materials.append(material)
	return materials
