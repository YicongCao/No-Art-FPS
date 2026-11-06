shader_type spatial;
render_mode unshaded, depth_draw_never, shadows_disabled;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform int damage_level = 0;
uniform vec3 flash_color : source_color = vec3(1.0, 0.76, 0.42);
uniform vec3 chip_edge : source_color = vec3(0.93, 0.65, 0.40);
uniform vec3 chip_core : source_color = vec3(0.20, 0.10, 0.07);
varying vec3 panel_position;
varying vec3 panel_normal;

void vertex() {
	panel_position = VERTEX;
	panel_normal = NORMAL;
}

float cut(vec2 point, vec2 center, float slope, float span, float width) {
	vec2 offset = point - center;
	float taper = max(0.0, 1.0 - abs(offset.x) / span);
	float edge = abs(offset.y - slope * offset.x) - width * taper;
	return (1.0 - step(span, abs(offset.x))) * (1.0 - smoothstep(-0.002, 0.002, edge));
}

void fragment() {
	vec3 axis = abs(panel_normal);
	vec2 panel = vec2(axis.x > axis.z ? panel_position.z : panel_position.x, panel_position.y);
	float chips = 0.0;
	float cores = 0.0;
	if (axis.y < 0.8 && damage_level > 0) {
		chips = cut(panel, vec2(-0.065, -0.045), 0.55, 0.086, 0.030);
		cores = cut(panel, vec2(-0.065, -0.045), 0.55, 0.067, 0.017);
		if (damage_level > 1) {
			chips = max(chips, cut(panel, vec2(0.065, 0.045), -0.80, 0.076, 0.032));
			cores = max(cores, cut(panel, vec2(0.065, 0.045), -0.80, 0.058, 0.018));
		}
	}
	ALBEDO = mix(mix(chip_edge, chip_core, cores), flash_color, flash);
	ALPHA = max(chips * 0.96, flash * 0.72);
}
