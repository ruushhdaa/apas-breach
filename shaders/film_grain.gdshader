shader_type canvas_item;

uniform float grain_amount : hint_range(0.0, 0.2) = 0.04;
uniform float timer_seed = 0.0;

// Pseudo-random generator
float rand(vec2 co) {
    return fract(sin(dot(co.xy + vec2(timer_seed, timer_seed * 1.618), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    float noise = (rand(UV * 256.0) - 0.5) * 2.0;
    COLOR = vec4(vec3(noise), grain_amount);
}
