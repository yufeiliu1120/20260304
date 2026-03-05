
extends Node
class_name MapGenerator

@export var coast_scene: PackedScene
@export var lighthouse_scene: PackedScene

@export_group("Map Settings")
## 地图生成中心点
@export var map_center: Vector2i = Vector2i(0, 0)
## 海岸线所在的半径（圈数）
@export var map_radius: int = 4
## 生成的灯塔数量
@export var lighthouse_count: int = 2


# --- 核心动画与放置逻辑 ---

func place_tile_at(grid_pos: Vector2i, tile_scene: PackedScene) -> Node2D:
	if GridAutoload.is_position_occupied(grid_pos):
		return null
		
	var new_tile = tile_scene.instantiate()
	new_tile.grid_coordinate = grid_pos
	new_tile.distance_to_source = 999
	new_tile.is_connected = false
	
	var target_pos = GridAutoload.grid_to_pixel(grid_pos)
	
	new_tile.global_position = target_pos + Vector2(0, -150)
	new_tile.modulate = Color(1, 1, 1, 0) 
	
	var storage = get_tree().get_first_node_in_group("TileStorage")
	if storage:
		storage.add_child(new_tile)
	else:
		add_child(new_tile)
		
	GridAutoload.register_tile(grid_pos, new_tile)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(new_tile, "global_position", target_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_tile, "modulate", Color(1, 1, 1, 1), 0.15)
	
	get_tree().create_timer(0.15).timeout.connect(func():
		_play_landing_effect(new_tile)
	)
	
	return new_tile

func _play_landing_effect(tile: Node2D):
	if not is_instance_valid(tile): return
	var dust = tile.get_node_or_null("DustParticles")
	if dust:
		dust.emitting = false
		dust.restart()
		dust.emitting = true
		
	var sprite = tile.get_node_or_null("Sprite2D")
	if sprite:
		var impact_tween = create_tween()
		impact_tween.tween_property(sprite, "scale", Vector2(1.1, 0.8), 0.05)
		impact_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

# --- 辅助提取函数：获取特定圈数的所有坐标 ---
func get_hex_ring(radius: int, center: Vector2i) -> Array[Vector2i]:
	var ring: Array[Vector2i] = []
	if radius <= 0:
		ring.append(center)
		return ring
		
	var visited = {center: 0}
	var queue = [center]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_dist = visited[current]
		if current_dist < radius:
			var neighbors = GridAutoload.get_neighbors(current)
			for n in neighbors:
				if not visited.has(n):
					visited[n] = current_dist + 1
					queue.append(n)
					
	for pos in visited.keys():
		if visited[pos] == radius:
			ring.append(pos)
			
	return ring

# --- 图形边界生成函数 ---
func generate_hex_border(radius: int, center: Vector2i, tile_scene: PackedScene):
	var ring_coords = get_hex_ring(radius, center)
	for pos in ring_coords:
		place_tile_at(pos, tile_scene)
		await get_tree().create_timer(0.05).timeout

# --- 测试与执行 ---
func _ready():
	await get_tree().create_timer(0.1).timeout
	
	if not coast_scene or not lighthouse_scene:
		push_error("请在编辑器中为 MapGenerator 分配 coast_scene 和 lighthouse_scene！")
		return
		
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(true)
	
	await get_tree().create_timer(0.5).timeout
	
	# 1. 动态读取暴露的变量来生成海岸线
	await generate_hex_border(map_radius, map_center, coast_scene)
	
	# 2. 生成多个海岸内侧的随机灯塔
	var inner_ring_coords = get_hex_ring(map_radius - 1, map_center)
	
	# 安全检查：防止要求的灯塔数量超过了内圈能容纳的总格子数
	var actual_count = min(lighthouse_count, inner_ring_coords.size())
	
	if actual_count > 0:
		# 克隆一份坐标数组并进行“洗牌”(打乱顺序)
		var available_coords = inner_ring_coords.duplicate()
		available_coords.shuffle() 
		
		# 按照打乱后的顺序，取前 N 个坐标进行放置，这样能保证灯塔绝对不会重叠
		for i in range(actual_count):
			var pos = available_coords[i]
			place_tile_at(pos, lighthouse_scene)
			
			# 如果生成多个，让它们依次“嘭、嘭”地落下来，效果更好
			await get_tree().create_timer(0.1).timeout 
	
	ConnectivityManager.update_connectivity()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(false)
	print("地图与地标生成完毕！")
