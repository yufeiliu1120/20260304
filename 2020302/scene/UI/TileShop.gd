extends Button
class_name tile_shop
@export var tile_scene: PackedScene # 在编辑器里拖入你的 Road 或其他地块场景
@export var base_cost: Dictionary = {"stone": 5,"wood": 0,"food": 0} # 基础购买价格
func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed():
	# 1. 检查是否买得起基础价格
	if GameResourceManager.can_afford(base_cost):
		# 2. 扣除基础费用
		GameResourceManager.consume_resources(base_cost)
		
		# 3. 实例化地块并交给拖拽系统
		var new_tile = tile_scene.instantiate()
		get_tree().get_first_node_in_group("TileStorage").add_child(new_tile)
		
		# 4. 通知状态机进入拖拽状态（假设你的状态机有这个接口）
		# 注意：此时地块是“预付”状态，放置时会触发 try_final_placement 补差价
		new_tile.Statemachine.current_state.state_finished.emit("Dragging")
	else:
		print("买不起！需要: ", base_cost)
