shader_type spatial;
render_mode cull_back;

uniform float travel = 0.0;
varying vec3 local_position;
varying float upward_face;

void vertex() {
	local_position = VERTEX;
	upward_face = step(.7, NORMAL.y);
}

void fragment() {
	float rib = smoothstep(.89, .96, fract((local_position.z - travel) * 3.5));
	ALBEDO = mix(vec3(.043, .052, .075), vec3(.095, .119, .156), rib * upward_face);
	ROUGHNESS = .72;
}
