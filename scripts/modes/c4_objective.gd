extends Node3D
class_name C4Objective

@export var objective_id = ""
@export var defuse_duration = 5.0
@export var reach = 1.8
var game: Node
var progress = 0.0
var defused = false
var needs_release = false
var submitted = false
var beep_time = 0.0

func available() -> bool:
	if game==null or game.state!="RUNNING" or not game.rules.active or game.health<=0 or defused:return false
	if game.player.global_position.distance_to(global_position)>reach:return false
	var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,global_position+Vector3.UP*.1,1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func cancel(require_release: bool = true) -> void:
	progress = 0
	submitted = false
	if game:
		game.rules.cancel_defuse(objective_id)
		if game.objective_focus==self:game.objective_focus = null
	needs_release = require_release

func reset() -> void:
	progress = 0
	defused = false
	needs_release = false
	submitted = false
	get_node("Indicator").modulate = Color("f2d084")
	get_node("Indicator").show()
	beep_time = 0

func _physics_process(delta: float) -> void:
	if game==null or not game.rules.mission:return
	if game.state=="RUNNING" and game.rules.active and not defused:
		beep_time -= delta
		if beep_time<=0:
			beep_time = 1.5
			if game.player.global_position.distance_to(global_position)<10:game.play_world_sound("tick",global_position,-22)
	if game.rules.completed.has(objective_id):
		mark_defused()
		return
	var held = game.interact_held()
	if not held:
		if progress>0 and not submitted:cancel(false)
		needs_release = false
		return
	if submitted:return
	if needs_release:return
	if not available() or game.reload_time>0 or (game.objective_focus!=null and game.objective_focus!=self):
		if progress>0:cancel()
		return
	if game.player.velocity.length()>.15:
		if progress>0:cancel()
		return
	game.objective_focus = self
	progress = minf(defuse_duration,progress+delta)
	if progress>=defuse_duration-.000001:
		submitted = game.rules.request_defuse(objective_id)
		if not submitted:cancel()

func mark_defused() -> void:
	if defused:return
	game.play_sound("reload",-12,1.4)
	defused = true
	progress = defuse_duration
	get_node("Indicator").hide()
	if game.objective_focus==self:game.objective_focus = null
