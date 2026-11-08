shader_type spatial;

void fragment() {
	vec2 grid = UV * vec2(28.0, 14.0);
	vec2 tile = floor(grid);
	vec2 edge = abs(fract(grid) - 0.5);
	float seam = 1.0 - smoothstep(0.42, 0.49, max(edge.x, edge.y));
	float facet = fract(sin(dot(tile, vec2(17.13, 75.37))) * 43758.54);
	vec3 silver = mix(vec3(0.30, 0.31, 0.53), vec3(0.93, 0.83, 0.83), facet);
	ALBEDO = mix(vec3(0.12, 0.10, 0.23), silver, seam);
	ROUGHNESS = mix(0.62, 0.24, seam);
	METALLIC = seam * 0.65;
	EMISSION = silver * seam * pow(facet, 4.0) * 0.42;
}
