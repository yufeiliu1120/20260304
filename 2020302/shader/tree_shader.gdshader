shader_type canvas_item;

uniform float speed = 2.0;       // 摇摆速度
uniform float min_strength = 0.05; // 基础摇摆幅度
uniform float max_strength = 0.15; // 最大摇摆幅度
uniform float interval = 3.5;    // 阵风间隔

void vertex() {
	// 只有上半部分会动 (UV.y 越小越靠近顶部)
	float strength = mix(min_strength, max_strength, 0.5 + 0.5 * sin(TIME * 0.5));
	
	// 核心公式：利用 UV.y 的反比来控制偏移量
	// 1.0 - UV.y 确保底部 (UV.y=1) 权重为0，顶部权重最大
	float offset = sin(TIME * speed) * strength * (1.0 - UV.y);
	
	VERTEX.x += offset * 10.0; // 乘以一个系数来放大效果
}
