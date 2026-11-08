shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D crystal : source_color, filter_linear_mipmap, repeat_disable;
uniform float elapsed = 0.0;
uniform vec3 arena_origin;
uniform vec2 dome_center;
varying float visibility;

float shelter(vec3 p) {
	// The drum, south entrance awning and east instrument-door canopy.
	float radius = length(p.xz - dome_center);
	float dome_roof = 4.65 + 8.55 * sqrt(max(0.0, 1.0 - pow(radius / 11.55, 2.0)));
	if (radius < 11.7 && p.y < dome_roof + 0.12) {
		return 0.0;
	}
	if (abs(p.x) < 2.05 && p.z > 8.52 && p.z < 10.52 && p.y < 3.37) {
		return 0.0;
	}
	if (p.x > 11.20 && p.x < 14.30 && p.z > -4.75 && p.z < -0.53 && p.y < 4.71) {
		return 0.0;
	}
	return 1.0;
}

void vertex() {
	vec4 seed = INSTANCE_CUSTOM;
	float fall = fract(seed.x + elapsed * mix(0.046, 0.096, seed.y));
	float gust = sin(elapsed * 0.7 + seed.z * TAU + fall * 4.0);
	vec3 center = MODEL_MATRIX[3].xyz + vec3(fall * 2.6 + gust * 0.37, 15.0 * (1.0 - fall), gust * 0.6 - fall);
	vec3 local_center = center - arena_origin;
	vec3 view = (VIEW_MATRIX * vec4(center, 1.0)).xyz;
	float depth = -view.z;
	float snow_line = local_center.x > 11.1 && local_center.x < 21.1
			&& local_center.z > -6.75 && local_center.z < 0.65 ? 2.38 : 0.0;
	visibility = smoothstep(0.58, 1.17, depth) * (1.0 - smoothstep(35.0, 54.0, depth));
	visibility *= smoothstep(snow_line + 0.12, snow_line + 0.80, local_center.y) * smoothstep(0.0, 0.08, fall);
	visibility *= shelter(local_center) * mix(0.60, 0.99, seed.w);

	float turn = seed.z * TAU + elapsed * mix(-1.4, 1.4, seed.y);
	float tilt = 0.75 + 0.25 * sin(turn + seed.x * TAU);
	float size = mix(0.11, 0.29, seed.w * seed.w);
	vec2 offset = vec2(VERTEX.x * tilt, VERTEX.y) * size;
	mat2 roll = mat2(vec2(cos(turn), sin(turn)), vec2(-sin(turn), cos(turn)));
	VERTEX = view + vec3(roll * offset * step(0.001, visibility), 0.0);
}

void fragment() {
	vec4 texel = texture(crystal, UV);
	ALBEDO = texel.rgb;
	ALPHA = texel.a * visibility;
}
