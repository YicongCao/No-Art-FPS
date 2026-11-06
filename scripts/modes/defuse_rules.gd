extends "res://scripts/run_rules.gd"

var objective_ids: Array[String] = ["a_site","short","ct_court"]
var completed: Dictionary = {}
var pending: Dictionary = {}
var fatal = false
var outcome = ""

func _init() -> void:
	duration = 180.0
	respawn_allowed = false
	destroy_duration = 0
	finale_duration = 0
	continuous_spawns = false
	mission = true

func start() -> void:
	super.start()
	completed.clear()
	pending.clear()
	fatal = false
	outcome = ""

func tick(delta: float) -> void:
	if active:elapsed = minf(duration,elapsed+maxf(0,delta))
	if elapsed>=duration-.000001:elapsed = duration

func request_defuse(id: String) -> bool:
	if not active or elapsed>=duration or fatal or not id in objective_ids or completed.has(id) or pending.has(id):return false
	pending[id] = elapsed
	return true

func cancel_defuse(id: String) -> void:
	pending.erase(id)

func report_death() -> void:
	if active:fatal = true

func settle() -> void:
	if not active:return
	if fatal:outcome = "DEAD"
	elif elapsed>=duration:outcome = "TIMEOUT"
	else:
		completed.merge(pending)
		if completed.size()==objective_ids.size():outcome = "SUCCESS"
	pending.clear()
	if not outcome.is_empty():active = false

func result_value() -> float:
	return elapsed if outcome=="SUCCESS" else -1.0
