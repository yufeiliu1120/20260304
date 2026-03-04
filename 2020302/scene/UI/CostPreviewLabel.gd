extends Label
class_name CostPreviewLabel

func _ready():
	# 默认隐藏
	visible = false
	
	# 确保不会遮挡鼠标点击
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 监听全局信号
	SignalBusAutoload.update_cost_preview.connect(_on_update_cost_preview)

func _process(_delta):
	# 如果当前正在显示，就让它跟随鼠标
	if visible:
		# 获取鼠标在屏幕上的相对位置，并加上一点偏移量（比如向右下角偏移）
		# 这样提示文字就不会被鼠标指针挡住
		var mouse_pos = get_viewport().get_mouse_position()
		global_position = mouse_pos + Vector2(20, 10)

func _on_update_cost_preview(msg: String, is_show: bool):
	text = msg
	visible = is_show
	
	# 如果你想做得更细致，可以根据文字内容改变颜色
	# 比如包含 "不足" 或者 "无法" 时文字变红
	if "不足" in msg or "无法" in msg:
		add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # 红色警告
	elif "+" in msg:
		add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # 橙黄色扣费
	else:
		add_theme_color_override("font_color", Color(0.5, 1.0, 0.5)) # 绿色安全
