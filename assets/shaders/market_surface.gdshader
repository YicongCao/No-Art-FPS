shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.3,0.5,0.6,1.0);
uniform sampler2D detail_noise : repeat_enable, filter_linear_mipmap_anisotropic;
uniform float base_roughness = 0.8;
uniform float base_metallic = 0.0;
uniform bool ground_surface = false;
uniform bool canopy_surface = false;
uniform bool use_vertex_color = false;
uniform int surface_kind = 0; // paint, metal, masonry, fabric
varying vec3 world_position;
varying vec3 world_normal;
float nearest_pendant(float z) {
	const float rows[7] = float[7](-12.0,-8.0,-1.0,3.0,9.0,13.0,16.0);
	float nearest = rows[0];
	for(int i=1;i<7;i++) if(abs(z-rows[i])<abs(z-nearest)) nearest=rows[i];
	return nearest;
}
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
	if(use_vertex_color) paint *= COLOR.rgb;
	float contrast = surface_kind==2 ? 0.07 : 0.08;
	paint *= 1.0+(macro-.5)*contrast+(grain-.5)*0.06;
	float roughness = clamp(base_roughness+(macro-.5)*.14,0.14,1.0);
	float ground_y = clamp((18.0-world_position.z)*3.7/36.0,0.0,3.7);
	float height = max(0.0,world_position.y-ground_y);
	float dist = length(world_position - CAMERA_POSITION_WORLD);
	float near_mask = 1.0 - smoothstep(12.0, 32.0, dist);
	if(surface_kind==0 || surface_kind==1) {
		float wear = (1.0-smoothstep(.02,.20,height))*smoothstep(.42,.72,grain)*.18;
		paint = mix(paint,mix(paint*.88,vec3(.52,.48,.40),.35),wear);
		roughness = clamp(roughness + wear * .10, 0.14, 1.0);
		float curv = length(fwidth(world_normal)) / max(length(fwidth(world_position)) * 18.0, 0.035);
		float chip = smoothstep(0.24, 0.72, curv) * smoothstep(0.36, 0.68, grain) * near_mask;
		vec3 edge_col = surface_kind==1 ? vec3(0.86, 0.90, 0.94) : mix(vec3(0.95, 0.90, 0.80), paint * 1.28, 0.45);
		paint = mix(paint, edge_col, clamp(chip * 0.34, 0.0, 0.30));
		roughness = clamp(roughness - chip * 0.10, 0.14, 1.0);
	}
	if(surface_kind==2 && world_normal.y>.7) {
		float damp = smoothstep(.38,.65,macro);
		paint *= mix(1.0,.82,damp);
		roughness = mix(roughness,.24,damp);
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
	NORMAL = normalize(NORMAL-gradient*(surface_kind==2 ? .0015 : .0018));
	// Local diffuse bounce from the fixed rows of practical fixtures. Geometry and direct lights remain dynamic.
	float row = clamp(round(world_position.z/5.0)*5.0,-15.0,15.0);
	vec3 lamp = vec3(0.0,(18.0-row)*3.7/36.0+3.64,row);
	vec3 to_lamp = lamp-world_position;
	float center_pool = pow(max(0.0,1.0-length(to_lamp)/6.0),2.0)*max(dot(world_normal,normalize(to_lamp)),0.0);
	float side_row = nearest_pendant(world_position.z);
	vec3 side_lamp = vec3(sign(world_position.x)*6.2,(18.0-side_row)*3.7/36.0+2.6,side_row);
	vec3 to_side = side_lamp-world_position;
	float side_pool = pow(max(0.0,1.0-length(to_side)/4.4),2.0)*max(dot(world_normal,normalize(to_side)),0.0);
	float inside = (1.0-smoothstep(17.0,19.0,abs(world_position.z)))*(1.0-smoothstep(10.0,16.0,abs(world_position.x)));
	EMISSION = paint*vec3(1.0,.53,.20)*(center_pool*1.5+side_pool*2.2)*inside;
	if(ground_surface && world_normal.y>.7) {
		// Local pools from the existing ceiling fixtures; retain darker gaps between lamps.
		vec2 center_delta = vec2(world_position.x,world_position.z-row);
		float pool = exp(-dot(center_delta/vec2(1.8,1.35),center_delta/vec2(1.8,1.35)));
		vec2 side_delta = vec2(abs(world_position.x)-6.2,world_position.z-side_row);
		float side = exp(-dot(side_delta/vec2(1.45,1.6),side_delta/vec2(1.45,1.6)));
		EMISSION += vec3(1.0,.62,.28)*(pool*.50+side*.36)*inside*(.80+grain*.4);
		// Broad rough-surface fixture reflection; the sharper image lives in the wet film.
		vec3 eye_ray = normalize(world_position-CAMERA_POSITION_WORLD);
		vec3 reflected_ray = reflect(eye_ray,normalize(vec3(0.0,1.0,3.7/36.0)));
		vec2 hit = world_position.xz + reflected_ray.xz * 3.64/max(dot(reflected_ray,normalize(vec3(0.0,1.0,3.7/36.0))),.08);
		float row_delta = abs(mod(hit.y+2.5,5.0)-2.5);
		float spec = exp(-pow(hit.x/.85,2.0)-pow(row_delta/.70,2.0));
		vec2 side_hit = world_position.xz+reflected_ray.xz*2.57/max(dot(reflected_ray,normalize(vec3(0.0,1.0,3.7/36.0))),.08);
		float side_delta_z = abs(side_hit.y-nearest_pendant(side_hit.y));
		float side_spec = exp(-pow((abs(side_hit.x)-6.2)/.7,2.0)-pow(side_delta_z/.7,2.0));
		float rough_grain = mix(.65,1.0,smoothstep(.28,.68,fine));
		EMISSION += vec3(1.0,.65,.30)*(spec*.95+side_spec*.65)*rough_grain*inside;

	}
	if(canopy_surface) EMISSION += paint*.32;
	ALBEDO = paint;
	ROUGHNESS = roughness;
	METALLIC = base_metallic;
	SPECULAR = .42;
	AO = mix(mix(.76,1.0,smoothstep(.015,.22,height)),1.0,step(.7,world_normal.y));
}
