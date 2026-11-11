shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, depth_test_disabled;

uniform vec4 rim_color : source_color = vec4(1.0, .76, .24, 1.0);
uniform float pulse = 1.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.6);
	ALBEDO = rim_color.rgb * (.25 + rim * 1.4) * pulse;
}
