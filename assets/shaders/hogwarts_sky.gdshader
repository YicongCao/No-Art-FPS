shader_type sky;

uniform float frenzy : hint_range(0.0, 1.0) = 0.0;

void sky() {
	vec3 low = mix(vec3(.85,.39,.38), vec3(.79,.30,.67), frenzy);
	vec3 high = mix(vec3(.27,.25,.48), vec3(.21,.16,.45), frenzy);
	float height = max(EYEDIR.y, 0.0);
	vec3 dusk = mix(low, high, smoothstep(-.05,.46,height));
	float drift = sin(EYEDIR.x*10.0+EYEDIR.z*4.0)*.33;
	float cloud_band = sin(height*50.0+drift+sin(EYEDIR.z*6.0)*2.5);
	float breaks = sin(EYEDIR.x*12.0+EYEDIR.z*16.0)*.48 + sin(EYEDIR.x*38.0-EYEDIR.z*21.0+height*14.0)*.22;
	float clouds = smoothstep(.61,.92,cloud_band*.53+breaks)*smoothstep(.01,.06,height)*(1.0-smoothstep(.21,.39,height));
	vec3 cloud_color = mix(vec3(.96,.56,.51), vec3(.94,.53,.77), frenzy);
	COLOR = mix(dusk, cloud_color, clouds*.42);
}
