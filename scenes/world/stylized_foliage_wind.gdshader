shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.12;
uniform float wind_strength : hint_range(0.0, 0.15) = 0.035;
uniform float wind_speed : hint_range(0.0, 3.0) = 0.82;
uniform vec2 wind_direction = vec2(0.85, 0.35);
uniform float mesh_bottom = 0.0;
uniform float mesh_height = 1.0;

varying float wind_height;


void vertex() {
	float relative_height = clamp((VERTEX.y - mesh_bottom) / max(mesh_height, 0.001), 0.0, 1.0);
	wind_height = smoothstep(0.14, 0.88, relative_height);
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 direction = normalize(wind_direction);
	float phase = INSTANCE_CUSTOM.r * 6.2831853 + dot(world_position.xz, vec2(0.085, 0.063));
	float slow_sway = sin(TIME * wind_speed + phase);
	float detail_sway = sin(TIME * wind_speed * 1.67 + phase * 1.91);
	float gust = slow_sway * 0.72 + detail_sway * 0.28;
	VERTEX.xz += direction * gust * wind_strength * wind_height * wind_height;
}


void fragment() {
	vec4 surface_color = texture(albedo_texture, UV) * albedo_tint;
	if (surface_color.a < alpha_cutoff) {
		discard;
	}
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = surface_color.rgb;
	ROUGHNESS = 0.88;
	AO = mix(0.96, 1.0, wind_height);
}
