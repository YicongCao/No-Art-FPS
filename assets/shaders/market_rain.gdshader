shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void vertex() {
	float fall = fract(TIME * .89 + INSTANCE_CUSTOM.r);
	VERTEX.y -= fall * 8.0;
	VERTEX.x += fall * .72;
}

void fragment() {
	ALBEDO = vec3(.55, .72, .95);
	ALPHA = .26 * (1.0 - abs(UV.y * 2.0 - 1.0));
}
