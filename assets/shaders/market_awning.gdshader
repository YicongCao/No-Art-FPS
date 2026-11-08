shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform float wind_phase = 0.0;
varying float fold_shade;

void vertex() {
	float drop = UV.y;
	float flex = drop * drop;
	float phase = wind_phase + MODEL_MATRIX[3].z * 0.39 + MODEL_MATRIX[3].x * 0.22;
	float wave = sin(UV.x * 14.0 - phase) + 0.37 * sin(UV.x * 26.0 - phase * 1.5);
	VERTEX.z += flex * (0.19 + wave * 0.15 + 0.12 * sin(phase * 0.5));
	VERTEX.y += flex * (0.07 + 0.08 * sin(UV.x * 12.0 - phase));
	VERTEX.x += flex * 0.042 * sin(phase - UV.x * 7.0);
	fold_shade = 0.88 + 0.18 * cos(UV.x * 14.0 - phase) * drop;
}

void fragment() {
	float stripe = mod(floor(UV.x * 11.0), 4.0);
	vec3 cloth = vec3(0.81, 0.76, 0.72);
	if (stripe == 0.0) {
		cloth = vec3(0.65, 0.052, 0.10);
	} else if (stripe == 2.0) {
		cloth = vec3(0.042, 0.16, 0.57);
	}
	float hem = 1.0 - smoothstep(0.94, 0.97, UV.y) * 0.22;
	ALBEDO = cloth * fold_shade * hem;
	ROUGHNESS = 0.93;
}
