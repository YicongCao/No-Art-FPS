extends SceneTree

const Rules = preload("res://scripts/run_rules.gd")

func _initialize() -> void:
	var rules = Rules.new()
	assert(not rules.record_kill(1,true),"Idle runs cannot score")
	rules.start()
	assert(rules.record_kill(1,true))
	assert(not rules.record_kill(1,false),"A dead enemy cannot score twice")
	assert(rules.kills==1 and rules.headshots==1)
	rules.tick(59.99)
	assert(rules.record_kill(2,false),"Kills before the deadline count")
	rules.tick(.01)
	assert(not rules.active and rules.elapsed==60)
	assert(not rules.record_kill(3,true),"Deadline kills cannot count")
	rules.tick(20)
	assert(rules.elapsed==60 and rules.kills==2)
	rules.deaths = 3
	rules.start()
	assert(rules.elapsed==0 and rules.kills==0 and rules.headshots==0 and rules.deaths==0 and rules.defeated.is_empty())
	assert(rules.record_kill(1,false),"Restart resets the death registry")
	for i in range(3600):rules.tick(1.0/60.0)
	assert(not rules.active and rules.remaining()==0,"Exactly 3600 physics ticks end the round")
	print("RULES_PASS: idle, duplicate death, deadline, late score, restart, fixed tick clock")
	quit()
