extends VictoryCondition
class_name LighthouseVictory

func check_condition() -> bool:
	var total_lighthouses = 0
	var active_lighthouses = 0
	
	# 遍历地图上所有的地块
	for tile in GridAutoload.active_tiles.values():
		# 识别灯塔（注意：要在你的 lighthouse.tres 中把 tile_name 精确设置为 "Lighthouse"）
		if tile.data and tile.data.tile_name == "Lighthouse":
			total_lighthouses += 1
			# 如果灯塔是连通状态（is_connected == true），就算作激活
			if tile.is_connected:
				active_lighthouses += 1
				
	# 胜利条件：地图上至少有1个灯塔，且所有灯塔都已被激活
	if total_lighthouses > 0 and active_lighthouses == total_lighthouses:
		return true
		
	return false

func get_victory_message() -> String:
	return "海路大通！所有灯塔均已点亮，游戏胜利！"
