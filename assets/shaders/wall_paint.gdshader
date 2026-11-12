shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
uniform int paint_count = 0;
uniform sampler2D artwork_0 : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D artwork_1 : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 paint_center_0;
uniform vec3 paint_center_1;
uniform vec3 paint_normal_0 = vec3(0.0, 0.0, 1.0);
uniform vec3 paint_normal_1 = vec3(0.0, 0.0, 1.0);
uniform vec2 paint_size_0 = vec2(1.0);
uniform vec2 paint_size_1 = vec2(1.0);
uniform float wall_gradient = 0.14;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

vec3 apply_paint(vec3 wall, sampler2D artwork, vec3 center, vec3 normal, vec2 size) {
	vec3 offset = world_position - center;
	vec3 right = cross(vec3(0.0, 1.0, 0.0), normal);
	vec2 paint_uv = vec2(dot(offset, right), -offset.y) / size + .5;
	if (abs(dot(offset, normal)) > .12 || dot(world_normal, normal) < .4
		|| any(lessThan(paint_uv, vec2(0.0))) || any(greaterThan(paint_uv, vec2(1.0)))) {
		return wall;
	}
	vec4 paint = texture(artwork, paint_uv);
	return mix(wall, paint.rgb, paint.a);
}

void fragment() {
	// Paint and wall share one opaque surface and one depth value. No overlay,
	// vertex offset or transparent pass can compete with the wall or its ribs.
	vec3 color = base_color.rgb;
	if (paint_count > 0) {
		color = apply_paint(color, artwork_0, paint_center_0, paint_normal_0, paint_size_0);
	}
	if (paint_count > 1) {
		color = apply_paint(color, artwork_1, paint_center_1, paint_normal_1, paint_size_1);
	}
	float wall = 1.0 - abs(world_normal.y);
	color *= mix(1.0 - wall_gradient * wall, 1.0, smoothstep(0.0, 3.2, world_position.y));
	color *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));
	ALBEDO = color;
	ROUGHNESS = 0.54;
	SPECULAR = 0.5;
}
