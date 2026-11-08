shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D board_atlas : source_color, filter_linear, repeat_disable;
uniform float elapsed = 0.0;
uniform bool reduced_motion = false;
const vec2 GRID = vec2(39.0, 6.0);
const float PAGE_SECONDS = 6.0;

vec3 sample_page(vec2 uv, float page) {
	return texture(board_atlas, vec2(uv.x, (uv.y + page) / 3.0)).rgb;
}

void fragment() {
	vec2 tile = UV * GRID;
	vec2 cell = floor(tile);
	float y = fract(tile.y);
	float step = floor(elapsed / PAGE_SECONDS);
	float next = mod(step, 3.0);
	float last = mod(step + 2.0, 3.0);
	float stagger = cell.x * 0.010 + cell.y * 0.047 + mod(cell.x * 11.0 + cell.y * 7.0, 9.0) * 0.011;
	float age = mod(elapsed, PAGE_SECONDS) - stagger;
	float flip = clamp(age / 0.32, 0.0, 1.0);
	vec3 paint = sample_page(UV, next);

	if (!reduced_motion && step > 0.0 && cell.y > 0.0 && flip < 1.0) {
		bool first_half = flip < 0.5;
		float fold = max(abs(cos(flip * PI)), 0.001);
		float from_hinge = (y - 0.5) / fold;
		if (y >= 0.5) {
			paint = sample_page(UV, last);
		}
		if ((first_half && from_hinge >= -0.5 && y < 0.5)
				|| (!first_half && from_hinge <= 0.5 && y >= 0.5)) {
			float face_y = (cell.y + 0.5 + from_hinge) / GRID.y;
			paint = sample_page(vec2(UV.x, face_y), first_half ? last : next) * mix(0.47, 1.0, fold);
		}
	}
	ALBEDO = paint * (1.0 - 0.36 * (1.0 - smoothstep(0.02, 0.044, abs(y - 0.5))));
}
