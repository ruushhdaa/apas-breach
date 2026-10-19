shader_type canvas_item;

uniform float period = 2.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float noise = hash(UV + vec2(floor(TIME * 15.0), 0.0)) * 2.0 - 1.0;
    // organic flicker: opacity = 0.88 + 0.12 * sin(TIME * 2.3 + noise)
    float flicker = clamp(0.88 + 0.12 * sin(TIME * period + noise), 0.0, 1.0);
    COLOR = vec4(col.rgb, col.a * flicker);
}
