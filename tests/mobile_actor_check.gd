extends SceneTree
const Enemy = preload("res://scripts/enemy.gd")
func _initialize() -> void:check.call_deferred()
func bounds(node: Node3D) -> AABB:
	var first := true
	var box := AABB()
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var area = node.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		box = area if first else box.merge(area)
		first = false
	return box
func check() -> void:
	var contract = {"enemy":["Head","Helmet","Visor","Torso","Vest","BrokenVest","LeftPad","LeftPadTrim","RightPad","LeftArm","RightArm","LeftLeg","RightLeg","EnemyGun"],"rusher":["Head","Helmet","Visor","Torso","ChestPlate","LeftFin","LeftHorn","RightArm","RightHand","LeftLeg","RightLeg"]}
	for kind in contract:
		var old = load("res://assets/models/toy/%s.glb"%kind).instantiate()
		var compact = load("res://assets/models/toy/%s_mobile.glb"%kind).instantiate()
		root.add_child(old);root.add_child(compact)
		for name in contract[kind]:
			var source = old.find_child(name,true,false)
			var target = compact.find_child(name,true,false)
			assert(source!=null and target!=null,name)
			assert(source.global_position.distance_to(target.global_position)<.003,"Articulated pivot drift: "+name)
		var a = bounds(old);var b = bounds(compact)
		assert(a.position.distance_to(b.position)<.005 and a.size.distance_to(b.size)<.005,"Silhouette bounds changed")
		var old_count = old.find_children("*","MeshInstance3D",true,false).size()
		var count = compact.find_children("*","MeshInstance3D",true,false).size()
		assert(count==14 and count<old_count)
		Enemy.apply_mobile_paint(compact)
		for mesh: MeshInstance3D in compact.find_children("*","MeshInstance3D",true,false):
			var arrays = mesh.mesh.surface_get_arrays(0)
			assert(arrays[Mesh.ARRAY_COLOR].size()>0)
			for response: Vector2 in arrays[Mesh.ARRAY_TEX_UV]:
				assert(response.x>=.15 and response.x<=1.0,"Material roughness lost during export")
			assert(mesh.material_override.next_pass==null)
		old.free();compact.free()
	print("MOBILE_ACTOR_PASS: 50/29 to 14 meshes, gameplay pivots, bounds, colours, single-pass rim")
	quit()
