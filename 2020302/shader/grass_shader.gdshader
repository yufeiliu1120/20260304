shader_type canvas_item;

// 控制参数
uniform float speed = 2.0;     
uniform float min_strength = 0.05; 
uniform float max_strength = 0.2; 
uniform float interval = 3.5;
uniform float detail = 1.0;   

void vertex() {
	float vertical_factor = pow(1.0 - UV.y, 1.2); 
	float time = TIME * speed;
	float wave = sin(time) * 0.5 + 0.5;
	wave += sin(time * 1.5 + 0.5) * 0.3;
	wave += sin(time * 0.8 - 0.2) * 0.2;
	float strength = mix(min_strength, max_strength, wave);
	float offset = sin(time * detail) * strength;
	VERTEX.x += offset * vertical_factor * (TEXTURE_PIXEL_SIZE.x * 500.0);
}
