extends RefCounted
## Shared painted-toy camera response: filmic highlights and a painted sky gradient.
## Runs after map-specific lookdev, so frenzy background colours still drive the sky.
const SKY = preload("res://assets/shaders/toy_sky.gdshader")
const EXPOSURE = 1.0
const WHITE = 5.5
const SATURATION = 1.15
const CONTRAST = 1.06

static func apply(env: Environment) -> void:
	if env==null:return
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = EXPOSURE
	env.tonemap_white = WHITE
	env.adjustment_enabled = true
	env.adjustment_saturation = SATURATION
	env.adjustment_contrast = CONTRAST
	if env.background_mode==Environment.BG_COLOR and not env.has_meta("toy_sky"):
		var paint := ShaderMaterial.new()
		paint.shader = SKY
		env.sky = Sky.new()
		env.sky.sky_material = paint
		env.sky.radiance_size = Sky.RADIANCE_SIZE_64
		env.background_mode = Environment.BG_SKY
		env.set_meta("toy_sky",paint)
	if env.has_meta("toy_sky"):
		var sky: ShaderMaterial = env.get_meta("toy_sky")
		var base := env.background_color
		var horizon := base.lerp(Color("fff1df"),.42)
		sky.set_shader_parameter("top_color",base.darkened(.12))
		sky.set_shader_parameter("horizon_color",horizon)
		sky.set_shader_parameter("ground_color",horizon.darkened(.22))
