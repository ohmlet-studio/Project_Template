shader_type canvas_item;

uniform float outline_thickness : hint_range(0.5, 5.0) = 1.0;
uniform float outline_strength : hint_range(0.0, 10.0) = 2.0;
uniform float bw_mix : hint_range(0.0, 1.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D color_mask; // dynamically rendered mask

void fragment() {
    vec2 texel = TEXTURE_PIXEL_SIZE * outline_thickness;

    float tl = dot(texture(TEXTURE, UV + vec2(-texel.x, -texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float tm = dot(texture(TEXTURE, UV + vec2(0.0,      -texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float tr = dot(texture(TEXTURE, UV + vec2( texel.x, -texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float ml = dot(texture(TEXTURE, UV + vec2(-texel.x,  0.0    )).rgb, vec3(0.299, 0.587, 0.114));
    float mr = dot(texture(TEXTURE, UV + vec2( texel.x,  0.0    )).rgb, vec3(0.299, 0.587, 0.114));
    float bl = dot(texture(TEXTURE, UV + vec2(-texel.x,  texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float bm = dot(texture(TEXTURE, UV + vec2(0.0,       texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float br = dot(texture(TEXTURE, UV + vec2( texel.x,  texel.y)).rgb, vec3(0.299, 0.587, 0.114));

    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tm - tr + bl + 2.0*bm + br;
    float edge = clamp(sqrt(gx*gx + gy*gy) * outline_strength, 0.0, 1.0);

    vec4 base = texture(TEXTURE, UV);
    float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    vec4 bw = vec4(vec3(luma), base.a);

    float mask = texture(color_mask, UV).r;

    vec4 color = mix(mix(base, bw, bw_mix), base, mask);
    color = mix(color, vec4(outline_color.rgb, color.a), edge * outline_color.a * (1.0 - mask));

    COLOR = color;
}