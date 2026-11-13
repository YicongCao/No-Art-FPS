shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Faithful painted coating: authored colour, roughness and metallic stay as the base,
// enriched with stylized miniature-diorama weathering (dry-brushed bevel chips,
// painterly pigment mottling, base splash stains, rain streaks, floor scuffs & subtle relief).
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap;
uniform bool use_vertex_color = false;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform float specular_value = 0.5;
uniform float floor_height = 0.0;
uniform float wall_gradient = 0.14;
uniform float wear_amount = 0.34;
uniform vec3 grime_tint : source_color = vec3(0.72, 0.66, 0.58);
uniform vec3 edge_tint : source_color = vec3(0.97, 0.94, 0.88);
uniform float streak_amount = 0.04;

varying vec3 world;
varying vec3 world_normal;
varying float v_luma;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_luma = use_vertex_color ? dot(COLOR.rgb, vec3(0.3333)) : 1.0;
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(6.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec2 uv_x = world.zy;
	vec2 uv_y = world.xz;
	vec2 uv_z = world.xy;

	float macro = texture(detail_noise, uv_x * 0.075).r * weights.x
	            + texture(detail_noise, uv_y * 0.075).r * weights.y
	            + texture(detail_noise, uv_z * 0.075).r * weights.z;
	float brush = texture(detail_noise, uv_x * 0.32).r * weights.x
	            + texture(detail_noise, uv_y * 0.32).r * weights.y
	            + texture(detail_noise, uv_z * 0.32).r * weights.z;
	float fine = texture(detail_noise, uv_x * 1.15).r * weights.x
	           + texture(detail_noise, uv_y * 1.15).r * weights.y
	           + texture(detail_noise, uv_z * 1.15).r * weights.z;

	vec3 color = base_color.rgb;
	if (use_vertex_color) {
		color *= COLOR.rgb;
	}

	float dist = length(world - CAMERA_POSITION_WORLD);
	float near_mask = 1.0 - smoothstep(12.0, 34.0, dist);
	float mid_mask = 1.0 - smoothstep(22.0, 56.0, dist);

	// 1. Keep broad toy colour reads clean: only whisper-soft tonal warmth, no muddy noise
	float blotch = (macro - 0.5) * 0.055 + (brush - 0.5) * 0.035;
	color *= 1.0 + blotch * wear_amount * mid_mask;
	float sun_fade = smoothstep(0.65, 0.96, world_normal.y) * smoothstep(0.48, 0.78, macro) * 0.07 * wear_amount;
	color = mix(color, mix(color, edge_tint, 0.45), sun_fade * mid_mask);

	// 2. Crisp grounding dust only right at the floor seam (no dark streaks or muddy patches)
	float wall = 1.0 - abs(world_normal.y);
	float h = max(0.0, world.y - floor_height);
	float dust_h = 0.16 + macro * 0.14;
	float base_dust = wall * (1.0 - smoothstep(0.01, dust_h, h)) * smoothstep(0.38, 0.72, brush);
	vec3 clean_dust = mix(color * 0.90, grime_tint, 0.35);
	color = mix(color, clean_dust, clamp(base_dust * 0.22 * wear_amount, 0.0, 0.18));

	// 3. Clean dry-brushed highlight on 3D bevels, chipped corners & architectural seams
	float curv = length(fwidth(world_normal)) / max(length(fwidth(world)) * 15.0, 0.028);
	float edge_chip = smoothstep(0.24, 0.70, curv) * smoothstep(0.36, 0.68, brush * 0.7 + fine * 0.3) * near_mask * wear_amount;
	vec3 primer = mix(edge_tint, color * 1.32 + vec3(0.08), 0.42);
	color = mix(color, primer, clamp(edge_chip * 0.52, 0.0, 0.34));

	// Subtle cotangent micro-relief breaks mirror-plastic flatness via specular only
	float relief = brush * 0.65 + fine * 0.35;
	vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = (dFdx(relief) * r1 + dFdy(relief) * r2) / max(abs(det), 0.00001) * sign(det);
	NORMAL = normalize(NORMAL - grad * (0.00075 * wear_amount * near_mask));

	// Sky-lit wall gradient and cool undersides
	float rise = smoothstep(0.0, 3.2, h);
	color *= mix(1.0 - wall_gradient * wall, 1.0, rise);
	color *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));

	// 4. Specular roughness variation carries surface tactility while albedo stays bright & clean
	float rough = roughness_value
	            + (macro - 0.5) * 0.12 * wear_amount
	            + (brush - 0.5) * 0.08 * wear_amount
	            + base_dust * 0.08
	            - edge_chip * 0.12;

	ALBEDO = color;
	ROUGHNESS = clamp(rough, 0.14, 0.98);
	METALLIC = metallic_value;
	SPECULAR = specular_value;
}
