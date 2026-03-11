extends Node2D

@onready var rabbit = $AnimatedSprite2D
@onready var rabbit_shadow = $Sprite2D
var rabbit_generate:bool = false
var detail_showed:bool = true

func _ready() -> void:
	
	#控制地块中的兔子有一定几率生成在随机位置
	var rand1 = randi_range(0,100)
	if rand1 >= 50:
		rabbit_generate = true
	else:
		rabbit_generate = false
	if not rabbit_generate:
		rabbit.queue_free()
		rabbit_shadow.queue_free()
		
	#控制相机在缩小时会省略细节
	var cam = get_tree().get_first_node_in_group("Camera")
	if cam:
		# 连接信号到自身的控制函数
		cam.detail_mode_changed.connect(_on_camera_detail_changed)
		_update_visibility(cam.is_current_detailed)
	var rand = Vector2(randf_range(-21, 20),randf_range(-12, 15))
	rabbit.position = rand
	rabbit_shadow.position = Vector2(rand.x,rand.y + 6)
	
	
func _update_visibility(show_detail: bool):
	if not show_detail:
		detail_showed = false
		$grass.visible = false
		$outline.visible = false
	else:
		detail_showed = true
		$grass.visible = true
		$outline.visible = true
	
#控制细节会在相机缩小时被省略
func _on_camera_detail_changed(show_detail:bool):
	_update_visibility(show_detail)
	
