shader_type sky;

uniform float nightfall : hint_range(0.0, 1.0) = 0.0;

void sky() {
	vec3 horizon = mix(vec3(1.0, 0.63, 0.37), vec3(0.18, 0.22, 0.39), nightfall);
	vec3 zenith = mix(vec3(0.42, 0.43, 0.65), vec3(0.045, 0.065, 0.18), nightfall);
	vec3 ground = mix(vec3(0.59, 0.32, 0.28), vec3(0.10, 0.12, 0.23), nightfall);
	float elevation = EYEDIR.y;
	vec3 dusk = mix(horizon, zenith, smoothstep(0.0, 0.70, elevation));
	dusk = mix(dusk, ground, smoothstep(0.0, 0.46, -elevation));
	float to_sun = dot(normalize(vec3(0.55, 0.24, -0.80)), EYEDIR);
	float halo = smoothstep(0.948, 1.0, to_sun) * (1.0 - nightfall);
	float disk = smoothstep(0.9983, 0.9988, to_sun) * (1.0 - nightfall);
	COLOR = mix(mix(dusk, vec3(1.0, 0.76, 0.45), halo * 0.55), vec3(1.0, 0.91, 0.65), disk);
}
