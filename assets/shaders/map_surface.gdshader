shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform int kind = 0; // 1 metal, 2 masonry, 3 wood, 4 textile, 5 foliage, 6 snow, 7 tile, 8 lake
uniform bool use_vertex_color = false;
uniform bool roof_pattern = false;
uniform float daylight = 1.0;
uniform float floor_height = 0.0;
uniform float wall_gradient = 0.14;
uniform float wear_amount = 0.72;
uniform vec3 grime_tint : source_color = vec3(0.42, 0.36, 0.30);
uniform vec3 edge_tint : source_color = vec3(0.97, 0.94, 0.86);
uniform float streak_amount = 0.36;

varying vec3 world;
varying vec3 world_normal;
varying float v_luma;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_luma = use_vertex_color ? dot(COLOR.rgb, vec3(0.3333)) : 1.0;
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(6.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	float macro = texture(detail_noise, world.yz * 0.072).r * weights.x
	            + texture(detail_noise, world.xz * 0.072).r * weights.y
	            + texture(detail_noise, world.xy * 0.072).r * weights.z;
	float n = texture(detail_noise, world.yz * 0.42).r * weights.x
	        + texture(detail_noise, world.xz * 0.42).r * weights.y
	        + texture(detail_noise, world.xy * 0.42).r * weights.z;
	float fine = texture(detail_noise, world.yz * 1.35).r * weights.x
	           + texture(detail_noise, world.xz * 1.35).r * weights.y
	           + texture(detail_noise, world.xy * 1.35).r * weights.z;

	vec3 c = base_color.rgb;
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}

	float dist = length(world - CAMERA_POSITION_WORLD);
	float near_mask = 1.0 - smoothstep(14.0, 42.0, dist);
	float mid_mask = 1.0 - smoothstep(28.0, 72.0, dist);

	// Material-specific painterly mottling & grain
	float variation = 0.0;
	float macro_var = 0.0;
	if (kind == 1) { variation = 0.16; macro_var = 0.22; }
	else if (kind == 2) { variation = 0.20; macro_var = 0.26; }
	else if (kind == 3) {
		float plank = texture(detail_noise, vec2(world.x * 2.1 + world.y * 0.6, world.z * 0.12)).r;
		n = mix(n, plank, 0.76);
		variation = 0.28;
		macro_var = 0.22;
	}
	else if (kind == 4) { variation = 0.18; macro_var = 0.16; }
	else if (kind == 5) {
		// Lawn & foliage: natural sun-bleached patches & worn turf paths
		variation = 0.10;
		macro_var = 0.16;
		c *= mix(0.88, 1.08, smoothstep(-0.4, 0.8, world_normal.y));
		float worn_turf = smoothstep(0.75, 0.98, world_normal.y) * smoothstep(0.54, 0.80, macro) * 0.28 * wear_amount;
		c = mix(c, grime_tint * 1.15, worn_turf * mid_mask);
		BACKLIGHT = c * 0.28;
	}
	else if (kind == 6) {
		variation = 0.11;
		macro_var = 0.12;
		c *= vec3(0.62, 0.69, 0.77);
	}
	else if (kind == 7) { variation = 0.14; macro_var = 0.20; }

	c *= 1.0 + (n - 0.5) * variation * mid_mask + (macro - 0.5) * macro_var * wear_amount * mid_mask;

	// Tile joints & worn grout on tiled floors (kind 7)
	if (kind == 7) {
		vec2 grid = abs(fract(world.xz / 1.5) - 0.5);
		float seam = smoothstep(0.470, 0.496, max(grid.x, grid.y));
		c = mix(c, grime_tint * 0.85, seam * 0.48 * mid_mask);
	}
	// Subtle worn carpet footpath variation on indoor floors (kind 4)
	if (kind == 4 && world_normal.y > 0.7) {
		float tread = smoothstep(0.45, 0.76, macro * 0.7 + n * 0.3) * wear_amount * mid_mask;
		c = mix(c, grime_tint * (0.65 + 0.45 * base_color.rgb), tread * 0.28);
	}
	if (roof_pattern && world_normal.y > 0.65 && length(world.xz) < 9.5) {
		vec2 grid = abs(fract((world.xz + vec2(world.y * 0.45, world.y * 0.2)) / 3.0) - 0.5);
		float beam = smoothstep(0.42, 0.47, max(grid.x, grid.y));
		c *= mix(1.0, 0.69, beam * daylight);
	}
	if (kind == 8) {
		float wave = sin(world.z * 2.0 + sin(world.x * 0.3) + TIME * 0.6);
		c = mix(c, vec3(0.24, 0.29, 0.4), 0.3 + 0.12 * wave);
	}

	float h = max(0.0, world.y - floor_height);
	float wall = 1.0 - abs(world_normal.y);
	float rough = roughness_value + (n - 0.5) * 0.22 + (macro - 0.5) * 0.18 * wear_amount;
	float metal = metallic_value;

	// Hard architectural & prop surfaces (metal, masonry, wood, tile)
	if (kind == 1 || kind == 2 || kind == 3 || kind == 7) {
		// 1. Vertical rain / rust / moss / soot streaks down walls
		float drip = texture(detail_noise, vec2(world.x + world.z, world.y * 0.14) * 0.45).r;
		float streaks = wall * smoothstep(0.42, 0.74, drip) * streak_amount * wear_amount * mid_mask;
		c = mix(c, grime_tint * (0.45 + 0.52 * base_color.rgb), streaks * 0.64);

		// 2. Grounding base splash / moss / dust + baked crevice grime + road/deck traffic scuffs
		float splash_h = (kind == 2 ? 0.68 : 0.48) + macro * 0.52;
		float base_stain = wall * (1.0 - smoothstep(0.03, splash_h, h)) * smoothstep(0.26, 0.64, n);
		float ao_stain = (1.0 - smoothstep(0.64, 0.94, v_luma)) * smoothstep(0.30, 0.68, macro) * 0.90;
		float floor_scuff = smoothstep(0.7, 0.95, world_normal.y) * smoothstep(0.42, 0.72, macro * 0.65 + n * 0.35) * 0.55;
		float dirt = clamp((base_stain * 0.68 + ao_stain * 0.52 + floor_scuff * 0.58) * wear_amount, 0.0, 0.72);
		c = mix(c, grime_tint * (0.50 + 0.50 * base_color.rgb), dirt);
		rough += dirt * 0.24 - floor_scuff * 0.18 * wear_amount;

		// 3. Dry-brushed bevel wear: bright silver steel on metal, sun-bleached chalk/splinter on stone & wood
		float curv = length(fwidth(world_normal)) / max(length(fwidth(world)) * 15.0, 0.028);
		float edge_wear = smoothstep(0.14, 0.58, curv) * smoothstep(0.28, 0.62, n * 0.7 + fine * 0.3) * near_mask * wear_amount;
		vec3 worn_edge = kind == 1 ? mix(edge_tint, vec3(0.88, 0.92, 0.96), 0.70) : mix(edge_tint, c * 1.48 + vec3(0.11), 0.40);
		c = mix(c, worn_edge, clamp(edge_wear * (kind == 1 ? 0.80 : 0.68), 0.0, 0.68));
		if (kind == 1) {
			metal = clamp(metal + edge_wear * 0.28 - dirt * 0.32, 0.0, 0.96);
			rough -= edge_wear * 0.20;
		} else {
			rough += edge_wear * 0.08;
		}

		// 4. Subtle cotangent relief so wood planks, masonry & metal catch broken specular highlights
		float relief = n * 0.65 + fine * 0.35;
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
		float det = dot(dpdx, r1);
		vec3 grad = (dFdx(relief) * r1 + dFdy(relief) * r2) / max(abs(det), 0.00001) * sign(det);
		float bump_scale = (kind == 3 ? 0.0022 : (kind == 2 ? 0.0018 : 0.0013)) * wear_amount * near_mask;
		NORMAL = normalize(NORMAL - grad * bump_scale);
	}

	c *= mix(1.0 - wall_gradient * wall, 1.0, smoothstep(0.0, 3.2, h));
	c *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));

	ALBEDO = c;
	ROUGHNESS = clamp(rough, 0.12, 0.98);
	METALLIC = metal;
	SPECULAR = 0.5;
}
