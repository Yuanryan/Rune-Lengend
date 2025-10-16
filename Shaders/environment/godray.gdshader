shader_type canvas_item;

uniform float ray_angle = -0.3;
uniform float ray_position = -0.2;
uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.1;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.15;

uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.3;

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.65, 0.8);

uniform bool hdr = false;
uniform float seed = 5.0;


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}


float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}


mat2 create_rotation_matrix(float rot_angle) {
    float s = sin(rot_angle);
    float c = cos(rot_angle);
    return mat2(vec2(c, -s), vec2(s, c));
}


vec3 screen_blend(vec3 base, vec3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment() {

    vec2 centered_uv = UV - vec2(0.5, ray_position);
    vec2 transformed_uv = create_rotation_matrix(ray_angle) * centered_uv;
    

    transformed_uv.y = transformed_uv.y / (transformed_uv.y * spread + 1.0);
    transformed_uv += vec2(0.5);
    
    float time_factor = TIME * speed;
    vec2 ray1_uv = vec2(
        transformed_uv.x * ray1_density + sin(time_factor * 0.1) * (ray1_density * 0.2) + seed,
        transformed_uv.y
    );
    
    vec2 ray2_uv = vec2(
        transformed_uv.x * ray2_density + sin(time_factor * 0.2) * (ray1_density * 0.2) + seed,
        transformed_uv.y
    );
    
    float cut_x = smoothstep(cutoff - 0.1, cutoff + 0.1, transformed_uv.x) * 
                 smoothstep(1.0 + cutoff + 0.1, 1.0 + cutoff - 0.1, transformed_uv.x);

    float ray1 = noise(ray1_uv);
    float ray2 = noise(ray2_uv) * ray2_intensity;
    
    float rays;
    if (hdr) {
        rays = ray1 + ray2;
    } else {
        rays = clamp(ray1 + ray2, 0.0, 1.0);
    }
    

    rays *= cut_x;
    rays *= smoothstep(0.0, falloff, 1.0 - UV.y);
    rays *= smoothstep(0.0, edge_fade, transformed_uv.x);
    rays *= smoothstep(0.0, edge_fade, 1.0 - transformed_uv.x);
    

    vec3 final_color = vec3(rays) * color.rgb;

    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    final_color = screen_blend(screen_color, final_color * color.a);
    
    COLOR = vec4(final_color, rays * color.a);
}