extends RefCounted
## Per-map colour script for the toy look: key light, shadow colour, haze, glow and actor rim.
## Maps without an entry keep their authored lighting. Applied by MapLookdev.apply_state before
## the shared camera response in toy_look.gd.

const DEFAULT_RIM = Color(.62,.78,1.0)
const DEFAULT_RIM_STRENGTH = .48

# sun: colour, energy, rotation. ambient: colour and energy for shadowed sides.
# fog: colour, density. glow: intensity, threshold. emission: multiplier for lit windows and lamps.
# rim: cool or warm edge that separates enemies from this map's dominant colours.
const PALETTES = {
	"hogwarts": {
		# Sunset behind the pitch: warm low key, violet shadows, pink haze toward the castle.
		"sun": [Color("ffcfa3"),1.0,Vector3(-24,-43,0)],
		"ambient": [Color("b6b2f2"),.52],
		"fog": [Color("d9a7c4"),.0032],
		"glow": [.42,1.05],
		"emission": 1.8,
		"rim": [Color("9fe4ff"),.62],
	},
}

static func has_palette(map_id: String) -> bool:
	return PALETTES.has(map_id)

static func emission_boost(map_id: String) -> float:
	return PALETTES.get(map_id,{}).get("emission",1.0)

static func apply(map_id: String, env: Environment, sun: DirectionalLight3D, frenzy: bool) -> void:
	var rim: ShaderMaterial = load("res://scripts/enemy.gd").toy_rim()
	var palette: Dictionary = PALETTES.get(map_id,{})
	rim.set_shader_parameter("rim_color",palette.rim[0] if palette.has("rim") else DEFAULT_RIM)
	rim.set_shader_parameter("strength",palette.rim[1] if palette.has("rim") else DEFAULT_RIM_STRENGTH)
	if palette.is_empty() or env==null:return
	sun.light_color = palette.sun[0]
	sun.light_energy = palette.sun[1]
	sun.rotation_degrees = palette.sun[2]
	if not frenzy:
		env.ambient_light_color = palette.ambient[0]
		env.ambient_light_energy = palette.ambient[1]
	env.fog_enabled = true
	env.fog_light_color = palette.fog[0]
	env.fog_density = palette.fog[1]
	env.fog_light_energy = 1.0
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = palette.glow[0]
	env.glow_hdr_threshold = palette.glow[1]
	env.glow_bloom = 0.0
