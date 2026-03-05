extends Button

func _ready():
	# 防止点击按钮时误触地块
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_on_pressed)

func _on_pressed():
	# 调用资源管理器执行结算
	GameResourceManager.process_turn()
	
	# 可以在这里加一个小小的视觉反馈，比如让按钮闪一下
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
