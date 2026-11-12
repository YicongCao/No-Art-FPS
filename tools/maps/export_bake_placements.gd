extends SceneTree

# Records where every model kit sits in each map, for tools/maps/bake_vertex_light.py.
# godot --headless --path . --script tools/maps/export_bake_placements.gd
# Writes tools/maps/bake_placements.json. A kit is "static" when neither it nor any ancestor below
# the map root carries a script (destructible props, doors, carousels) or sits under "Moving".
const MAPS = ["amusement_park","baggage_below","bb_office","ginza_station","hogwarts","last_ferry","night_studio","palm_house","rain_market","sandgate","snowline"]

func _initialize() -> void:
	var result := {}
	for id in MAPS:
		var map: Node = load("res://scenes/maps/%s.tscn"%id).instantiate()
		var kits: Array = []
		for node: Node3D in map.find_children("*","Node3D",true,false):
			if not node.scene_file_path.ends_with(".glb"):continue
			var static_kit := true
			var place := Transform3D.IDENTITY
			var cursor: Node = node
			while cursor!=map:
				if cursor.get_script()!=null or cursor.name=="Moving":static_kit = false
				if cursor is Node3D:place = (cursor as Node3D).transform*place
				cursor = cursor.get_parent()
			var basis := place.basis
			kits.append({
				"kit":node.scene_file_path.trim_prefix("res://"),
				"node":str(map.get_path_to(node)),
				"static":static_kit,
				"transform":[basis.x.x,basis.x.y,basis.x.z,basis.y.x,basis.y.y,basis.y.z,basis.z.x,basis.z.y,basis.z.z,place.origin.x,place.origin.y,place.origin.z],
			})
		result[id] = kits
		map.free()
	var file := FileAccess.open("res://tools/maps/bake_placements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("BAKE_PLACEMENTS ",result.size())
	quit()
