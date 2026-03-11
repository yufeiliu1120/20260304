shader_type canvas_item;

// 定义两个变量：是否开启闪白，以及闪白的颜色（默认为白色）
uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // 获取纹理原本的颜色
    vec4 tint_color = texture(TEXTURE, UV);
    
    // 如果 active 为 true，则将非透明部分的颜色替换为 flash_color
    if (active) {
        tint_color.rgb = flash_color.rgb;
    }
    
    COLOR = tint_color;
}