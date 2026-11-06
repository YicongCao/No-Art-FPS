extends Node
var game: Node
func _ready() -> void:
	process_physics_priority = 100
func _physics_process(_delta: float) -> void:
	game.settle_rules()
