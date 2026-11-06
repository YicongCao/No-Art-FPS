shader_type canvas_item;

uniform vec4 background : source_color = vec4(.094, .137, .184, 1.0);
uniform vec2 viewport_size = vec2(1440.0, 810.0);
uniform float progress = 0.0;

void fragment() {
	vec2 p = (UV - .5) * viewport_size;
	float radius = length(viewport_size * .5) * progress;
	float alpha = smoothstep(radius - 30.0, radius, length(p));
	if (progress <= 0.0) { alpha = 1.0; }
	if (progress >= 1.0) { alpha = 0.0; }
	COLOR = vec4(background.rgb, alpha);
}
