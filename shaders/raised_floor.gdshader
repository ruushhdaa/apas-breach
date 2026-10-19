shader_type spatial;
render_mode cull_back;

uniform vec4 tile_color : source_color = vec4(0.18, 0.22, 0.26, 1.0);
uniform vec4 grout_color : source_color = vec4(0.08, 0.09, 0.11, 1.0);
uniform float tile_scale = 1.0;

void fragment() {
    vec2 tile_coord = fract(UV * tile_scale);
    float border = step(0.94, tile_coord.x) + step(0.94, tile_coord.y);
    vec3 col = mix(tile_color.rgb, grout_color.rgb, clamp(border, 0.0, 1.0));
    ALBEDO = col;
    ROUGHNESS = 0.5;
}
