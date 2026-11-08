extends "res://scripts/destructible.gd"

var door_hits := 0

func restore() -> void:
	super.restore()
	door_hits = 0

func breach_hit() -> void:
	door_hits += 1
	if door_hits == 2:
		game.play_world_sound("hit",world_bounds().get_center(),-13)
		collapse(false)

func ignite_hit(point: Vector3) -> void:
	hits = maxi(hits,door_hits)
	super.ignite_hit(point)
