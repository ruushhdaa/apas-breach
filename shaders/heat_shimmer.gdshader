shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amplitude = 0.003;
uniform float speed = 2.0;

void fragment() {
	vec2 offset = vec2(
		sin(SCREEN_UV.y * 35.0 + TIME * speed),
		cos(SCREEN_UV.x * 35.0 + TIME * speed)
	) * amplitude;
	ALBEDO = texture(screen_tex, SCREEN_UV + offset).rgb;
}
