shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec4 water_color : source_color = vec4(0.22, 0.12, 0.06, 1.0);
uniform vec4 foam_color : source_color = vec4(0.55, 0.45, 0.35, 1.0);
uniform float speed = 0.02;

void fragment() {
    vec2 uv = UV;
    // Downstream current flow
    float stream_time = TIME * speed;
    vec2 stream_uv = vec2(uv.x + stream_time, uv.y + sin(TIME * 0.4 + uv.x * 8.0) * 0.015);
    
    // Low-poly stepped ripple pattern
    float ripple = sin(stream_uv.x * 35.0 + stream_uv.y * 25.0);
    ripple = step(0.65, ripple);
    
    // Moving specular highlight line moving downstream
    float spec_band = sin(stream_uv.x * 12.0 - TIME * 0.8) * 0.5 + 0.5;
    float spec_highlight = pow(spec_band, 16.0);
    
    // Foam patches near outfall (western edge / low X UV)
    float outfall_dist = length(vec2(uv.x * 2.0, (uv.y - 0.3) * 3.0));
    float foam_patch = step(0.55, sin(uv.x * 30.0 + TIME * 1.5) * cos(uv.y * 25.0 - TIME)) * smoothstep(0.4, 0.05, outfall_dist);
    
    vec3 col = mix(water_color.rgb, foam_color.rgb, ripple * 0.25);
    col = mix(col, vec3(0.85, 0.82, 0.75), foam_patch * 0.6);
    col += vec3(0.9, 0.85, 0.7) * spec_highlight * 0.35;
    
    ALBEDO = col;
}
