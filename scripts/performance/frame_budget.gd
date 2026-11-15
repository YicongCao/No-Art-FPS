extends RefCounted

static func scale_for(size: Vector2i, target: int, tier: int, mobile: bool) -> float:
	var edge := 1024.0 if target==120 else 1280.0
	var pixels := 1024.0*576.0 if target==120 else 1280.0*720.0
	if not mobile:edge = 1920.0;pixels = 1920.0*1080.0
	var base := minf(1.0,minf(edge/maxf(size.x,size.y),sqrt(pixels/maxf(1.0,float(size.x)*size.y))))
	return clampf(base*[1.0,.85,.70][clampi(tier,0,2)],.125,1.0)

static func tier_for(samples: Array[float], target: int) -> int:
	if samples.size()<8:return 0
	var sorted = samples.duplicate()
	sorted.sort()
	var typical: float = sorted[int(sorted.size()*.75)]
	var budget := 1000.0/target
	return 2 if typical>budget*1.9 else (1 if typical>budget*1.22 else 0)
