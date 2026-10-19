shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.54, 0.54, 0.50, 1.0); // #8A8A80
uniform vec4 streak_color : source_color = vec4(0.32, 0.32, 0.30, 1.0);

void fragment() {
    // Procedural vertical streaks scrolling slightly with UV
    float streak_pattern = sin(UV.x * 60.0) * sin(UV.x * 12.0 + 2.0);
    float vertical_fade = smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.7, UV.y);
    float is_streak = step(0.35, streak_pattern) * vertical_fade;
    
    vec3 col = mix(base_color.rgb, streak_color.rgb, is_streak * 0.45);
    ALBEDO = col;
    ROUGHNESS = 0.85;
}
