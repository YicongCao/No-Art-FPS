shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D pixel_tile : filter_nearest_mipmap, repeat_enable;
uniform vec4 profile = vec4(1.0, 0.55, 0.86, 0.0);
uniform float lamp_glow = 0.0;

varying vec3 local_point;
varying vec3 local_normal;

void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	// Metre-scaled UV projection in mesh space travels with the animated rides.
	vec3 axis = abs(local_normal);
	vec2 uv = local_point.xz;
	if (axis.x > max(axis.y, axis.z)) {
		uv = local_point.zy;
	} else if (axis.z > axis.y) {
		uv = local_point.xy;
	}
	float detail = texture(pixel_tile, uv * profile.x).r;
	ALBEDO = base_color.rgb * (1.0 + (detail - 0.5) * profile.y);
	ROUGHNESS = clamp(profile.z + (0.5 - detail) * 0.28, 0.16, 1.0);
	METALLIC = profile.w;
	SPECULAR = mix(0.76, 0.31, smoothstep(0.22, 0.91, profile.z));
	EMISSION = ALBEDO * lamp_glow;
}
