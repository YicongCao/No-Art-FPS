shader_type spatial;
render_mode cull_back;

uniform float travel = 0.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float rib = smoothstep(.89, .96, fract((local_position.z - travel) * 3.5));
	float edge = smoothstep(.05, .18, abs(NORMAL.y));
	ALBEDO = mix(vec3(.043, .052, .075), vec3(.095, .119, .156), rib * edge);
	ROUGHNESS = .72;
}
