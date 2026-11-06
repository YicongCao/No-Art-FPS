shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always;

void fragment() {
	vec2 ripple_uv = UV * vec2(9.0, 12.0);
	float ripple = sin(ripple_uv.x * 2.5 + sin(ripple_uv.y * 1.7 + TIME * .6));
	float glint = smoothstep(.93, .99, ripple) * (.5 + .5 * sin(ripple_uv.y * 2.1 - TIME * .45));
	ALBEDO = mix(vec3(.08, .62, .68), vec3(.65, .95, .91), glint * .6);
	ROUGHNESS = .45;
	SPECULAR = .25;
	ALPHA = .78;
}
