extends RefCounted

const DURATION = 60.0
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
	elapsed = minf(DURATION,elapsed+maxf(0,delta))
	if elapsed >= DURATION-0.000001:
		elapsed = DURATION
		active = false

func record_kill(id: int, headshot: bool) -> bool:
	if not active or elapsed >= DURATION or defeated.has(id):return false
	defeated[id] = true
	kills += 1
	if headshot:headshots += 1
	return true

func remaining() -> float:
	return maxf(0,DURATION-elapsed)
