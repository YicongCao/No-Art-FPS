shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0,.7,.3,1.0);
uniform float strength = .3;
uniform float polish = .0;
uniform vec3 fixture_position;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float pool=pow(max(0.0,1.0-dot(p,p)),2.0);
 vec3 to_light=normalize(fixture_position-world);
 vec3 to_camera=normalize(CAMERA_POSITION_WORLD-world);
 float stripe=pow(max(dot(normalize(to_light+to_camera),vec3(0.0,1.0,0.0)),0.0),55.0)*pool;
 float fresnel=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.0);
 ALBEDO=tint.rgb;
 ALPHA=(pool+stripe*polish*(.3+fresnel))*strength*COLOR.a;
}
