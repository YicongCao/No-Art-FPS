shader_type canvas_item;

uniform sampler2D opening_frame : source_color, filter_linear, repeat_disable;
uniform float shade_opacity = .55;
uniform vec2 viewport_size = vec2(1440.0, 810.0);
uniform float progress = 0.0;

void fragment() {
	vec2 p = (UV - .5) * viewport_size;
	float radius = length(viewport_size * .5) * progress;
	float alpha = smoothstep(radius - 30.0, radius, length(p));
	if (progress <= 0.0) { alpha = 1.0; }
	if (progress >= 1.0) { alpha = 0.0; }
	// Title and loading use the very same captured opening frame and black
	// shade. The radial alpha reveals live 3D without showing preparation work.
	vec3 scene = texture(opening_frame, UV).rgb;
	COLOR = vec4(scene * (1.0 - shade_opacity), alpha);
}
