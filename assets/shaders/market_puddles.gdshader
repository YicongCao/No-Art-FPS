shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform bool frenzy = false;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = world_position.xz;
	float ripple = sin(p.y * 24.0 + sin(p.x * 15.0) * .6) * .3;
	float edge_noise = hash(floor(p * vec2(17.0, 7.0))) * .24 + ripple * .23;
	float wet = sin(p.x * .65 + p.y * .38) + .48 * sin(p.x * 1.4 - p.y * .73) + edge_noise;
	float patch = smoothstep(.26, .68, wet);
	float break_up = .63 + .37 * hash(floor(p * vec2(8.0, 18.0)));
	float warm = exp(-pow((abs(p.x) - 4.4 + ripple) * 1.9, 2.0));
	float pink = exp(-pow((p.x - 9.5 + ripple) * 1.6, 2.0));
	float blue = exp(-pow((p.x + 2.3 + ripple) * 1.4, 2.0));
	float length_mask = .30 + .70 * smoothstep(.11, .85, cos((p.y + .4) * 1.18));
	vec3 warm_tint = vec3(.97, .57, .29);
	vec3 neon_tint = vec3(.91, .24, .56);
	vec3 tint = vec3(.31, .46, .67) + warm_tint * warm * .73;
	tint += neon_tint * pink * (frenzy ? .72 : .21);
	tint += vec3(.16, .39, .88) * blue * (frenzy ? .75 : .37);
	ALBEDO = min(tint, vec3(1.0));
	ALPHA = clamp((.20 + warm * .40 + pink * .37 + blue * .27) * patch * length_mask * break_up, 0.0, .59);
}
