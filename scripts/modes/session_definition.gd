extends Resource
class_name SessionDefinition

@export var session_id = "score_attack"
@export var display_name = "竞技场"
@export var map_scene: PackedScene
@export var rules_script: Script
@export var layout_version = 1
@export var time_limit = 60.0
@export var round_music: AudioStream
@export var combat_music: AudioStream
@export var destroy_music: AudioStream

func make_rules() -> RefCounted:
	var result = rules_script.new()
	result.duration = time_limit
	return result
