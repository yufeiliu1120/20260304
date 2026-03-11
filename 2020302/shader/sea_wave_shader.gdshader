shader_type canvas_item;

// --- 动画参数 ---
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_frequency : hint_range(0.0, 50.0) = 20.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
uniform float foam_softness : hint_range(0.0, 1.0) = 0.5;

// --- 颜色设置 (对应 coast.png) ---
uniform vec4 sea_base_color : source_color = vec4(0.12, 0.36, 0.44, 1.0); 
uniform vec4 sea_light_color : source_color = vec4(0.24, 0.72, 0.64, 1.0); 
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);       

// --- 颜色检测阈值 ---
const float sea_detection_threshold = 0.15;

void fragment() {
    vec4 sprite_color = texture(TEXTURE, UV);
    
    // 1. 计算当前像素与海基色的距离
    float dist_to_sea = distance(sprite_color.rgb, sea_base_color.rgb);
    
    // 判定是否属于海水区域 (权重 0.0 到 1.0)
    float is_sea = 1.0 - smoothstep(0.0, sea_detection_threshold, dist_to_sea);

    // 2. 只有当确实是海水区域时才计算动画逻辑
    if (is_sea > 0.1) {
        // 生成波动值
        float wave = sin(TIME * wave_speed + UV.y * wave_frequency) * wave_amplitude;
        
        // 计算浪花位置 (foam_threshold 0.55-0.6 比较贴合海岸边缘)
        float foam_threshold = 0.58; 
        float foam_mix = smoothstep(foam_threshold - wave - (foam_softness * 0.02), foam_threshold - wave, UV.x);
        
        // 混合深海色与浅海色
        vec3 recomputed_sea = mix(sea_base_color.rgb, sea_light_color.rgb, is_sea);
        // 再次混合浪花白色
        vec3 final_rgb = mix(recomputed_sea, foam_color.rgb, foam_mix);
        
        // 输出最终带波浪的颜色
        COLOR = vec4(final_rgb, sprite_color.a);
    } 
    else {
        // 如果不是海水区域（沙滩/草地），直接输出原图颜色
        COLOR = sprite_color;
    }
}
