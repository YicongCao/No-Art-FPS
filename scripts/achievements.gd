extends RefCounted

signal unlocked(id: String)
signal changed

const COLLECTION_BADGE = "no_art"
const BADGES = {
	"first": ["FIRST BLOOD","First combat kill",1,preload("res://assets/ui/achievements/first.svg")],
	"headshot": ["PINPOINT","12 headshots across rounds",12,preload("res://assets/ui/achievements/headshot.svg")],
	"triple": ["TRIPLE TAP","3 kills within 1.25 seconds",3,preload("res://assets/ui/achievements/triple.svg")],
	"barrel": ["BARREL DEAL","Kill an enemy with an oil barrel explosion",1,preload("res://assets/ui/achievements/barrel.svg")],
	"yard": ["YARD SHIFT","12 combat kills in one yard round",12,preload("res://assets/ui/achievements/yard.svg")],
	"park": ["LAST RIDE","5 kills in one park DESTROY ALL phase",5,preload("res://assets/ui/achievements/park.svg")],
	"ferry": ["HIGH TIDE","3 kills from high ground on the ferry in one round",3,preload("res://assets/ui/achievements/ferry.svg")],
	"studio": ["OFF AIR","Destroy a Night Studio backdrop",1,preload("res://assets/ui/achievements/studio.svg")],
	"wreck": ["WRECKING CREW","Destroy 8 props or structures across rounds",8,preload("res://assets/ui/achievements/wreck.svg")],
	"clean": ["STILL STANDING","Finish 60 seconds with no deaths and 8 combat kills",8,preload("res://assets/ui/achievements/clean.svg")],
	"water": ["SPLASH ZONE","10 combat kills in water blaster mode",10,preload("res://assets/ui/achievements/water.svg")],
	"slipper": ["SOLE JUSTICE","10 combat kills in slipper launcher mode",10,preload("res://assets/ui/achievements/slipper.svg")],
	"poop": ["POOP PATROL","15 combat kills in Poop Mode",15,preload("res://assets/ui/achievements/poop.svg")],
	"grenade": ["PIN PULLER","15 kills with grenades across rounds",15,preload("res://assets/ui/achievements/grenade.svg")],
	COLLECTION_BADGE: ["NO ART","Unlock every other badge",1,preload("res://assets/ui/achievements/no_art.svg")],
}
var counts: Dictionary = {}
var scores: Dictionary = {}
var run_unlocks: Array[String] = []
var combat_kills = 0
var park_destroy_kills = 0
var ferry_catwalk_kills = 0

func start_round() -> void:
	run_unlocks.clear()
	combat_kills = 0
	park_destroy_kills = 0
	ferry_catwalk_kills = 0

func unlocked_badge(id: String) -> bool:
	return counts.get(id,0)>=BADGES[id][2]

func advance(id: String, value: int) -> void:
	if id==COLLECTION_BADGE:return
	var previous: int = counts.get(id,0)
	var target: int = BADGES[id][2]
	var next = clampi(value,previous,target)
	if next==previous:return
	counts[id] = next
	if next==target:
		award(id)
		check_collection(true)
	changed.emit()

func award(id: String) -> void:
	run_unlocks.append(id)
	unlocked.emit(id)

func check_collection(announce: bool) -> void:
	if unlocked_badge(COLLECTION_BADGE):return
	for id in BADGES:
		if id!=COLLECTION_BADGE and not unlocked_badge(id):return
	counts[COLLECTION_BADGE] = 1
	if announce:award(COLLECTION_BADGE)

func increment(id: String, amount: int = 1) -> void:
	advance(id,counts.get(id,0)+amount)

func combat_kill(map: String, headshot: bool, streak: int, destroy_phase: bool, elevation: float, toy: String) -> void:
	combat_kills += 1
	advance("first",1)
	if headshot:increment("headshot")
	advance("triple",streak)
	match map:
		"score_attack":advance("yard",combat_kills)
		"amusement_park":
			if destroy_phase:
				park_destroy_kills += 1
				advance("park",park_destroy_kills)
		"last_ferry":
			if elevation>=2.55:
				ferry_catwalk_kills += 1
				advance("ferry",ferry_catwalk_kills)
	match toy:
		"comedy":
			increment("water")
			increment("poop")
		"roach":increment("slipper")

func finish_round(completed: bool, deaths: int) -> void:
	if completed and deaths==0:advance("clean",combat_kills)

func snapshot() -> Dictionary:
	return {"achievements":counts,"scores":scores}

func merge(snapshot_data: Variant) -> void:
	if not snapshot_data is Dictionary:return
	var loaded: Variant = snapshot_data.get("achievements")
	if loaded is Dictionary:
		for id in BADGES:
			if id==COLLECTION_BADGE:continue
			var value: Variant = loaded.get(id)
			if value is int or (value is float and is_finite(value)):
				var progress = int(clampf(float(value),0,BADGES[id][2]))
				if progress>counts.get(id,0):counts[id] = progress
		# Older saves stored up to ten kills from the same mode under "water".
		if counts.get("water",0)>counts.get("poop",0):counts["poop"] = counts["water"]
		check_collection(false)
	loaded = snapshot_data.get("scores")
	if loaded is Dictionary:
		for key in loaded:
			if key is String and (key=="score" or key.begins_with("score_")):
				merge_score(key,loaded[key])

func merge_score(key: String, value: Variant) -> void:
	if value is int or (value is float and is_finite(value)):
		var score = int(clampf(float(value),0,2147483647))
		if score>scores.get(key,0):scores[key] = score
