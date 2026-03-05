extends Node
class_name Connectivitymanager
# 哪些地块可以传导连通性
const CONDUCTIVE_TILES = ["HQ", "Road"]

## 更新全图连通性
func update_connectivity():
	var active_tiles = GridAutoload.active_tiles
	
	# 1. 重置所有地块状态
	for tile in active_tiles.values():
		tile.is_connected = false
	
	# 2. 寻找总部 HQ
	var queue = []
	var visited = {}
	
	for tile in active_tiles.values():
		if tile.data and tile.data.tile_name == "HQ":
			queue.append(tile)
			tile.is_connected = true
			visited[tile.grid_coordinate] = true
	
	# 3. BFS 扩散
	while queue.size() > 0:
		var current = queue.pop_front()
		var neighbors = GridAutoload.get_neighbors(current.grid_coordinate)
		
		for n_pos in neighbors:
			if active_tiles.has(n_pos) and not visited.has(n_pos):
				var neighbor_tile = active_tiles[n_pos]
				# 如果当前地块能传导，则点亮邻居
				if is_conductive(current):
					neighbor_tile.is_connected = true
					visited[n_pos] = true
					# 如果邻居也能传导，加入队列继续扩散
					if is_conductive(neighbor_tile):
						queue.append(neighbor_tile)
						
	# 通知全图：连通性刷新完毕，可以检查胜利条件了
	SignalBusAutoload.map_state_changed.emit()
	
func is_conductive(tile: Node) -> bool:
	if not tile or not tile.data: return false
	return tile.data.tile_name in CONDUCTIVE_TILES

## 简单的连通性探测：放置前检查周围是否有已连通的路或HQ
func check_placement_connectivity(grid_pos: Vector2i, is_hq: bool) -> bool:
	if is_hq: return true # HQ 总是合法的
	if GridAutoload.active_tiles.is_empty(): return true # 第一个地块默认合法
	
	for n_pos in GridAutoload.get_neighbors(grid_pos):
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			if n_tile.is_connected and is_conductive(n_tile):
				return true
	return false
	
	
func get_min_distance_at(grid_pos: Vector2i, is_hq: bool) -> int:
	# HQ 本身就是源头，距离永远是 0
	if is_hq: return 0 
	
	var min_dist = 999
	var neighbors = GridAutoload.get_neighbors(grid_pos)
	
	for n_pos in neighbors:
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			# 只有当邻居已连通，且是能传导的地块（Road 或 HQ）时，才能提供距离
			if n_tile.is_connected and is_conductive(n_tile):
				if n_tile.distance_to_source < min_dist:
					min_dist = n_tile.distance_to_source
	
	# 如果找到了合法的邻居，自身距离就是最近邻居的距离 + 1
	if min_dist < 999:
		return min_dist + 1
	else:
		return 999 # 未连通
