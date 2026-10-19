shader_type canvas_item;

uniform float period = 2.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float noise = hash(UV + vec2(floor(TIME * 15.0), 0.0));
    // driven by sin(time * 2.3 + noise), range 0.85 to 1.0
    float flicker = 0.85 + 0.15 * (sin(TIME * period + noise * 4.0) * 0.5 + 0.5);
    
    // Subtle scanlines behind logo
    float scanline = sin(UV.y * 300.0) * 0.08;
    
    COLOR = vec4(col.rgb - scanline, col.a * flicker);
}
