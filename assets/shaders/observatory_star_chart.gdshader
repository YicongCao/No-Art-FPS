shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, blend_add;

void fragment() {
	vec2 point = (UV - vec2(.5)) * 2.0;
	float radius = length(point);
	float ring = 1.0 - smoothstep(.007, .019, abs(fract(radius * 3.0) - .5));
	float angle = atan(point.y, point.x + .00001);
	float axis = 1.0 - smoothstep(.014, .055, abs(sin(angle * 6.0)));
	vec2 cell = floor(point * 15.0);
	float hash = fract(sin(dot(cell, vec2(13.1, 53.4))) * 43758.54);
	float star = (1.0 - smoothstep(.09, .27, length(fract(point * 15.0) - .5))) * step(.84, hash);
	float mask = smoothstep(.20, .28, radius) * (1.0 - smoothstep(.94, 1.0, radius));
	ALBEDO = mix(vec3(.99, .28, .23), vec3(1.0, .72, .58), star);
	ALPHA = mask * max(star * .69, max(ring * .47, axis * .20));
}
