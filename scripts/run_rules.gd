extends RefCounted

const DURATION = 60.0
var duration = DURATION
var respawn_allowed = true
var destroy_duration = 15.0
var finale_duration = 1.0
var continuous_spawns = true
var mission = false
var active = false
var elapsed = 0.0
var kills = 0
var headshots = 0
var shots = 0
var hits = 0
var deaths = 0
var defeated: Dictionary = {}

func start() -> void:
	active = true
	elapsed = 0.0
	kills = 0
	headshots = 0
	shots = 0
	hits = 0
	deaths = 0
	defeated.clear()

func tick(delta: float) -> void:
	if not active:return
	elapsed = minf(duration,elapsed+maxf(0,delta))
	if elapsed >= duration-0.000001:
		elapsed = duration
		active = false

func record_kill(id: int, headshot: bool) -> bool:
	if not active or elapsed >= duration or defeated.has(id):return false
	defeated[id] = true
	kills += 1
	if headshot:headshots += 1
	return true

func remaining() -> float:
	return maxf(0,duration-elapsed)

func settle() -> void:
	pass

func report_death() -> void:
	pass

func result_value() -> float:
	return float(kills)
