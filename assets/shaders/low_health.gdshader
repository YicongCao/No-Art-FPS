shader_type canvas_item;
uniform float severity : hint_range(0.0,1.0) = 0.0;
void fragment() {
    vec2 centered = abs(UV * 2.0 - 1.0);
    float edge = pow(max(centered.x, centered.y), 3.5);
    float corners = smoothstep(0.35, 1.35, length(centered));
    COLOR = vec4(0.24, 0.005, 0.018, severity * (edge * 0.57 + corners * 0.30));
}
