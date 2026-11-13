shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap;
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
uniform float wear_amount = 0.34;
uniform vec3 grime_tint : source_color = vec3(0.74, 0.68, 0.58);
uniform vec3 edge_tint : source_color = vec3(0.97, 0.94, 0.88);
uniform float streak_amount = 0.04;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

vec3 apply_paint(vec3 wall, sampler2D artwork, vec3 center, vec3 normal, vec2 size, float peel) {
	vec3 offset = world_position - center;
	vec3 right = cross(vec3(0.0, 1.0, 0.0), normal);
	vec2 paint_uv = vec2(dot(offset, right), -offset.y) / size + .5;
	if (abs(dot(offset, normal)) > .12 || dot(world_normal, normal) < .4
		|| any(lessThan(paint_uv, vec2(0.0))) || any(greaterThan(paint_uv, vec2(1.0)))) {
		return wall;
	}
	vec4 paint = texture(artwork, paint_uv);
	float weathered_alpha = paint.a * mix(1.0, 0.88 + 0.12 * peel, 0.35 * wear_amount);
	return mix(wall, paint.rgb, weathered_alpha);
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(6.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	float macro = texture(detail_noise, world_position.zy * 0.075).r * weights.x
	            + texture(detail_noise, world_position.xz * 0.075).r * weights.y
	            + texture(detail_noise, world_position.xy * 0.075).r * weights.z;
	float brush = texture(detail_noise, world_position.zy * 0.34).r * weights.x
	            + texture(detail_noise, world_position.xz * 0.34).r * weights.y
	            + texture(detail_noise, world_position.xy * 0.34).r * weights.z;

	float dist = length(world_position - CAMERA_POSITION_WORLD);
	float near_mask = 1.0 - smoothstep(12.0, 34.0, dist);
	float mid_mask = 1.0 - smoothstep(22.0, 56.0, dist);

	vec3 color = base_color.rgb;
	color *= 1.0 + ((macro - 0.5) * 0.055 + (brush - 0.5) * 0.035) * wear_amount * mid_mask;

	if (paint_count > 0) {
		color = apply_paint(color, artwork_0, paint_center_0, paint_normal_0, paint_size_0, brush);
	}
	if (paint_count > 1) {
		color = apply_paint(color, artwork_1, paint_center_1, paint_normal_1, paint_size_1, brush);
	}

	float wall = 1.0 - abs(world_normal.y);
	float h = max(0.0, world_position.y);
	float base_dust = wall * (1.0 - smoothstep(0.01, 0.18 + macro * 0.12, h)) * smoothstep(0.38, 0.72, brush);
	color = mix(color, mix(color * 0.90, grime_tint, 0.35), clamp(base_dust * 0.22 * wear_amount, 0.0, 0.18));

	float curv = length(fwidth(world_normal)) / max(length(fwidth(world_position)) * 15.0, 0.028);
	float edge_chip = smoothstep(0.24, 0.70, curv) * smoothstep(0.36, 0.68, brush) * near_mask * wear_amount;
	color = mix(color, mix(edge_tint, color * 1.32 + vec3(0.08), 0.42), clamp(edge_chip * 0.52, 0.0, 0.34));

	color *= mix(1.0 - wall_gradient * wall, 1.0, smoothstep(0.0, 3.2, h));
	color *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));
	ALBEDO = color;
	ROUGHNESS = clamp(0.54 + (macro - 0.5) * 0.12 * wear_amount + base_dust * 0.08 - edge_chip * 0.12, 0.16, 0.98);
	SPECULAR = 0.5;
}
