shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_add;

void fragment() {
	float width_fade = 1.0 - smoothstep(.25, .49, abs(UV.x - .5));
	float length_fade = smoothstep(0.0, .13, UV.y) * (1.0 - smoothstep(.72, 1.0, UV.y));
	ALBEDO = vec3(.95, .14, .12);
	ALPHA = width_fade * length_fade * .57;
}
