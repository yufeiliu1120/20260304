extends StateMachine.State
class_name tile_idle_base

var state_name = "Idle"

func enter():
	actor.z_index = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func do(_delta):
	# 【核心修复】防穿透：如果鼠标悬停在 UI 上（如按钮、面板），直接跳过地块的输入处理！
	if _is_mouse_over_ui():
		return

	# 1. 鼠标左键逻辑
	if Input.is_action_just_pressed("mouse_left"):
		# 只要没点在 UI 上，点其他任何地方都会隐藏菜单
		SignalBusAutoload.hide_tile_menu.emit()
		
		if actor_is_hovered():
			if not get_tree().get_first_node_in_group("ControlNode").mouse_is_dragging:
				_on_tile_clicked()

	# 2. 鼠标右键逻辑
	if Input.is_action_just_pressed("mouse_right"):
		if actor_is_hovered():
			actor._try_open_context_menu()


# --- 辅助函数 ---

## 判断鼠标是否正悬停在 UI 控件上
func _is_mouse_over_ui() -> bool:
	# Godot 4 专属方法：获取当前阻挡鼠标的最高层 Control 节点
	var hovered_control = get_viewport().gui_get_hovered_control()
	# 如果不为空，说明鼠标被 UI 挡住了
	return hovered_control != null


func actor_is_hovered() -> bool:
	var mouse_pos = actor.get_global_mouse_position()
	var collision_poly = actor.get_node_or_null("CollisionPolygon2D")
	if collision_poly:
		var local_mouse = collision_poly.to_local(mouse_pos)
		return Geometry2D.is_point_in_polygon(local_mouse, collision_poly.polygon)
	return false

func _on_tile_clicked():
	print("点击了已固定的地块: ", actor.data.tile_name if actor.data else "未知地块")
	var sprite = actor.get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.05, 0.95), 0.05)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
