extends Node2D

func _ready() -> void:
	var rand = randi_range(1,100)
	if rand >= 70:
		$deer.visible = true
	else:
		$deer.visible = false
