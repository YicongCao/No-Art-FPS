shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float ripple = 0.0;
uniform float frenzy : hint_range(0.0, 1.0) = 0.0;
varying vec2 water_point;

void vertex() {
	water_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz;
}

void fragment() {
	vec2 p = water_point;
	float bands = sin(p.y*1.45+sin(p.x*.25)-ripple);
	float chop = smoothstep(.32,.94,sin(p.x*.43+p.y*.12+ripple*.25));
	float sheen = smoothstep(.59,.96,bands)*chop;
	float dusk = exp(-abs(p.x+63.0)*.036) * .68;
	vec3 deep = mix(vec3(.062,.096,.22),vec3(.10,.07,.24),frenzy);
	vec3 glint = mix(vec3(.32,.24,.44),vec3(.43,.24,.58),frenzy);
	ALBEDO = mix(deep, glint, sheen*(.31+dusk));
}
