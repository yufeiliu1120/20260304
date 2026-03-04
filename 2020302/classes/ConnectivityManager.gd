extends Node

## 定义哪些地块名具有传导功能（可以延伸路径）
const CONDUCTIVE_TILES = ["HQ", "Road"]

## 执行全图连通性检测
func update_connectivity_and_distance():
	var active_tiles = GridAutoload.active_tiles
	
	# 1. 初始化：重置状态
	for tile in active_tiles.values():
		tile.is_connected = false
		tile.distance_to_source = 999
	
	# 2. 收集所有“水源点”（HQ 和 已连通的驿站）
	var queue = []
	var visited = {}
	
	for tile in active_tiles.values():
		if not tile.data: continue
		
		# 只有 HQ 或 已激活的驿站/据点 能作为距离的起点
		# 注意：驿站本身必须先连通到 HQ 才能作为起点（可选规则，增加策略深度）
		if tile.data.tile_name == "HQ" or (tile.data.is_anchor and tile.is_connected):
			queue.append(tile)
			tile.distance_to_source = 0
			tile.is_connected = true
			visited[tile.grid_coordinate] = 0

	# 3. BFS 扩散计算距离
	while queue.size() > 0:
		var current = queue.pop_front()
		var neighbors = GridAutoload.get_neighbors(current.grid_coordinate)
		
		for n_coord in neighbors:
			if active_tiles.has(n_coord):
				var n_tile = active_tiles[n_coord]
				
				# 如果是传导地块（Road等），则传递距离
				if is_conductive(n_tile) and not visited.has(n_coord):
					n_tile.is_connected = true
					n_tile.distance_to_source = current.distance_to_source + 1
					visited[n_coord] = n_tile.distance_to_source
					queue.append(n_tile)
				# 如果是非传导建筑（如麦田），标记连通但不继续扩散
				elif not visited.has(n_coord):
					n_tile.is_connected = true
					n_tile.distance_to_source = current.distance_to_source + 1
					visited[n_coord] = n_tile.distance_to_source
					# 不加入 queue，因为建筑不能传导路径
					
	
## 辅助函数：判断地块是否能延伸路径
func is_conductive(tile: TileBase) -> bool:
	if not tile.data: return false
	return tile.data.tile_name in CONDUCTIVE_TILES
