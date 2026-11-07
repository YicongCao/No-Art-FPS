shader_type sky;

void sky() {
	float altitude = max(EYEDIR.y, 0.0);
	vec3 color = mix(vec3(0.13, 0.23, 0.41), vec3(0.02, 0.045, 0.12), smoothstep(0.0, 0.6, altitude));
	float moon = dot(EYEDIR, normalize(vec3(0.57, 0.35, -0.83)));
	COLOR = mix(color, vec3(0.79, 0.87, 0.94), smoothstep(0.9993, 0.9996, moon));
}
