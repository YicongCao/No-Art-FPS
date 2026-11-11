shader_type sky;

// Painted gradient for maps that author a flat background colour.
uniform vec3 top_color : source_color = vec3(0.30, 0.45, 0.78);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.80, 0.92);
uniform vec3 ground_color : source_color = vec3(0.58, 0.62, 0.70);
uniform float sun_glow = 0.22;

void sky() {
	float height = EYEDIR.y;
	vec3 color = mix(horizon_color, top_color, smoothstep(0.0, 0.58, height));
	color = mix(color, ground_color, smoothstep(0.0, 0.18, -height));
	if (LIGHT0_ENABLED) {
		float toward = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		color += LIGHT0_COLOR * (pow(toward, 18.0) * sun_glow + pow(toward, 4.0) * sun_glow * 0.25);
	}
	COLOR = color;
}
