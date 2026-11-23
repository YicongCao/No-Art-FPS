extends RefCounted
## Instance repeated office scenery without changing the nodes that own collision and destruction.

const Destructible = preload("res://scripts/destructible.gd")
const CELL_SIZE = 12.0
const BATCH_ROOT = "WebPropBatches"

static func apply(office: Node3D, opaque_shaders: Array) -> void:
	if office.has_node(BATCH_ROOT):
		return
	var groups := {}
	var to_office := office.global_transform.affine_inverse()
	for prop in office.get_node("Props").get_children():
		# Doors and separately managed interactive models stay on their original paths.
		if prop.get_script() != Destructible or not prop.scenery or not prop.batch_parts.is_empty():
			continue
		var model := prop.get_node_or_null("Model")
		if not model or model not in prop.parts:
			continue
		var sources := model.find_children("*", "MeshInstance3D", true, false)
		if model is MeshInstance3D:
			sources.push_front(model)
		for source: MeshInstance3D in sources:
			if not source.is_visible_in_tree() or not source.mesh is ArrayMesh or source.skin:
				continue
			if source.mesh.get_blend_shape_count() or source.material_overlay or source.transparency > 0.0:
				continue
			if source.custom_aabb != AABB() or source.extra_cull_margin > 0.0 or source.visibility_range_begin > 0.0 or source.visibility_range_end > 0.0:
				continue
			var pose := to_office * source.global_transform
			if pose.basis.determinant() <= 0.0:
				continue # MultiMesh cannot flip back-face culling per instance.
			var materials := opaque_materials(source, opaque_shaders)
			if materials.is_empty():
				continue
			var at := (pose * source.get_aabb()).get_center()
			var cell := Vector2i(floori(at.x / CELL_SIZE), floori(at.z / CELL_SIZE))
			var style := [source.mesh, materials, source.layers, source.cast_shadow, source.lod_bias]
			groups.get_or_add([style, cell], []).append([prop, source, pose])

	var parent := Node3D.new()
	parent.name = BATCH_ROOT
	office.add_child(parent)
	var meshes := {}
	for key in groups:
		var entries: Array = groups[key]
		if entries.size() < 2:
			continue
		var style: Array = key[0]
		if not meshes.has(style):
			# The imported resource is shared by all office instances. Keep the
			# resolved lookdev materials on a copy, shared across spatial cells.
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
		var path := office.get_path_to(batch)
		var transforms: Array[Transform3D] = []
		for i in entries.size():
			var entry: Array = entries[i]
			instances.set_instance_transform(i, entry[2])
			transforms.append(entry[2])
			# Use the existing Destructible collapse/restore hooks for this slot.
			entry[0].batch_parts.get_or_add(path, []).append(i)
			entry[1].mesh = null
		office.initial_batches[batch] = transforms

static func opaque_materials(source: MeshInstance3D, opaque_shaders: Array) -> Array[Material]:
	var materials: Array[Material] = []
	for surface in source.mesh.get_surface_count():
		var material := source.get_active_material(surface)
		if not material or material.next_pass:
			return []
		if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return []
		if material is ShaderMaterial and material.shader not in opaque_shaders:
			return []
		materials.append(material)
	return materials
