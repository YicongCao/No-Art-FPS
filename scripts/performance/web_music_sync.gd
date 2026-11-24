extends RefCounted
## Keep only the music near the game clock. Never feed audio time back to the rules.

const INTERVAL := .5
const DRIFT_LIMIT := .25
const CONFIRMATIONS := 3
const COOLDOWN := 5.0
const FADE_SECONDS := .07
const LOW_GAIN_DB := -36.0

var player: AudioStreamPlayer
var origin := 0.0
var length := 0.0
var looped := false
var latency := 0.0
var volume_db := 0.0
var gain := 1.0
var fade := 0
var probe := 0.0
var streak := 0
var cooldown := 0.0
var drift := 0.0
var last_probe_position := -1.0
var seeks := 0

func start_track(elapsed: float) -> void:
	origin = elapsed
	length = player.stream.get_length()
	# All looping round cues are Ogg tracks with a zero loop offset.
	looped = player.stream is AudioStreamOggVorbis and player.stream.loop and player.stream.loop_offset==0.0
	latency = AudioServer.get_output_latency()
	cooldown = 0.0
	suspend()

func set_volume(db: float) -> void:
	volume_db = db
	apply_gain()

func apply_gain() -> void:
	player.volume_db = volume_db + lerpf(LOW_GAIN_DB,0.0,gain)

func suspend() -> void:
	probe = 0.0
	streak = 0
	drift = 0.0
	last_probe_position = -1.0
	if fade!=0:
		fade = 0
		gain = 1.0
		apply_gain()

func track_target(elapsed: float) -> float:
	var age := elapsed-origin
	if length<=0.0 or age<INTERVAL or (not looped and age>=length-.25):return -1.0
	return fposmod(age,length) if looped else age

func observe(target: float, audible: float) -> bool:
	drift = audible-target
	if looped:drift = fposmod(drift+length*.5,length)-length*.5
	if absf(drift)<DRIFT_LIMIT:
		streak = 0
		return false
	var direction := 1 if drift>0.0 else -1
	streak = streak+direction if streak*direction>0 else direction
	return absi(streak)>=CONFIRMATIONS

# Returns true only when we have repositioned the cue.
func update(delta: float, elapsed: float) -> bool:
	cooldown = maxf(0.0,cooldown-delta)
	var target := track_target(elapsed)
	if target<0.0:
		suspend()
		return false
	if fade!=0:
		gain = move_toward(gain,0.0 if fade<0 else 1.0,delta/FADE_SECONDS)
		apply_gain()
		if fade<0 and gain==0.0:
			latency = AudioServer.get_output_latency()
			var position := target+latency
			position = fposmod(position,length) if looped else minf(position,length-.05)
			player.play(position)
			fade = 1
			cooldown = COOLDOWN
			seeks += 1
			return true
		if fade>0 and gain==1.0:fade = 0
		return false
	if cooldown>0.0:return false
	probe += delta
	if probe<INTERVAL:return false
	probe = 0.0
	# A stopped cue well inside its timeline is equivalent to sustained drift.
	var needs_seek: bool
	if not player.playing:
		streak = mini(streak,0)-1
		needs_seek = -streak>=CONFIRMATIONS
	else:
		var position := player.get_playback_position()
		var advancing := last_probe_position<0.0 or not is_equal_approx(position,last_probe_position)
		last_probe_position = position
		if not advancing:
			streak = 0
			return false
		latency = AudioServer.get_output_latency()
		needs_seek = observe(target,position+AudioServer.get_time_since_last_mix()-latency)
	if needs_seek:
		fade = -1
		streak = 0
	return false
