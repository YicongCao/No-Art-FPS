shader_type spatial;
render_mode unshaded, depth_draw_never, shadows_disabled;

// Asymmetric painted-toy mecha battle damage: scorched impact crater, jagged
// armor breach with chipped primer rim, and branching molten circuit cracks.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform int damage_level = 0;
uniform vec3 flash_color : source_color = vec3(1.0, 0.82, 0.46);
uniform vec3 chip_edge : source_color = vec3(0.98, 0.88, 0.66);
uniform vec3 chip_core : source_color = vec3(0.07, 0.09, 0.13);
uniform vec3 ember_glow : source_color = vec3(1.0, 0.30, 0.08);
varying vec3 panel_position;
varying vec3 panel_normal;

void vertex() {
	panel_position = VERTEX;
	panel_normal = NORMAL;
}

float crack(vec2 p, vec2 a, vec2 b, float w_a, float w_b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	vec2 perp = normalize(vec2(-ba.y, ba.x));
	float jag = (sin(h * 25.0) * 0.005 + sin(h * 61.0) * 0.0025) * sin(h * 3.14159);
	float d = length(pa - ba * h + perp * jag);
	float w = mix(w_a, w_b, h);
	return 1.0 - smoothstep(w - 0.0025, w + 0.0025, d);
}

float crater(vec2 p, vec2 c, float r) {
	vec2 d = p - c;
	float ang = atan(d.y, d.x);
	float wobble = 1.0 + 0.18 * sin(ang * 5.0 + 1.2) + 0.11 * cos(ang * 9.0);
	return 1.0 - smoothstep(r * 0.86, r * 1.04, length(d) * wobble);
}

void fragment() {
	vec3 axis = abs(panel_normal);
	vec2 p = vec2(axis.x > axis.z ? panel_position.z : panel_position.x, panel_position.y);
	float rim = 0.0;
	float gouge = 0.0;
	float ember = 0.0;

	if (axis.y < 0.86 && damage_level > 0) {
		// Off-centre blast crater + main jagged tear toward upper-left shoulder
		vec2 hit = vec2(-0.045, 0.015);
		rim = max(rim, crater(p, hit, 0.056));
		gouge = max(gouge, crater(p, hit, 0.041));
		ember = max(ember, crater(p, hit, 0.018));

		rim = max(rim, crack(p, hit, vec2(-0.155, 0.095), 0.034, 0.006));
		gouge = max(gouge, crack(p, hit, vec2(-0.148, 0.090), 0.021, 0.003));
		ember = max(ember, crack(p, hit, vec2(-0.130, 0.078), 0.008, 0.001));

		rim = max(rim, crack(p, hit, vec2(0.085, -0.068), 0.028, 0.005));
		gouge = max(gouge, crack(p, hit, vec2(0.078, -0.063), 0.017, 0.002));
		ember = max(ember, crack(p, hit, vec2(0.064, -0.052), 0.007, 0.001));

		if (damage_level > 1) {
			// Branching lower fracture + secondary side spall gouge
			rim = max(rim, crack(p, vec2(-0.020, -0.005), vec2(-0.085, -0.105), 0.024, 0.005));
			gouge = max(gouge, crack(p, vec2(-0.020, -0.005), vec2(-0.080, -0.098), 0.015, 0.002));
			ember = max(ember, crack(p, vec2(-0.020, -0.005), vec2(-0.068, -0.082), 0.006, 0.001));

			vec2 spall = vec2(0.092, 0.052);
			rim = max(rim, crater(p, spall, 0.034));
			gouge = max(gouge, crater(p, spall, 0.023));
			ember = max(ember, crater(p, spall, 0.009));
		}
	}

	float pulse = 0.86 + 0.28 * sin(TIME * 17.0);
	vec3 scar = mix(chip_edge, chip_core, gouge);
	scar = mix(scar, ember_glow * pulse, ember);
	ALBEDO = mix(scar, flash_color, flash);
	ALPHA = max(rim * 0.98, flash * 0.82);
}
