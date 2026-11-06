extends RefCounted

const WAIT_LIMIT = 17.0
const SEAT_DURATION = .22
const REVEAL_DURATION = .65
const DOCK_DURATION = .65

var phase = "FILL"
var phase_time = 0.0
var rounds = 0.0
var work_progress = 0.0
var work_complete = false
var idle_time = 0.0
var suspended = false

func report(value: float) -> void:
	work_progress = maxf(work_progress,clampf(value,0,1))
	idle_time = 0

func advance(delta: float) -> void:
	if suspended:return
	# Never skip visual stages after a delayed frame.
	delta = minf(delta,.05)
	phase_time += delta
	if phase=="FILL":
		idle_time += delta
		var measured = work_progress*16.0
		var estimate = measured+(WAIT_LIMIT-measured)*(1-exp(-idle_time*.7))
		if idle_time>=3:estimate = WAIT_LIMIT
		var target = 20.0 if work_complete else minf(WAIT_LIMIT,estimate)
		rounds = move_toward(rounds,maxf(rounds,target),delta*19.0)
		if work_complete and rounds>=20:
			phase = "SEAT"
			phase_time = 0
	elif phase=="SEAT" and phase_time>=SEAT_DURATION:
		phase = "REVEAL"
		phase_time = 0
	elif phase=="REVEAL" and phase_time>=REVEAL_DURATION:
		phase = "DOCK"
		phase_time = 0
	elif phase=="DOCK" and phase_time>=DOCK_DURATION:
		phase = "DONE"
		phase_time = 0

func seating_offset(reduced_motion: bool) -> float:
	if phase!="SEAT":return 0
	var depth = 4.0 if reduced_motion else 16.0
	if phase_time<.14:return depth*smoothstep(0,.14,phase_time)
	return depth*pow(1-clampf((phase_time-.14)/.08,0,1),3)

func reveal_progress() -> float:
	if phase in ["DOCK","DONE"]:return 1
	return smoothstep(0,REVEAL_DURATION,phase_time) if phase=="REVEAL" else 0.0

func dock_progress() -> float:
	if phase=="DONE":return 1
	return smoothstep(0,DOCK_DURATION,phase_time) if phase=="DOCK" else 0.0
