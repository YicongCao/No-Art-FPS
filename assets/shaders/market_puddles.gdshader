shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform bool frenzy = false;
uniform float ripple_phase = 0.0;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float near_row(float along, float gap, float offset) {
	return abs(mod(along - offset + gap * 0.5, gap) - gap * 0.5);
}

void fragment() {
	vec2 p = world_position.xz;
	float ripples = sin(p.y * 24.0 + sin(p.x * 12.0) + ripple_phase);
	float breakup = sin(p.y * 35.0 + sin(p.x * 19.0) * 2.1 - ripple_phase * 0.5);
	float wet = sin(p.x * 0.68 + p.y * 0.37) + 0.44 * sin(p.x * 1.36 - p.y * 0.73);
	float puddle = smoothstep(-0.72, 0.38, wet + ripples * 0.18);
	vec3 eye = normalize(world_position - CAMERA_POSITION_WORLD);
	vec3 ray = reflect(eye, world_normal);
	vec2 reflected = p + ray.xz / max(dot(ray, world_normal), 0.085) * 3.7;
	reflected.x += ripples * 0.13 + breakup * 0.055;
	float lane = smoothstep(18.1, 19.0, abs(p.x));
	float middle = (1.0 - lane) * (1.0 - smoothstep(16.5, 18.1, abs(reflected.y)));
	float tube = exp(-abs(reflected.x) * 1.65 - near_row(reflected.y, 5.0, 0.0) * 0.62) * middle;
	float pendant = exp(-abs(abs(reflected.x) - 6.2) * 1.43 - near_row(reflected.y, 4.1, 0.8) * 0.71) * middle;
	float sconce = exp(-abs(abs(reflected.x) - 23.0) * 0.75 - near_row(reflected.y, 6.0, 1.0) * 0.78) * lane;
	float canopy = exp(-abs(abs(reflected.x) - 3.8) * 0.19) * middle;
	float neon = exp(-abs(abs(reflected.x) - 9.6) * 1.5 - near_row(reflected.y, 9.0, 2.0) * 0.55);
	float seafood_sign = exp(-abs(reflected.x + 21.75) * 1.28 - abs(reflected.y - 11.2) * 0.37);
	float ice_sign = exp(-abs(reflected.x - 20.42) * 1.08 - abs(reflected.y - 8.0) * 0.44);
	float glancing = 0.60 + 0.40 * pow(1.0 - max(dot(-eye, world_normal), 0.0), 2.1);
	float bands = 0.76 + breakup * 0.19 + ripples * 0.05;
	vec3 tint = vec3(0.26, 0.40, 0.64) + vec3(0.0, 0.07, 0.16) * canopy;
	tint = mix(tint, vec3(1.0, 0.72, 0.31), clamp(tube * 1.75 + sconce * 1.45, 0.0, 1.0));
	tint = mix(tint, vec3(1.0, 0.31, 0.33), clamp(pendant * 1.65, 0.0, 1.0));
	tint = mix(tint, vec3(1.0, 0.27, 0.27), seafood_sign * 0.68);
	tint = mix(tint, vec3(0.34, 0.96, 0.72), ice_sign * 0.62);
	if (frenzy) {
		vec3 neon_tint = reflected.x > 0.0 ? vec3(1.0, 0.24, 0.61) : vec3(0.16, 0.65, 1.0);
		tint = mix(tint, neon_tint, clamp(neon * 1.5, 0.0, 1.0));
	}
	ALBEDO = tint;
	float highlights = tube * 1.63 + pendant * 1.03 + sconce * 1.35
		+ seafood_sign * 0.41 + ice_sign * 0.36 + (frenzy ? neon * 0.62 : 0.0);
	ALPHA = min((0.09 + canopy * 0.14 + highlights) * glancing * bands * mix(0.40, 1.0, puddle), 0.78);
}
