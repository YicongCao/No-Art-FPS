shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform sampler2D crest : source_color, repeat_disable, filter_linear_mipmap;
uniform float breeze = 0.0;
varying vec2 cloth_uv;

void vertex() {
	cloth_uv = vec2(VERTEX.x/1.86, -VERTEX.y/2.42);
	float free_end = pow(cloth_uv.x, 1.4);
	VERTEX.z += sin(cloth_uv.x*9.0-cloth_uv.y*4.0+breeze)*.22*free_end;
	VERTEX.y += sin(cloth_uv.x*5.0+breeze*1.2)*.15*free_end;
}

void fragment() {
	vec3 color = texture(crest, cloth_uv).rgb;
	float folds = .82 + .18*cos(cloth_uv.x*9.0-cloth_uv.y*4.0+breeze);
	ALBEDO = color * folds;
	ROUGHNESS = .94;
}
