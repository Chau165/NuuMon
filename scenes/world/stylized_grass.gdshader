shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert_wrap, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.12, 0.42, 0.16, 1.0);
uniform vec4 tip_color : source_color = vec4(0.42, 0.76, 0.28, 1.0);
uniform float wind_strength : hint_range(0.0, 0.2) = 0.045;
uniform float wind_speed : hint_range(0.0, 4.0) = 1.25;
uniform vec2 wind_direction = vec2(1.0, 0.35);
uniform float patch_scale : hint_range(0.001, 0.2) = 0.035;
uniform float patch_strength : hint_range(0.0, 0.4) = 0.16;
uniform float instance_color_strength : hint_range(0.0, 0.25) = 0.06;
uniform float emission_strength : hint_range(0.0, 0.2) = 0.02;
uniform float mesh_bottom = 0.0;
uniform float mesh_height = 1.0;

varying float blade_height;
varying vec3 blade_world_position;
varying float instance_tint;


float random_value(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}


float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);

	float bottom_left = random_value(cell);
	float bottom_right = random_value(cell + vec2(1.0, 0.0));
	float top_left = random_value(cell + vec2(0.0, 1.0));
	float top_right = random_value(cell + vec2(1.0, 1.0));
	return mix(mix(bottom_left, bottom_right, local.x), mix(top_left, top_right, local.x), local.y);
}


void vertex() {
	blade_height = smoothstep(0.0, 1.0, (VERTEX.y - mesh_bottom) / max(mesh_height, 0.001));
	instance_tint = INSTANCE_CUSTOM.r * 2.0 - 1.0;
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 direction = normalize(wind_direction);
	float large_gust = sin(TIME * wind_speed + dot(world_position.xz, vec2(0.14, 0.11)));
	float small_gust = sin(TIME * wind_speed * 1.73 + dot(world_position.xz, vec2(-0.23, 0.19)));
	float gust = large_gust * 0.72 + small_gust * 0.28;
	VERTEX.xz += direction * gust * wind_strength * blade_height * blade_height;
	blade_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float patch = value_noise(blade_world_position.xz * patch_scale);
	vec3 grass_color = mix(base_color.rgb, tip_color.rgb, blade_height);
	grass_color *= mix(1.0 - patch_strength, 1.0 + patch_strength, patch);
	grass_color *= 1.0 + instance_tint * instance_color_strength;
	ALBEDO = grass_color;
	ROUGHNESS = 0.92;
	AO = mix(0.97, 1.0, blade_height);
	EMISSION = grass_color * emission_strength;
}
