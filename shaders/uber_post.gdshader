shader_type spatial;
render_mode depth_draw_never, depth_test_disabled, unshaded;

uniform sampler2D SCREEN_TEX : hint_screen_texture, repeat_disable;
uniform sampler2D DEPTH_TEX : hint_depth_texture, repeat_disable;
uniform sampler2D NORMAL_TEX : hint_normal_roughness_texture, repeat_disable;

uniform float VIRTUAL_HEIGHT : hint_range(9, 270) = 90.;
uniform vec3 SKYBOX_COLOR_TOP : source_color = vec3(.02, .02, .02);
uniform vec3 SKYBOX_COLOR_BTM : source_color = vec3(0., 0., 0.);
uniform vec3 OUTLINE_COLOR : source_color = vec3(0., 0., 0.);
uniform float OUTLINE_STRENGTH : hint_range(0, 1000) = 500.;
uniform float OUTLINE_WIDTH : hint_range(1, 10) = 4.;
uniform float OUTLINE_DEPTH : hint_range(0, 10) = .25;
uniform float OUTLINE_FALLOFF : hint_range(0, 5) = 1.;
uniform float COLOR_STEP : hint_range(0, 1) = .1;
uniform float COLOR_FALLOFF : hint_range(0, 5) = 2.;

const vec3 DEPTH_SAMPLES[] = {
	vec3(-1., -1., .4), vec3( 0., -1., .8), vec3( 1., -1., .4),
	vec3(-1.,  0., .8), vec3( 0.,  0., 1.), vec3( 1.,  0., .8),
	vec3(-1.,  1., .4), vec3( 0.,  1., .8), vec3( 1.,  1., .4)
};

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// PIXELLATION
	float PIXEL_SCALE = VIEWPORT_SIZE.y / VIRTUAL_HEIGHT;
	vec2 VIRTUAL_UV = floor(SCREEN_UV * (VIEWPORT_SIZE / PIXEL_SCALE)) / VIEWPORT_SIZE * PIXEL_SCALE;
	
	// WORLD
	ALBEDO = texture(SCREEN_TEX, VIRTUAL_UV).rgb;
	
	// COLOR
	// /posterize
	ALBEDO = COLOR_STEP * round(ALBEDO / COLOR_STEP);
	ALBEDO = vec3(pow(ALBEDO.r, COLOR_FALLOFF), pow(ALBEDO.g, COLOR_FALLOFF), pow(ALBEDO.b, COLOR_FALLOFF));
	// /atmospheric disturbance
	ALBEDO.b += max(1. - ALBEDO.r, 1. - ALBEDO.g) * .2;
	
	// SKYBOX
	ALBEDO = mix(ALBEDO, mix(SKYBOX_COLOR_TOP, SKYBOX_COLOR_BTM, SCREEN_UV.y), floor(texture(DEPTH_TEX, VIRTUAL_UV).r));
	
	// OUTLINES
	vec2 TEXEL_SIZE = 1. / VIEWPORT_SIZE * OUTLINE_WIDTH;
	float[9] depth_values;
	for(int i = 0; i < 9; i++) {
		depth_values[i] = pow(1. - texture(DEPTH_TEX, VIRTUAL_UV + DEPTH_SAMPLES[i].xy * TEXEL_SIZE).r, OUTLINE_FALLOFF) * OUTLINE_DEPTH;
	}
	float depth_total = 0.;
	for(int i = 0; i < 4; i++) {
		depth_total += abs(depth_values[i] - depth_values[4]) * DEPTH_SAMPLES[i].z;
	}
	for(int i = 5; i < 9; i++) {
		depth_total += abs(depth_values[i] - depth_values[4]) * DEPTH_SAMPLES[i].z;
	}
	ALBEDO = mix(ALBEDO, OUTLINE_COLOR, depth_total * OUTLINE_STRENGTH);
}
