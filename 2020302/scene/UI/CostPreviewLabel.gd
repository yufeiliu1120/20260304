extends Label
class_name CostPreviewLabel

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SignalBusAutoload.update_cost_preview.connect(_on_update_cost_preview)

func _process(_delta):
	if visible:
		var mouse_pos = get_viewport().get_mouse_position()
		global_position = mouse_pos + Vector2(20, 10)

func _on_update_cost_preview(status: int, penalty: Dictionary, is_show: bool):
	visible = is_show
	if not is_show: return
	
	match status:
		0:
			text = tr("UI_COST_FREE")
			# 防呆逻辑：如果没配翻译表，tr()会返回原文，我们就强制显示中文
			if text == "UI_COST_FREE": text = "无额外花费" 
			add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		1:
			var stone_cost = penalty.get("stone", 0)
			var template = tr("UI_COST_ADD")
			# 防呆逻辑：确保字符串里一定有 %d，这样就不会触发 not all arguments converted
			if template == "UI_COST_ADD": template = "+ %d 石头" 
			text = template % stone_cost
			add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		2:
			text = tr("UI_WARNING_NO_FUNDS")
			if text == "UI_WARNING_NO_FUNDS": text = "补给运费不足"
			add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		3:
			text = tr("UI_WARNING_INVALID_POS")
			if text == "UI_WARNING_INVALID_POS": text = "无法放置"
			add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
