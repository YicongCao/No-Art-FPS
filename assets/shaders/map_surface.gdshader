shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform int kind = 0; // 1 metal, 2 masonry, 3 wood, 4 textile, 5 foliage, 6 snow, 7 tile
uniform bool use_vertex_color = false;
uniform bool roof_pattern = false;
uniform float daylight = 1.0;
uniform float floor_height = 0.0;
uniform float wall_gradient = 0.14;
varying vec3 world;
varying vec3 world_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 weights=pow(abs(world_normal),vec3(6.0)); weights/=max(dot(weights,vec3(1.0)),0.001);
 float n=texture(detail_noise,world.yz*.44).r*weights.x+texture(detail_noise,world.xz*.44).r*weights.y+texture(detail_noise,world.xy*.44).r*weights.z;
 
 vec3 c=base_color.rgb;
 if(use_vertex_color){c*=COLOR.rgb;}
 float variation=0.0;
 if(kind==2){variation=.06;}
 if(kind==3){n=mix(n,texture(detail_noise,vec2(world.x+world.y,world.z)*vec2(1.7,.08)).r,.7);variation=.12;}
 if(kind==4){variation=.13;}
 if(kind==5){variation=.06;c*=mix(.90,1.06,smoothstep(-.4,.8,world_normal.y));BACKLIGHT=c*.28;}
 if(kind==6){variation=.09;c*=vec3(.62,.69,.77);}
 c*=1.0+(n-.5)*variation;
 if(kind==7){vec2 grid=abs(fract(world.xz/1.5)-.5);float seam=smoothstep(.478,.496,max(grid.x,grid.y));c*=1.0-seam*.16;}
 if(roof_pattern&&world_normal.y>.65&&length(world.xz)<9.5){vec2 grid=abs(fract((world.xz+vec2(world.y*.45,world.y*.2))/3.0)-.5);float beam=smoothstep(.42,.47,max(grid.x,grid.y));c*=mix(1.0,.69,beam*daylight);}
 if(kind==8){float wave=sin(world.z*2.0+sin(world.x*.3)+TIME*.6);c=mix(c,vec3(.24,.29,.4),.3+.12*wave);}
 float wall=1.0-abs(world_normal.y);
 c*=mix(1.0-wall_gradient*wall,1.0,smoothstep(0.0,3.2,world.y-floor_height));
 c*=mix(vec3(1.0),vec3(.90,.94,1.02),smoothstep(.3,.9,-world_normal.y));
 ALBEDO=c;
 ROUGHNESS=clamp(roughness_value+(n-.5)*.14,.12,1.0);
 METALLIC=metallic_value;
 SPECULAR=.5;
 // Detail stays subtle enough to avoid reintroducing ink-like texture edges.

}
