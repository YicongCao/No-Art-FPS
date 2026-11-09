shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float elapsed = 0.0;
varying vec2 water_point;

void vertex() {
	water_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float depth = smoothstep(25.0, 125.0, water_point.y);
	vec2 p = water_point;
	float waves = sin(p.y * 1.8 + sin(p.x * 0.23 + elapsed * 0.32) - elapsed * 0.74);
	float gaps = sin(p.x * 0.56 - p.y * 0.26 + elapsed * 0.24);
	float crests = smoothstep(0.71, 0.97, waves) * smoothstep(0.03, 0.86, gaps);
	float silver = crests * (1.0 - depth * 0.85);
	ALBEDO = mix(vec3(0.044, 0.099, 0.173), vec3(0.14, 0.21, 0.34), depth)
		+ vec3(0.049, 0.102, 0.151) * silver;
}
