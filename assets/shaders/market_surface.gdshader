shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.3,0.5,0.6,1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap_anisotropic;
uniform float base_roughness = 0.8;
uniform float base_metallic = 0.0;
uniform int surface_kind = 0; // paint, metal, masonry, fabric
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 w = abs(world_normal);
	vec2 uv = world_position.xz;
	if (w.x > w.y && w.x > w.z) uv = world_position.zy;
	else if (w.z > w.y) uv = world_position.xy;
	float macro = texture(detail_noise,uv*0.035).r;
	float grain = texture(detail_noise,uv*0.65).r;
	float fine = texture(detail_noise,uv*3.0).r;
	float relief = grain*0.65+fine*0.35;
	vec3 paint = base_color.rgb;
	float contrast = surface_kind==2 ? 0.32 : 0.13;
	paint *= 1.0+(macro-.5)*contrast+(grain-.5)*0.14;
	float roughness = clamp(base_roughness+(macro-.5)*.18,0.14,1.0);
	float ground_y = clamp((18.0-world_position.z)*3.7/36.0,0.0,3.7);
	float height = max(0.0,world_position.y-ground_y);
	if(surface_kind==0) {
		float wear = (1.0-smoothstep(.04,.24,height))*smoothstep(.44,.7,grain)*.28;
		paint = mix(paint,vec3(.42,.36,.24),wear);
	}
	if(surface_kind==2 && world_normal.y>.7) {
		float damp = smoothstep(.38,.65,macro);
		paint *= mix(1.0,.77,damp);
		roughness = mix(roughness,.39,damp);
	}
	if(surface_kind==3) {
		float weave = texture(detail_noise,uv*6.0).r;
		paint *= .96+weave*.08;
		roughness = .92;
	}
	// Cotangent perturbation follows world-projected detail without relying on imported UVs.
	vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy,NORMAL), r2 = cross(NORMAL,dpdx);
	float det = dot(dpdx,r1);
	vec3 gradient = (dFdx(relief)*r1+dFdy(relief)*r2)/max(abs(det),.00001)*sign(det);
	NORMAL = normalize(NORMAL-gradient*(surface_kind==2 ? .004 : .0018));
	// Local diffuse bounce from the fixed rows of practical fixtures. Geometry and direct lights remain dynamic.
	float row = clamp(round(world_position.z/5.0)*5.0,-15.0,15.0);
	vec3 lamp = vec3(0.0,(18.0-row)*3.7/36.0+3.64,row);
	vec3 to_lamp = lamp-world_position;
	float center_pool = pow(max(0.0,1.0-length(to_lamp)/6.0),2.0)*max(dot(world_normal,normalize(to_lamp)),0.0);
	float side_row = clamp(round((world_position.z-1.0)/4.1)*4.1+1.0,-12.0,16.0);
	vec3 side_lamp = vec3(sign(world_position.x)*6.2,(18.0-side_row)*3.7/36.0+2.6,side_row);
	vec3 to_side = side_lamp-world_position;
	float side_pool = pow(max(0.0,1.0-length(to_side)/4.4),2.0)*max(dot(world_normal,normalize(to_side)),0.0);
	float inside = (1.0-smoothstep(17.0,19.0,abs(world_position.z)))*(1.0-smoothstep(10.0,16.0,abs(world_position.x)));
	EMISSION = paint*vec3(1.0,.53,.20)*(center_pool*1.5+side_pool*2.2)*inside;
	ALBEDO = paint;
	ROUGHNESS = roughness;
	METALLIC = base_metallic;
	SPECULAR = .42;
	AO = mix(mix(.76,1.0,smoothstep(.015,.22,height)),1.0,step(.7,world_normal.y));
}
