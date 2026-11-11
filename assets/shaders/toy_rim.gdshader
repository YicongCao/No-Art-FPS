shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// Additive next pass for actor plastics: a light-independent edge that keeps dark
// bodies separated from both bright and dim backgrounds.
uniform vec3 rim_color : source_color = vec3(0.62, 0.78, 1.0);
uniform float strength = 0.48;
uniform float power = 2.6;

void fragment() {
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	ALBEDO = rim_color * edge * strength;
}
