shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void fragment() {
	float spread = mix(0.49, 0.11, UV.x);
	float edge = 1.0 - smoothstep(spread * 0.26, spread, abs(UV.y - 0.5));
	ALBEDO = vec3(1.0, 0.76, 0.38);
	ALPHA = edge * pow(UV.x, 1.75) * (0.49 + 0.07 * sin(TIME * 0.8));
}
