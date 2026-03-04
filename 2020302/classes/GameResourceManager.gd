extends Node

# --- 资源库存 ---
var stocks = {
	"food": 20,
	"wood": 10,
	"stone": 50,
	"explorer": 5,
	"iron": 0,
	"knight": 0
}

# --- 距离惩罚配置 (可在编辑器或初始化时调整) ---
@export_group("Distance Penalty Settings")
## 每多少格增加一次惩罚 (Step)
@export var step_distance: int = 2
## 每次达到 Step 时增加的资源量
@export var penalty_per_step: Dictionary = {
	"stone": 1,
	"wood": 0 # 如果以后想加木头消耗，直接改这里
}

# --- 信号 ---
signal resources_changed(new_stocks)
signal game_over(reason)
signal turn_started(turn_count)

var current_turn: int = 1
# --- 核心：回合结算逻辑 ---

func end_turn():
	# 1. 连通性扫描 (这里调用未来的 ConnectivityManager)
	ConnectivityManager.update_connectivity_and_distance()
	
	# 2. 统计当前所有工作地块的产出和消耗
	var turn_delta = _calculate_turn_resources()
	
	# 3. 核心判定：食物是否归零
	if stocks["food"] + turn_delta["food"] < 0:
		game_over.emit("饥荒：食物储备耗尽，探险队无法维持。")
		return # 停止结算
	
	# 4. 正式更新库存
	for res in stocks.keys():
		if turn_delta.has(res):
			stocks[res] += turn_delta[res]
	
	# 5. 回合数增加并通知 UI
	current_turn += 1
	resources_changed.emit(stocks)
	turn_started.emit(current_turn)
	print("回合结算完成。当前食物: ", stocks["food"])

# --- 内部计算逻辑 ---

func _calculate_turn_resources() -> Dictionary:
	var delta = {
		"food": 0, "wood": 0, "stone": 0, "explorer": 0, "iron": 0
	}
	
	# 遍历当前场上所有活跃地块
	for tile in GridAutoload.active_tiles.values():
		if not tile is TileBase: continue
		if not tile.is_working(): continue
		
		var d = tile.data
		if not d: continue
		
		# 统计食物 (产量 - 维护费)
		delta["food"] += (d.food_production - d.food_maintenance)
		
		# 统计其他资源
		for res in d.production.keys():
			if delta.has(res):
				delta[res] += d.production[res]
				
	return delta

# --- 外部调用接口 ---
func get_placement_penalty(grid_pos: Vector2i) -> Dictionary:
	var penalty = {}
	
	# 从 ConnectivityManager 获取该位置邻居中最短的距离
	var min_dist = ConnectivityManager.get_min_neighbor_distance(grid_pos)
	
	# 如果未连接或在起点附近，不产生惩罚
	if min_dist >= 999 or min_dist <= 0:
		return penalty
	
	# 计算惩罚倍率 (例如：距离5，Step 2 -> 5/2 = 2倍惩罚)
	var multiplier = int(min_dist / step_distance)
	
	if multiplier > 0:
		for res in penalty_per_step.keys():
			var amount = penalty_per_step[res] * multiplier
			if amount > 0:
				penalty[res] = amount
				
	return penalty


## 尝试执行最终放置（检查差价并扣款）
## 返回 true 表示支付成功，允许放置
func try_final_placement(grid_pos: Vector2i) -> bool:
	var penalty = get_placement_penalty(grid_pos)
	
	# 如果没有惩罚，直接通过
	if penalty.is_empty():
		return true
		
	if can_afford(penalty):
		consume_resources(penalty)
		return true
	else:
		# 这里可以发送一个信号，让 UI 弹出提示文字
		print("补给不足！需要额外资源: ", penalty)
		return false


## 修改现有的 consume_resources，确保触发 UI 刷新
func consume_resources(cost_dict: Dictionary):
	for res in cost_dict.keys():
		if stocks.has(res):
			stocks[res] -= cost_dict[res]
	resources_changed.emit(stocks)


## 检查是否买得起
func can_afford(cost_dict: Dictionary) -> bool:
	for res in cost_dict.keys():
		if stocks.get(res, 0) < cost_dict[res]:
			return false
	return true
