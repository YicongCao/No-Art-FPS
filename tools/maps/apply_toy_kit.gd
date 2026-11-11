extends SceneTree
## Swap bevelled kit geometry into authored map scenes without regenerating them.
## Matches embedded meshes by their GLB resource name, keeps every node, transform,
## collision, navigation and material resource, and sets kit paint to satin roughness.
## Rebuild GLBs first: blender --background --python tools/build_assets.py (and
## tools/build_playbox_assets.py), then: godot --headless --path . --script tools/maps/apply_toy_kit.gd
const KIT = ["barrel","crate","forklift","pallet","steel_bundle","traffic_light","container_cream","container_green","container_purple","container_red","container_openable"]
const MAPS = ["res://scenes/maps/yard.tscn"]
const OLD_ROUGHNESS = .88
const TOY_ROUGHNESS = .7

func _initialize() -> void:
	var meshes := {}
	for asset in KIT:
		var model: Node = load("res://assets/models/%s.glb"%asset).instantiate()
		for part: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			meshes[part.mesh.resource_name] = part.mesh
		model.free()
	for path in MAPS:
		var map: Node = load(path).instantiate()
		var swapped := {}
		var count := 0
		for node: MeshInstance3D in map.find_children("*","MeshInstance3D",true,false):
			if not node.mesh or not meshes.has(node.mesh.resource_name):continue
			var old: Mesh = node.mesh
			if not swapped.has(old):
				var fresh: ArrayMesh = meshes[old.resource_name].duplicate()
				assert(fresh.get_surface_count()==old.get_surface_count(),old.resource_name)
				for surface in old.get_surface_count():
					var paint := old.surface_get_material(surface)
					if paint is StandardMaterial3D and is_equal_approx(paint.roughness,OLD_ROUGHNESS):paint.roughness = TOY_ROUGHNESS
					fresh.surface_set_material(surface,paint)
				swapped[old] = fresh
			node.mesh = swapped[old]
			count += 1
		var packed := PackedScene.new()
		assert(packed.pack(map)==OK)
		assert(ResourceSaver.save(packed,path)==OK)
		print("TOY_KIT_APPLIED ",path," meshes=",swapped.size()," nodes=",count)
		map.free()
	quit()
