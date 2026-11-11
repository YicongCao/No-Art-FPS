extends SceneTree
## Reusable, seamless detail field. Generated offline, never during map loading.
func _initialize() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = 11011
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = .024
	noise.fractal_octaves = 4
	var texture = NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.noise = noise
	await texture.changed
	DirAccess.make_dir_recursive_absolute("res://assets/textures/rain_market")
	assert(texture.get_image().save_png("res://assets/textures/rain_market/surface_noise.png")==OK)
	print("MARKET_SURFACE_GENERATED")
	quit()
