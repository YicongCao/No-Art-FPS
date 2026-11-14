extends "res://scripts/maps/sandgate.gd"

# The same combat/respawn contract, with a separate authored lighting profile.
func validate_map() -> bool:
	return map_id == "moonbase_trial" and super.validate_map()

# Eight authored interaction groups outside traversal corridors. Static cover stays intact.
func interactive_prop_entries() -> Array:
	return [
		{"kind":"space_battery","asset":"res://assets/models/space/battery-rack.glb","at":[-5,0,11],"yaw":0.0},
		{"kind":"space_battery","asset":"res://assets/models/space/battery-rack.glb","at":[17,0,-6],"yaw":0.0},
		{"kind":"space_valves","asset":"res://assets/models/space/pressure-valves.glb","at":[11,0,-8],"yaw":0.0},
		{"kind":"space_valves","asset":"res://assets/models/space/pressure-valves.glb","at":[17,0,-16],"yaw":0.0},
		{"kind":"space_console","asset":"res://assets/models/space/control-console.glb","at":[5,0,-11],"yaw":PI},
		{"kind":"space_console","asset":"res://assets/models/space/control-console.glb","at":[7,0,14],"yaw":0.0},
		{"kind":"space_supply","asset":"res://assets/models/space/supply-case.glb","at":[-16,0,11],"yaw":PI},
		{"kind":"space_supply","asset":"res://assets/models/space/supply-case.glb","at":[3,0,5],"yaw":PI}
	]

func set_destroy_lighting(active: bool) -> void:
	for lamp in find_children("OverloadLight*","OmniLight3D",true,false):lamp.light_energy = .85 if active else 0.0
