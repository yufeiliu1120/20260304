extends Node

signal resources_changed(new_stocks)
signal turn_started(turn_count)

var current_turn: int = 1
var stocks = {
	"food": 20,
	"wood": 10,
	"stone": 30,
	"explorer": 5
}

func end_turn():
	# 1. 先更新连通性，这会影响地块是否 is_working
	ConnectivityManager.update_connectivity()
	
	# 2. 结算产出
	var delta = _calculate_resources()
	for res in delta:
		if stocks.has(res):
			stocks[res] += delta[res]
	
	current_turn += 1
	resources_changed.emit(stocks)
	turn_started.emit(current_turn)

func _calculate_resources() -> Dictionary:
	var delta = {"food": 0, "wood": 0, "stone": 0, "explorer": 0}
	for tile in GridAutoload.active_tiles.values():
		if tile.has_method("is_working") and tile.is_working():
			var d = tile.data
			delta["food"] += (d.food_production - d.food_maintenance)
			# 这里可以根据需要添加其他资源的生产逻辑
	return delta

func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if stocks.get(res, 0) < cost[res]:
			return false
	return true

func consume_resources(cost: Dictionary):
	for res in cost:
		stocks[res] -= cost[res]
	resources_changed.emit(stocks)
	
## 计算地块落地时的额外差价
func get_placement_penalty(tile_data: TileResourceData, distance: int) -> Dictionary:
	var penalty = {}
	
	# 如果数据为空，或者距离无效/在HQ旁边(距离为0)，则没有额外花费
	if not tile_data or distance <= 0 or distance >= 999:
		return penalty
		
	# 遍历地块的 distance_penalty 配置，乘以距离
	for res in tile_data.distance_penalty.keys():
		var cost_per_step = tile_data.distance_penalty[res]
		if cost_per_step > 0:
			penalty[res] = cost_per_step * distance
			
	return penalty
