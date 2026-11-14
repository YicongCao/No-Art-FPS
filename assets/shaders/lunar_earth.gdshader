shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_map : filter_linear_mipmap, repeat_enable;
uniform vec3 sun_direction = vec3(-0.486,0.530,0.695);
varying vec3 world_normal;
varying vec3 world_position;
void vertex(){
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
 vec3 n=normalize(world_normal);
 vec3 v=normalize(CAMERA_POSITION_WORLD-world_position);
 float sunlight=dot(n,normalize(sun_direction));
 float day=smoothstep(-0.10,0.25,sunlight);
 float diffuse=0.18+0.82*max(sunlight,0.0);
 vec3 land=texture(surface_map,UV).rgb;
 // Preserve geography; lift the extremely dark ocean toward the observed blue limb.
 float ocean=1.0-smoothstep(0.04,0.12,max(land.r,land.g));
 land=mix(land,vec3(0.012,0.055,0.17),ocean*.72);
 float cloud=smoothstep(.14,.85,texture(cloud_map,UV).r);
 vec3 surface=mix(land,vec3(.83,.88,.94),cloud*.91);
 float rim=pow(1.0-clamp(dot(n,v),0.0,1.0),3.8);
 vec3 atmosphere=vec3(.055,.20,.47)*rim*(.12+.88*day);
 ALBEDO=surface*(.012+day*diffuse)*1.35+atmosphere;
}
