shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float density = 0.15;
uniform float shaft_length = 1.0;
varying float distance_along;

void vertex() {
	distance_along = 0.5 - VERTEX.y / shaft_length;
}

void fragment() {
	float along = smoothstep(0.0, 0.08, distance_along) * (1.0 - smoothstep(0.22, 1.0, distance_along));
	float silhouette = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.65);
	ALBEDO = tint.rgb;
	ALPHA = along * pow(silhouette, 2.0) * density * smoothstep(.3,1.4,length(VERTEX));
}
