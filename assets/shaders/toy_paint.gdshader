shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Faithful painted coating: authored colour, roughness and metallic are unchanged.
// Walls darken slightly toward their base and undersides cool, like painted toys
// under a sky; upward faces keep the exact authored colour.
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform float specular_value = 0.5;
uniform float floor_height = 0.0;
uniform float wall_gradient = 0.14;
varying vec3 world;
varying vec3 world_normal;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 color = base_color.rgb;
	if (use_vertex_color) {
		color *= COLOR.rgb;
	}
	float wall = 1.0 - abs(world_normal.y);
	float rise = smoothstep(0.0, 3.2, world.y - floor_height);
	color *= mix(1.0 - wall_gradient * wall, 1.0, rise);
	color *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));
	ALBEDO = color;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	SPECULAR = specular_value;
}
