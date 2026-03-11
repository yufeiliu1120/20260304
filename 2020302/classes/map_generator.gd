extends Node
class_name MapGenerator

@export var coast_scene: PackedScene
@export var lighthouse_scene: PackedScene
@export var hq_scene: PackedScene # 【新增】用于自动生成的 HQ 场景

@export_group("Map Settings")
@export var map_center: Vector2i = Vector2i(0, 0)
@export var map_radius: int = 4
@export var lighthouse_count: int = 2
@export var auto_place_hq: bool = true # 【新增】是否在地图中心自动放置 HQ
signal game_start

# --- 核心动画与放置逻辑 ---
func place_tile_at(grid_pos: Vector2i, tile_scene: PackedScene) -> Node2D:
	if GridAutoload.is_position_occupied(grid_pos): return null
		
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

# ==========================================
# 【数学模块】精准测算海岸线的 12 种形态
# ==========================================

func _offset_to_cube(hex: Vector2i) -> Vector3i:
	var q = hex.x - floori(hex.y / 2.0)
	var r = hex.y
	var s = -q - r
	return Vector3i(q, r, s)

func get_coast_frame(grid_pos: Vector2i, center: Vector2i, radius: int) -> int:
	var cube = _offset_to_cube(grid_pos) - _offset_to_cube(center)
	var q = cube.x
	var r = cube.y
	var s = cube.z

	if q == radius and r == -radius and s == 0: return 0    
	if q == radius and r == 0 and s == -radius: return 2    
	if q == 0 and r == radius and s == -radius: return 4    
	if q == -radius and r == radius and s == 0: return 6    
	if q == -radius and r == 0 and s == radius: return 8    
	if q == 0 and r == -radius and s == radius: return 10   

	if q == radius and r < 0 and s < 0: return 1            
	if q > 0 and r > 0 and s == -radius: return 3           
	if q < 0 and r == radius and s < 0: return 5            
	if q == -radius and r > 0 and s > 0: return 7           
	if q < 0 and r < 0 and s == radius: return 9            
	if q > 0 and r == -radius and s > 0: return 11          

	return 0 

# ==========================================

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

func generate_hex_border(radius: int, center: Vector2i, tile_scene: PackedScene):
	var ring_coords = get_hex_ring(radius, center)
	for pos in ring_coords:
		var new_tile = place_tile_at(pos, tile_scene)
		
		if new_tile:
			var sprite = new_tile.get_node_or_null("Sprite2D")
			if sprite :
				if (sprite.hframes * sprite.vframes) >= 12:
					var frame_index = get_coast_frame(pos, center, radius)
					sprite.frame = frame_index
				
		await get_tree().create_timer(0.05).timeout

# --- 测试与执行 ---
func _ready():
	await get_tree().create_timer(0.1).timeout
	if not coast_scene or not lighthouse_scene or not hq_scene: 
		push_error("请在编辑器中为 MapGenerator 分配 coast, lighthouse 和 hq 场景！")
		return
		
	# 1. 寻找摄像机并初始化“上帝全景视角”
	var camera = get_tree().get_first_node_in_group("Camera")
	if camera:
		camera.can_control = false # 剥夺玩家控制权
		camera.global_position = Vector2(480, 45) # 你测试出的完美全景中心
		camera.zoom = Vector2(0.5, 0.5)           # 最大视野
		camera._target_zoom = 0.5                 # 同步内部变量防穿帮

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(true)
	
	# 给玩家 0.8 秒钟时间欣赏空旷的桌面
	await get_tree().create_timer(0.8).timeout
	
	# 2. 生成外围海岸线与灯塔（全景模式下观看生成）
	await generate_hex_border(map_radius, map_center, coast_scene)
	
	var inner_ring_coords = get_hex_ring(map_radius - 1, map_center)
	var actual_count = min(lighthouse_count, inner_ring_coords.size())
	if actual_count > 0:
		var available_coords = inner_ring_coords.duplicate()
		available_coords.shuffle() 
		for i in range(actual_count):
			place_tile_at(available_coords[i], lighthouse_scene)
			await get_tree().create_timer(0.15).timeout 
			
	# 3. 【镜头高潮】：聚焦降落 HQ
	if auto_place_hq:
		if camera:
			# 创建一个并行的缓动动画，耗时 1.5 秒
			var cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			var hq_pixel_pos = GridAutoload.grid_to_pixel(map_center)
			
			# 镜头猛地推近到 zoom 6.0，并精准对齐到 HQ 落点
			cam_tween.tween_property(camera, "zoom", Vector2(6.0, 6.0), 1.5)
			cam_tween.tween_property(camera, "global_position", hq_pixel_pos, 1.5)
			
			await cam_tween.finished # 等待镜头推到脸前
		else:
			await get_tree().create_timer(1.5).timeout 
		
		# 此时镜头已经在正中心了，砸下 HQ！
		var hq_tile = place_tile_at(map_center, hq_scene)
		
		# 精准等待 0.15 秒（这是你在 place_tile_at 里写好的地块砸地时间）
		await get_tree().create_timer(0.15).timeout 
		
		# 【附赠特效】砸地瞬间的屏幕微震！
		if camera and hq_tile:
			var shake_tween = create_tween()
			var base_pos = camera.global_position
			shake_tween.tween_property(camera, "global_position", base_pos + Vector2(0, 8), 0.05)
			shake_tween.tween_property(camera, "global_position", base_pos + Vector2(0, -8), 0.05)
			shake_tween.tween_property(camera, "global_position", base_pos, 0.05)
		
		# 欣赏一下落成的 HQ
		await get_tree().create_timer(0.8).timeout
		
		# 镜头平滑拉远到适合游玩的距离（假设正常游玩缩放是 1.5，你可以自行调整）
		if camera:
			var reset_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			reset_tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0)
			await reset_tween.finished
			
	# 统一刷新物理状态和连通性
	ConnectivityManager.update_connectivity()
	
	# 4. 演出结束，将控制权还给玩家
	if camera:
		camera._target_zoom = camera.zoom.x # 同步目标 zoom，防止镜头突然抽搐
		camera.can_control = true

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(false)
	SignalBusAutoload.game_start.emit()
	print("地图与地标生成完毕！游戏正式开始。")
