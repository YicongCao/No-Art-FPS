extends RefCounted
## Per-map colour script for the toy look: key light, shadow colour, haze, glow and actor rim.
## Maps without an entry keep their authored lighting. Applied by MapLookdev.apply_state (and by
## MarketLookdev for the rain market) before the shared camera response in toy_look.gd.

const DEFAULT_RIM = Color(.62,.78,1.0)
const DEFAULT_RIM_STRENGTH = .48

# sun: colour, energy, rotation. ambient: colour and energy for shadowed sides.
# fog: colour, density. glow: intensity, threshold. emission: multiplier for lit windows and lamps.
# practicals: how many lamp fixtures get a real light, with energy and range; the rest keep only
# the painted light pool. rim: edge colour that separates enemies from this map's dominant colours.
# Any key may be left out; that part of the authored lighting stays.
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
	"yard": {
		# Late-morning container yard: clean warm key, periwinkle shade, light blue distance.
		"sun": [Color("ffe4bd"),.95,Vector3(-38,-35,0)],
		"ambient": [Color("adbaf2"),.55],
		"fog": [Color("cfe0fa"),.0016],
		"rim": [Color("9fe4ff"),.6],
	},
	"sandgate": {
		# Desert afternoon: hot amber key, lilac shade, dusty ochre haze down the long lanes.
		"sun": [Color("ffdcaa"),.9,Vector3(-36,35,0)],
		"ambient": [Color("bcc2f4"),.64],
		"fog": [Color("ecd6b2"),.0018],
		"glow": [.3,1.1],
		"rim": [Color("8fe0ff"),.62],
	},
	"snowline": {
		# Clear alpine morning: neutral-warm key, saturated blue shade on snow, cold haze.
		"sun": [Color("fff0d6"),1.0,Vector3(-24,-39,0)],
		"ambient": [Color("9fb8ff"),.56],
		"fog": [Color("cddcff"),.0042],
		"glow": [.32,1.05],
		"rim": [Color("ffb27a"),.58],
	},
	"amusement_park": {
		# Golden hour on the boardwalk: orange key, violet shade, peach haze, lit bulbs.
		"sun": [Color("ffc58c"),1.0,Vector3(-17,145,0)],
		"ambient": [Color("b2a6ee"),.5],
		"fog": [Color("f0b49a"),.0026],
		"glow": [.45,1.0],
		"emission": 1.6,
		"practicals": [6,.8,5.0],
		"rim": [Color("9fe4ff"),.62],
	},
	"palm_house": {
		# Bright greenhouse noon: creamy key, teal shade under the leaves, faint green-white haze.
		"sun": [Color("fff0d2"),1.0,Vector3(-46,-28,0)],
		"ambient": [Color("c4d2f4"),.64],
		"fog": [Color("dcefe4"),.0016],
		"glow": [.3,1.1],
		"rim": [Color("ffc0e0"),.55],
	},
	"last_ferry": {
		# Harbour at night: sodium-warm key on the planks, deep indigo shade, lamps that light the deck.
		"sun": [Color("ffd2a0"),.36,Vector3(-40,-23,0)],
		"ambient": [Color("8088d0"),.46],
		"fog": [Color("47609c"),.0042],
		"glow": [.5,.9],
		"emission": 2.0,
		"practicals": [8,2.8,9.0],
		"rim": [Color("ffd08f"),.62],
	},
	"night_studio": {
		# Studio between takes: dim violet house light, warm stage practicals, strong glow on bulbs.
		"ambient": [Color("b4ace6"),.4],
		"glow": [.5,.95],
		"emission": 1.6,
		"rim": [Color("7ff0ff"),.62],
	},
	"rain_market": {
		# Wet night market: the market keeps its own lamps and reflections; warm rim against blue.
		"rim": [Color("ffcf8a"),.62],
	},
	"bb_office": {
		# Office afternoon: warm window light, lavender-blue shade under desks and partitions.
		"ambient": [Color("bfc3f2"),.5],
		"glow": [.3,1.05],
		"emission": 1.3,
		"rim": [Color("ffb36b"),.58],
	},
	"baggage_below": {
		# Airport hall in daylight: pale warm key through the glazing, sky-blue shade.
		"sun": [Color("fff0d0"),.5,Vector3(-40,30,0)],
		"ambient": [Color("b4cff2"),.52],
		"glow": [.3,1.05],
		"emission": 1.3,
		"rim": [Color("ffb36b"),.58],
	},
	"ginza_station": {
		# Underground platform: cool fluorescent fill, warm signage and lamps, glow on tubes.
		"ambient": [Color("d2defc"),.46],
		"glow": [.36,1.0],
		"emission": 1.4,
		"rim": [Color("ffb36b"),.6],
	},
}

static func has_palette(map_id: String) -> bool:
	return PALETTES.has(map_id)

static func emission_boost(map_id: String) -> float:
	return PALETTES.get(map_id,{}).get("emission",1.0)

## Count, energy and range of real lights placed at lamp fixtures.
static func practicals(map_id: String) -> Array:
	return PALETTES.get(map_id,{}).get("practicals",[2,1.0,5.0])

static func apply(map_id: String, env: Environment, sun: DirectionalLight3D, frenzy: bool) -> void:
	var rim: ShaderMaterial = load("res://scripts/enemy.gd").toy_rim()
	var palette: Dictionary = PALETTES.get(map_id,{})
	rim.set_shader_parameter("rim_color",palette.rim[0] if palette.has("rim") else DEFAULT_RIM)
	rim.set_shader_parameter("strength",palette.rim[1] if palette.has("rim") else DEFAULT_RIM_STRENGTH)
	if palette.is_empty() or env==null:return
	if palette.has("sun"):
		sun.light_color = palette.sun[0]
		sun.light_energy = palette.sun[1]
		sun.rotation_degrees = palette.sun[2]
	if palette.has("ambient") and not frenzy:
		env.ambient_light_color = palette.ambient[0]
		env.ambient_light_energy = palette.ambient[1]
	if palette.has("fog"):
		env.fog_enabled = true
		env.fog_light_color = palette.fog[0]
		env.fog_density = palette.fog[1]
		env.fog_light_energy = 1.0
		env.fog_sky_affect = 0.0
	if palette.has("glow"):
		env.glow_enabled = true
		env.glow_intensity = palette.glow[0]
		env.glow_hdr_threshold = palette.glow[1]
		env.glow_bloom = 0.0
