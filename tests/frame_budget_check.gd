extends SceneTree
const Budget = preload("res://scripts/performance/frame_budget.gd")
func _initialize() -> void:
	for hz in [60,120]:
		for size in [Vector2i(2532,1170),Vector2i(2796,1290),Vector2i(3840,2160)]:
			var scale = Budget.scale_for(size,hz,0,true)
			assert(maxf(size.x,size.y)*scale<= (1280.1 if hz==60 else 1024.1))
			assert(Budget.scale_for(size,hz,1,true)<scale)
	var good: Array[float] = [];good.assign([16.6,16.7,16.5,16.6,16.7,16.6,16.7,17.0])
	assert(Budget.tier_for(good,60)==0)
	assert(Budget.tier_for(good,120)==2)
	print("FRAME_BUDGET_PASS: refresh targets, physical pixel ceilings and target-relative tiers")
	quit()
