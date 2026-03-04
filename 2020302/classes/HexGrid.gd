extends Node
# 针对 64x70 素材的经验值
# 宽度 64，水平相邻中心距离就是 64
const OFFSET_X = 64.0 
# 垂直步进：为了让斜边嵌合，垂直距离通常是高度的 0.75 左右
# 你的面高约 64， 64 * 0.75 = 48
const OFFSET_Y = 48.0 

# 用于存储地图数据： { Vector2i(q, r): 地块实例 }
var active_tiles: Dictionary = {}

# 获取某个坐标周围的 6 个邻居坐标
func get_neighbors(grid_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	# 尖顶六边形在不同行（偶数/奇数）的偏移量不同
	var is_odd = abs(grid_pos.y) % 2 == 1
	
	# 定义 6 个方向的相对偏移
	var directions = []
	if not is_odd:
		directions = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), 
			Vector2i(0, 1), Vector2i(-1, -1), Vector2i(-1, 1)
		]
	else:
		directions = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), 
			Vector2i(0, 1), Vector2i(1, -1), Vector2i(1, 1)
		]
	
	for dir in directions:
		neighbors.append(grid_pos + dir)
	return neighbors

# 检查是否满足放置条件
func can_place_tile(grid_pos: Vector2i, tile_actor: Node2D) -> bool:
	# 1. 基础逻辑判定：是否重叠
	if active_tiles.has(grid_pos):
		return false
	
	# 2. 物理区域判定：是否在 BuildZone 内
	# 获取地块上的 Area2D 节点
	var area = tile_actor
	var overlapping_areas = area.get_overlapping_areas()
	
	var is_in_zone = false
	for a in overlapping_areas:
		if a.is_in_group("BuildZone"): # 或者使用 class_name/Group 判定
			is_in_zone = true
			break
	
	if not is_in_zone:
		return false

	# 3. 邻接逻辑判定：如果是第一个地块则跳过，否则必须挨着现有地块
	if active_tiles.is_empty():
		return true
		
	for n_pos in get_neighbors(grid_pos):
		if active_tiles.has(n_pos):
			return true
			
	return false
# 注册地块
func register_tile(grid_pos: Vector2i, tile_instance: Node):
	if active_tiles.has(grid_pos):
		return false # 已经有地块了
	active_tiles[grid_pos] = tile_instance
	return true

# 注销地块 (当拖走地块时)
func unregister_tile(grid_pos: Vector2i):
	active_tiles.erase(grid_pos)

# 检查某个位置是否已被占用
func is_position_occupied(grid_pos: Vector2i) -> bool:
	return active_tiles.has(grid_pos)
func pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
	# 逆向推算行号 r
	var r = round(pixel_pos.y / OFFSET_Y)
	# x轴受行号影响，因为奇数行会有半个宽度的偏移
	var offset_x_at_row = (int(r) % 2) * (OFFSET_X / 2.0)
	var q = round((pixel_pos.x - offset_x_at_row) / OFFSET_X)
	return Vector2i(int(q), int(r))

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	# 奇数行水平偏移半个宽度
	var x_offset = (abs(grid_pos.y) % 2) * (OFFSET_X / 2.0)
	var x = grid_pos.x * OFFSET_X + x_offset
	var y = grid_pos.y * OFFSET_Y
	return Vector2(x, y)
