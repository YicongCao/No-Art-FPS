shader_type spatial;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
varying float along_fish;

void vertex() {
	along_fish = clamp((VERTEX.x + 1.0) * 0.5, 0.0, 1.0);
}

void fragment() {
	float front = mix(-0.09, 1.16, progress);
	float on = 1.0 - smoothstep(front - 0.085, front + 0.01, along_fish);
	float flare = max(0.0, 1.0 - abs(along_fish - front) * 14.0);
	ALBEDO = mix(vec3(0.12, 0.26, 0.24), vec3(0.34, 0.91, 0.66), on);
	ALBEDO += flare * vec3(0.13, 0.10, 0.14);
}
