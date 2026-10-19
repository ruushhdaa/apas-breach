shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec4 water_color : source_color = vec4(0.22, 0.12, 0.06, 1.0);
uniform vec4 foam_color : source_color = vec4(0.45, 0.35, 0.25, 1.0);
uniform float speed = 0.005;

void fragment() {
    vec2 uv = UV;
    uv.x += TIME * speed;
    uv.y += sin(TIME * 0.5 + UV.x * 12.0) * 0.01;
    
    // Low-poly style stepped ripple pattern
    float ripple = sin(uv.x * 40.0 + uv.y * 30.0);
    ripple = step(0.6, ripple);
    
    // Thin highlight line near top edge (fake specular edge reflection)
    float edge_highlight = smoothstep(0.04, 0.0, UV.y);
    
    vec3 final_color = mix(water_color.rgb, foam_color.rgb, ripple * 0.25);
    final_color = mix(final_color, vec3(0.9, 0.85, 0.7), edge_highlight * 0.4);
    
    ALBEDO = final_color;
}
