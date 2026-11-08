shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float elapsed = 0.0;

void fragment() {
	float along = UV.x;
	float jet_height = .21 + .68 * along * along;
	float spray_width = .026 + along * .105;
	float jet = 1.0 - smoothstep(spray_width * .55, spray_width, abs(UV.y - jet_height));
	float strands = .48 + .52 * sin(68.0 * UV.x - elapsed * 25.0 + UV.y * 37.0);
	float fade = 1.0 - smoothstep(.67, 1.0, along);
	ALBEDO = mix(vec3(.21, .58, .86), vec3(.77, .93, 1.0), strands);
	ALPHA = jet * fade * (.46 + strands * .40);
}
