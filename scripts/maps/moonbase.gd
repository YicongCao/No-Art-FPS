extends "res://scripts/maps/sandgate.gd"

# The same combat/respawn contract, with a separate authored lighting profile.
func validate_map() -> bool:
	return map_id == "moonbase_trial" and super.validate_map()
