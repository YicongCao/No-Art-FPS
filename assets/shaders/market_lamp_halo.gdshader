shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
	float radius = length(UV*2.0-1.0);
	ALBEDO = vec3(1.0,.58,.22);
	ALPHA = pow(max(0.0,1.0-radius),3.0)*.28;
}
