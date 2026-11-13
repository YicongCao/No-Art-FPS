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
uniform float wear_amount = 0.34;
uniform vec3 grime_tint : source_color = vec3(0.72, 0.66, 0.58);
uniform vec3 edge_tint : source_color = vec3(0.97, 0.94, 0.88);
uniform float streak_amount = 0.04;

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
	float near_mask = 1.0 - smoothstep(12.0, 34.0, dist);
	float mid_mask = 1.0 - smoothstep(22.0, 56.0, dist);

	// Clean material grain: readable wood planks & subtle stone warmth without muddy blotches
	float variation = 0.0;
	float macro_var = 0.0;
	if (kind == 1) { variation = 0.05; macro_var = 0.06; }
	else if (kind == 2) { variation = 0.07; macro_var = 0.08; }
	else if (kind == 3) {
		float plank = texture(detail_noise, vec2(world.x * 2.1 + world.y * 0.6, world.z * 0.12)).r;
		n = mix(n, plank, 0.74);
		variation = 0.16;
		macro_var = 0.07;
	}
	else if (kind == 4) { variation = 0.07; macro_var = 0.05; }
	else if (kind == 5) {
		variation = 0.06;
		macro_var = 0.06;
		c *= mix(0.88, 1.08, smoothstep(-0.4, 0.8, world_normal.y));
		BACKLIGHT = c * 0.28;
	}
	else if (kind == 6) {
		variation = 0.06;
		macro_var = 0.05;
		c *= vec3(0.62, 0.69, 0.77);
	}
	else if (kind == 7) { variation = 0.04; macro_var = 0.05; }

	c *= 1.0 + (n - 0.5) * variation * mid_mask + (macro - 0.5) * macro_var * wear_amount * mid_mask;

	// Crisp, clean tile joints on tiled floors (kind 7)
	if (kind == 7) {
		vec2 grid = abs(fract(world.xz / 1.5) - 0.5);
		float seam = smoothstep(0.476, 0.497, max(grid.x, grid.y));
		c *= mix(1.0, 0.90, seam * mid_mask);
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
	float rough = roughness_value + (n - 0.5) * 0.12 + (macro - 0.5) * 0.10 * wear_amount;
	float metal = metallic_value;

	// Hard architectural & prop surfaces: clean edge highlights & subtle foot-seam dust only
	if (kind == 1 || kind == 2 || kind == 3 || kind == 7) {
		if ((kind == 2 || kind == 3) && streak_amount > 0.01) {
			float drip = texture(detail_noise, vec2(world.x + world.z, world.y * 0.14) * 0.45).r;
			float weather_wash = wall * smoothstep(0.52, 0.82, drip) * streak_amount * wear_amount * mid_mask;
			c *= 1.0 - weather_wash * 0.08;
		}

		float dust_h = (kind == 2 ? 0.22 : 0.15) + macro * 0.14;
		float base_dust = wall * (1.0 - smoothstep(0.01, dust_h, h)) * smoothstep(0.38, 0.72, n);
		vec3 clean_dust = mix(c * 0.90, grime_tint, 0.35);
		c = mix(c, clean_dust, clamp(base_dust * 0.24 * wear_amount, 0.0, 0.18));
		rough += base_dust * 0.10 * wear_amount;

		// Crisp dry-brushed bevel & chipped-stone highlights
		float curv = length(fwidth(world_normal)) / max(length(fwidth(world)) * 15.0, 0.028);
		float edge_wear = smoothstep(0.24, 0.70, curv) * smoothstep(0.34, 0.66, n * 0.7 + fine * 0.3) * near_mask * wear_amount;
		vec3 worn_edge = kind == 1 ? mix(edge_tint, vec3(0.90, 0.93, 0.97), 0.65) : mix(edge_tint, c * 1.32 + vec3(0.08), 0.42);
		c = mix(c, worn_edge, clamp(edge_wear * (kind == 1 ? 0.58 : 0.48), 0.0, 0.38));
		if (kind == 1) {
			metal = clamp(metal + edge_wear * 0.18, 0.0, 0.94);
			rough -= edge_wear * 0.12;
		} else {
			rough += edge_wear * 0.05;
		}

		// Subtle specular-only micro-relief
		float relief = n * 0.65 + fine * 0.35;
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
		float det = dot(dpdx, r1);
		vec3 grad = (dFdx(relief) * r1 + dFdy(relief) * r2) / max(abs(det), 0.00001) * sign(det);
		float bump_scale = (kind == 3 ? 0.0013 : (kind == 2 ? 0.0010 : 0.0007)) * wear_amount * near_mask;
		NORMAL = normalize(NORMAL - grad * bump_scale);
	}

	c *= mix(1.0 - wall_gradient * wall, 1.0, smoothstep(0.0, 3.2, h));
	c *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));

	ALBEDO = c;
	ROUGHNESS = clamp(rough, 0.12, 0.98);
	METALLIC = metal;
	SPECULAR = 0.5;
}
