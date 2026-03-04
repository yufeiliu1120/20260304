extends StateMachine.State
class_name tile_idle_base
var state_name = "Idle"

func enter():
	actor.z_index = 0
	# 确保鼠标是显示状态
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func do(_delta):
	# 单次点击
	if Input.is_action_just_pressed("mouse_left"):
		if actor_is_hovered():
			if not get_tree().get_first_node_in_group("ControlNode").mouse_is_dragging:
				state_finished.emit("Dragging")
func actor_is_hovered() -> bool:
	var mouse_pos = actor.get_global_mouse_position()
	var collision_poly = actor.get_node_or_null("CollisionPolygon2D")
	if collision_poly:
		var local_mouse = collision_poly.to_local(mouse_pos)
		return Geometry2D.is_point_in_polygon(local_mouse, collision_poly.polygon)
	return false
