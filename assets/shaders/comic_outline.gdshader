shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform float width_pixels : hint_range(0.5, 3.0) = 1.15;
uniform float color_edge_strength = 0.7;
uniform float ink_strength = 0.88;
uniform vec3 ink : source_color = vec3(0.075, 0.10, 0.14);

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
    float raw = texture(scene_depth, uv).r;
    #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
        vec3 ndc = vec3(uv, raw) * 2.0 - 1.0;
    #else
        vec3 ndc = vec3(uv * 2.0 - 1.0, raw);
    #endif
    vec4 view = inv_projection * vec4(ndc, 1.0);
    return max(0.01, -view.z / view.w);
}

void fragment() {
    vec2 pixel = width_pixels / VIEWPORT_SIZE;
    vec3 base = texture(scene_color, SCREEN_UV).rgb;
    float center_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float geometry_edge = 0.0;
    float color_edge = 0.0;
    for (int i = 0; i < 4; i++) {
        vec2 direction = vec2(0.0);
        if (i == 0) direction.x = 1.0;
        if (i == 1) direction.x = -1.0;
        if (i == 2) direction.y = 1.0;
        if (i == 3) direction.y = -1.0;
        vec2 uv = clamp(SCREEN_UV + direction * pixel, vec2(0.001), vec2(0.999));
        float adjacent = linear_depth(uv, INV_PROJECTION_MATRIX);
        geometry_edge = max(geometry_edge, abs(center_depth-adjacent) / max(0.25,min(center_depth,adjacent)));
        color_edge = max(color_edge, length(base-texture(scene_color,uv).rgb));
    }
    float edge = max(smoothstep(0.035,0.11,geometry_edge),smoothstep(0.22,0.42,color_edge)*color_edge_strength);
    ALBEDO = mix(base,ink,edge*ink_strength);
    ALPHA = 1.0;
}
