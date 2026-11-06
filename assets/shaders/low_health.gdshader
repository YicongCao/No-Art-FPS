shader_type canvas_item;
uniform float severity : hint_range(0.0,1.0) = 0.0;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
void fragment() {
    vec2 centered = abs(UV * 2.0 - 1.0);
    float distance_to_center = max(centered.x, centered.y);
    float edge = pow(distance_to_center, 3.5);
    float corners = smoothstep(0.35, 1.35, length(centered));
    float low_health = severity * (edge * 0.57 + corners * 0.30);
    float impact = hit_flash * smoothstep(0.27, 1.0, distance_to_center) * 0.55;
    vec3 tint = mix(vec3(0.24, 0.005, 0.018), vec3(0.71, 0.022, 0.037), hit_flash);
    COLOR = vec4(tint, low_health + (1.0 - low_health) * impact);
}
