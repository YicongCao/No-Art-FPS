shader_type spatial;
render_mode unshaded, shadows_disabled;

varying vec2 water_position;

void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = water_position;
	float drift = sin(p.x * 0.31 + sin(p.y * 0.16)) * 0.63;
	float stripe = sin(p.y * 1.3 + drift - TIME * 1.05);
	float chop = smoothstep(0.59, 0.94, sin(p.x * 0.58 + p.y * 0.21) * 0.75 + sin(p.x * 0.16 + p.y * 0.27) * 0.25);
	vec3 blue = mix(vec3(0.029, 0.095, 0.21), vec3(0.055, 0.16, 0.33), smoothstep(0.0, 0.86, stripe) * chop * 0.72);

	float near_ship = 1.0 - smoothstep(1.5, 4.2, abs(abs(p.x) - 13.8));
	float wake = near_ship * smoothstep(-22.0, -9.0, p.y) * (1.0 - smoothstep(24.0, 36.0, p.y));
	wake *= smoothstep(0.67, 1.0, stripe) * (0.5 + chop * 0.5);
	blue = mix(blue, vec3(0.35, 0.55, 0.71), wake * 0.66);

	float glint = exp(-abs(p.x - 61.0) * 0.2) * smoothstep(-64.0, -56.0, p.y) * (1.0 - smoothstep(-41.0, -19.0, p.y));
	glint += exp(-abs(p.x + 48.0) * 0.085) * smoothstep(-68.0, -60.0, p.y) * (1.0 - smoothstep(-52.0, -33.0, p.y));
	ALBEDO = mix(blue, vec3(0.91, 0.57, 0.26), glint * smoothstep(0.81, 1.0, stripe) * 0.56);
}
