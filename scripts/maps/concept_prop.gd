extends "res://scripts/destructible.gd"

@export var impact_kind := ""

func collapse(show_effects: bool = true) -> void:
	if collapsed:
		return
	super.collapse(show_effects)
	if collapsed and show_effects and hits>=2 and not impact_kind.is_empty():
		arena.scatter_prop(impact_kind,hit_point,Vector3.UP,world_bounds().position.y,true)
