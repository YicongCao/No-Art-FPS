shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D pixel_tile : filter_nearest_mipmap, repeat_enable;
uniform float repeats_per_metre = 1.0;
uniform float texture_strength = 0.55;
uniform float surface_roughness = 0.86;

void fragment() {
	float detail = texture(pixel_tile, UV * repeats_per_metre).r;
	ALBEDO = base_color.rgb * (1.0 + (detail - 0.5) * texture_strength);
	ROUGHNESS = surface_roughness;
}
