extends Node2D
var mouse_is_dragging:bool

func set_mouse_is_dragging(status:bool):
	mouse_is_dragging = status
	



func _on_button_pressed() -> void:
	ConnectivityManager.update_connectivity()
