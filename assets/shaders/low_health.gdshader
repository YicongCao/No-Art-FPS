shader_type canvas_item;
uniform float severity : hint_range(0.0,1.0) = 0.0;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
void fragment() {
    vec2 centered = abs(UV * 2.0 - 1.0);
    float distance_to_center = max(centered.x, centered.y);
    float inner_edge = mix(0.90, 0.39, severity);
    float edge = smoothstep(inner_edge, 1.0, distance_to_center);
    float low_health = edge * pow(severity, 0.75) * 0.88;
    float impact = hit_flash * smoothstep(0.64, 1.0, distance_to_center) * 0.62;
    vec3 tint = mix(vec3(0.31, 0.007, 0.021), vec3(0.77, 0.025, 0.045), hit_flash);
    COLOR = vec4(tint, low_health + (1.0 - low_health) * impact);
}
