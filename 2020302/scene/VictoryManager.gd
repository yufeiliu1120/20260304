extends Node

func _ready():
	# 【核心修复】通过代码动态实例化灯塔胜利规则，并作为子节点添加进来
	# 这样你就完全不需要在编辑器里手动创建节点并挂载脚本了！
	var lighthouse_objective = LighthouseVictory.new()
	add_child(lighthouse_objective)
	
	# 监听地图状态改变 (由 ConnectivityManager 每次刷新后发出)
	SignalBusAutoload.map_state_changed.connect(_on_map_state_changed)
	
	# 动态监听所有子节点（胜利条件）的胜利信号
	for child in get_children():
		if child is VictoryCondition:
			child.victory_achieved.connect(_on_victory_achieved)

func _on_map_state_changed():
	# 每次地图状态改变，让所有的胜利条件子节点都自查一遍
	for child in get_children():
		if child is VictoryCondition:
			child.evaluate()

func _on_victory_achieved(msg: String):
	# 触发全局胜利信号
	SignalBusAutoload.game_won.emit(msg)
	print("🏆 ", msg)
	
	# 为了防止重复触发胜利，可以在这里断开地图监听
	SignalBusAutoload.map_state_changed.disconnect(_on_map_state_changed)
