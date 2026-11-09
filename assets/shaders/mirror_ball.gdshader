shader_type spatial;

uniform bool pixel_finish = false;
uniform sampler2D pixel_tile : filter_nearest_mipmap, repeat_enable;

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
	if (pixel_finish) {
		float polish = texture(pixel_tile, UV * vec2(4.0, 2.0)).r;
		ALBEDO *= mix(0.76, 1.24, polish);
		ROUGHNESS = mix(0.62, mix(0.32, 0.16, polish), seam);
		SPECULAR = mix(0.5, 0.8, seam);
	}
}
