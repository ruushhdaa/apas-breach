shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float vignette = smoothstep(0.3, 0.75, dist);
    COLOR = vec4(0.0, 0.0, 0.0, vignette * vignette_intensity * vignette_opacity);
}
