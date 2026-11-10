shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float elapsed = 0.0;
uniform float beam_length = 1.0;
varying float distance_along;

void vertex() {
	distance_along = 0.5 + VERTEX.y / beam_length;
}

void fragment() {
	float fade = smoothstep(0.0, 0.018, distance_along) * (1.0 - smoothstep(0.48, 1.0, distance_along));
	float spiral = cos(TAU * (UV.x - distance_along * 18.0 + elapsed * 1.4));
	float crest = smoothstep(0.55, 0.98, spiral);
	ALBEDO = vec3(1.0, 0.34, 0.43);
	ALPHA = fade * (0.024 + 0.54 * crest);
}
