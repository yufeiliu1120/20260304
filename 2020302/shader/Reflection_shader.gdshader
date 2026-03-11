shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_img : repeat_enable;

// --- 基础参数 ---
uniform float wave_strength : hint_range(0.0, 0.05) = 0.01;
uniform float wave_speed : hint_range(0.0, 0.5) = 0.05;
uniform vec4 water_color : source_color = vec4(0.1, 0.25, 0.35, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.3;

// --- 高光参数 ---
uniform float sparkle_threshold : hint_range(0.0, 1.0) = 0.45; // 超过这个值就显示高光
uniform float sparkle_intensity : hint_range(0.0, 2.0) = 1.2; // 高光的亮度
uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // 高光颜色

void fragment() {
    // 1. 噪声 UV 计算
    vec2 noise_uv = UV + TIME * wave_speed;
    // 2. 获取原始噪声值
    float noise_raw = texture(noise_img, noise_uv).r;
    float noise_value = noise_raw - 0.5;
    
    // 3. 倒影采样
    vec2 distorted_uv = SCREEN_UV;
    distorted_uv.y -= UV.y * 1.0; // 简易对齐偏移
    distorted_uv.x += noise_value * wave_strength;
    distorted_uv.y += noise_value * wave_strength;
    vec4 reflection = texture(screen_texture, distorted_uv);
    
    // 4. 基础颜色混合
    float depth = UV.y; 
    vec4 final_color = mix(reflection, water_color, tint_amount + depth * 0.3);
    
    // 5. --- 增加高光部分 (Sparkles) ---
    // step 函数：如果 noise_raw > sparkle_threshold，返回 1.0，否则返回 0.0
    float sparkle_mask = step(sparkle_threshold, noise_raw);
    
    // 只在水面上半部分或者波浪尖端产生高光，并乘以强度
    vec4 sparkles = sparkle_mask * sparkle_color * sparkle_intensity;
    
    // 将高光叠加到最终颜色上
    final_color.rgb += sparkles.rgb;

    COLOR = final_color;
}
