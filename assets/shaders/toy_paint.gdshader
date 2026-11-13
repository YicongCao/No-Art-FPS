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
uniform float wear_amount = 0.72;
uniform vec3 grime_tint : source_color = vec3(0.42, 0.36, 0.30);
uniform vec3 edge_tint : source_color = vec3(0.97, 0.94, 0.86);
uniform float streak_amount = 0.36;

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
	float near_mask = 1.0 - smoothstep(14.0, 42.0, dist);
	float mid_mask = 1.0 - smoothstep(28.0, 72.0, dist);

	// 1. Painterly pigment mottling + sun-chalking on upward faces
	float blotch = (macro - 0.5) * 0.24 + (brush - 0.5) * 0.16;
	color *= 1.0 + blotch * wear_amount * mid_mask;
	float sun_fade = smoothstep(0.55, 0.95, world_normal.y) * smoothstep(0.42, 0.72, macro) * 0.18 * wear_amount;
	color = mix(color, mix(color, edge_tint, 0.65), sun_fade * mid_mask);

	// 2. Upward floor / deck traffic scuff marks & dust patches
	float floor_face = smoothstep(0.68, 0.95, world_normal.y);
	float traffic_patch = floor_face * smoothstep(0.46, 0.74, macro * 0.65 + brush * 0.35) * wear_amount * mid_mask;
	color = mix(color, grime_tint * (0.55 + 0.55 * base_color.rgb), traffic_patch * 0.42);

	// 3. Vertical rain / rust / soot streaks down walls & containers
	float wall = 1.0 - abs(world_normal.y);
	float drip_uv = texture(detail_noise, vec2(world.x + world.z, world.y * 0.14) * 0.46).r;
	float streaks = wall * smoothstep(0.44, 0.74, drip_uv) * streak_amount * wear_amount * mid_mask;
	color = mix(color, grime_tint * (0.48 + 0.52 * base_color.rgb), streaks * 0.58);

	// 4. Grounding base splash / kick-scuffs + baked crevice dirt accumulation
	float h = max(0.0, world.y - floor_height);
	float splash_h = 0.58 + macro * 0.52;
	float base_scuff = wall * (1.0 - smoothstep(0.03, splash_h, h)) * smoothstep(0.28, 0.64, brush);
	float ao_dirt = (1.0 - smoothstep(0.64, 0.94, v_luma)) * smoothstep(0.30, 0.66, macro) * 0.85;
	float dirt = clamp((base_scuff * 0.68 + ao_dirt * 0.50) * wear_amount, 0.0, 0.68);
	color = mix(color, grime_tint * (0.52 + 0.48 * base_color.rgb), dirt);

	// 5. Dry-brushed bevel paint chipping (catches 3D rounded edges & ribs)
	float curv = length(fwidth(world_normal)) / max(length(fwidth(world)) * 15.0, 0.028);
	float edge_chip = smoothstep(0.14, 0.58, curv) * smoothstep(0.30, 0.62, brush * 0.7 + fine * 0.3) * near_mask * wear_amount;
	vec3 primer = mix(edge_tint, color * 1.48 + vec3(0.12), 0.38);
	color = mix(color, primer, clamp(edge_chip * 0.76, 0.0, 0.68));

	// Subtle cotangent relief so painted plastic/metal catches broken specular highlights
	float relief = brush * 0.65 + fine * 0.35;
	vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = (dFdx(relief) * r1 + dFdy(relief) * r2) / max(abs(det), 0.00001) * sign(det);
	NORMAL = normalize(NORMAL - grad * (0.0014 * wear_amount * near_mask));

	// Sky-lit wall gradient and cool undersides
	float rise = smoothstep(0.0, 3.2, h);
	color *= mix(1.0 - wall_gradient * wall, 1.0, rise);
	color *= mix(vec3(1.0), vec3(0.90, 0.94, 1.02), smoothstep(0.3, 0.9, -world_normal.y));

	// 6. Tactile roughness contrast: scuffed patches go matte, rubbed bevels polish
	float rough = roughness_value
	            + (macro - 0.5) * 0.24 * wear_amount
	            + (brush - 0.5) * 0.14 * wear_amount
	            + dirt * 0.26
	            - traffic_patch * 0.14
	            - edge_chip * 0.20;

	ALBEDO = color;
	ROUGHNESS = clamp(rough, 0.14, 0.98);
	METALLIC = metallic_value;
	SPECULAR = specular_value;
}
