shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Vertex-painted articulated meshes: preserve material response and rim in one pass.
void fragment() {
    vec3 paint = COLOR.rgb;
    // glTF vertex colours are linear; Compatibility shades in sRGB.
    if (OUTPUT_IS_SRGB) {
        paint = mix(paint * 12.92, 1.055 * pow(paint, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), paint));
    }
    ALBEDO = paint;
    ROUGHNESS = clamp(UV.x, 0.16, 1.0);
    METALLIC = clamp(UV2.x, 0.0, 1.0);
    float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
    EMISSION = paint * UV2.y + vec3(0.62, 0.78, 1.0) * edge * 0.48;
}
