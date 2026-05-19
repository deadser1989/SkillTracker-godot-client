shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;

uniform vec4 lines_pos[100];
uniform int lines_count = 0;

uniform vec4 fog_color : source_color = vec4(0.02, 0.05, 0.1, 1.0);
uniform vec4 glow_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);

uniform float fog_clear_radius = 230.0; 

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 uv = world_pos * 0.0013 + vec2(TIME * 0.025, TIME * 0.015);
    float noise = texture(noise_tex, uv).r;

    vec4 final_color = fog_color;
    final_color.a *= (noise * 0.7 + 0.3);

    float min_dist = 100000.0;

    for (int i = 0; i < lines_count; i++) {
        vec2 a = lines_pos[i].xy;
        vec2 b = lines_pos[i].zw;
        
        vec2 pa = world_pos - a;
        vec2 ba = b - a;
        float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
        
        if (dot(ba, ba) == 0.0) h = 0.0; 
        
        float d = length(pa - ba * h);
        
        min_dist = min(min_dist, d);
    }

    float fog_density = smoothstep(fog_clear_radius * 0.4, fog_clear_radius, min_dist);
    final_color.a *= fog_density;

    float edge_glow = smoothstep(0.4, 0.8, fog_density) * smoothstep(1.0, 0.8, fog_density);
    final_color.rgb += glow_color.rgb * edge_glow * 2.0;

    COLOR = final_color;
}