shader_type canvas_item;

// 传入一张噪点贴图，必须开启 repeat_enable 才能无缝滚动
uniform sampler2D noise_texture : repeat_enable, filter_nearest;

// 云朵的颜色 (如果是烟雾选灰白色，如果是阴影选深褐色/黑色)
uniform vec4 cloud_color : source_color = vec4(0.9, 0.85, 0.8, 0.2);

// 飘动的速度和方向
uniform vec2 scroll_speed = vec2(0.02, 0.015);

// 云朵的浓密程度 (0.0 到 1.0)
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // 根据时间和速度计算当前 UV 的偏移量
    vec2 moving_uv = UV + TIME * scroll_speed;
    
    // 获取噪点图在该位置的颜色 (通常是一张黑白图，我们取 r 通道即可)
    float noise_value = texture(noise_texture, moving_uv).r;
    
    // 用 smoothstep 处理噪点，让云朵边缘更清晰，或者更柔和
    // cloud_density 控制云的边缘，值越小云越稀薄
    float alpha = smoothstep(1.0 - cloud_density, 1.0, noise_value);
    
    // 输出最终颜色：RGB 为自定义颜色，Alpha 由噪点和基础透明度决定
    COLOR = vec4(cloud_color.rgb, alpha * cloud_color.a);
}