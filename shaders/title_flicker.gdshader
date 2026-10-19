shader_type canvas_item;

uniform float period = 2.8;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float t = TIME * (6.28318 / period);
    float flicker = 0.925 + 0.075 * (0.6 * sin(t) + 0.3 * sin(t * 2.31) + 0.1 * sin(t * 5.17));
    COLOR = vec4(col.rgb, col.a * flicker);
}
