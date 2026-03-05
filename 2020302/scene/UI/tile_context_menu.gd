extends PanelContainer

var current_tile: Node2D = null

@onready var btn_upgrade = $VBoxContainer/BtnUpgrade
@onready var btn_demolish = $VBoxContainer/BtnDemolish

func _ready():
	hide()
	SignalBusAutoload.show_tile_menu.connect(_on_show_menu)
	SignalBusAutoload.hide_tile_menu.connect(hide)
	
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_demolish.pressed.connect(_on_demolish_pressed)

func _on_show_menu(tile: Node2D, screen_pos: Vector2):
	current_tile = tile
	global_position = screen_pos
	
	if current_tile.data:
		# 1. 控制改造按钮状态
		var can_upgrade = current_tile.data.can_be_upgraded and current_tile.data.get("upgrade_scene") != null
		# 如果钱不够，改造按钮也会变灰
		if can_upgrade and not GameResourceManager.can_afford(current_tile.data.upgrade_cost):
			can_upgrade = false
		btn_upgrade.disabled = not can_upgrade
		
		# 2. 控制拆除按钮状态
		var can_demolish = current_tile.data.get("can_be_demolished")
		if can_demolish == null:
			can_demolish = true 
		btn_demolish.disabled = not can_demolish
	
	show()

func _on_upgrade_pressed():
	if current_tile and current_tile.data:
		var cost = current_tile.data.upgrade_cost
		var upgrade_scene = current_tile.data.get("upgrade_scene")
		
		# 再次确认资源和场景
		if upgrade_scene and GameResourceManager.can_afford(cost):
			# 1. 扣除改造费用
			GameResourceManager.consume_resources(cost)
			
			# 2. 记录旧地块的关键信息
			var grid_pos = current_tile.grid_coordinate
			var pixel_pos = current_tile.global_position
			
			# 3. 实例化新地块（如伐木场）并继承位置
			var new_tile = upgrade_scene.instantiate()
			new_tile.grid_coordinate = grid_pos
			new_tile.global_position = pixel_pos
			new_tile.distance_to_source = 999 # 默认设为未连通，交由后续刷新
			
			# 4. 加入场景树
			var storage = get_tree().get_first_node_in_group("TileStorage")
			if storage:
				storage.add_child(new_tile)
			else:
				current_tile.get_parent().add_child(new_tile)
				
			# 5. 在全局网格中替换掉旧地块
			GridAutoload.active_tiles[grid_pos] = new_tile
			
			# 6. 强制新地块进入 Idle 状态（避免它变成跟随鼠标的 Dragging 状态）
			#if new_tile.get_node_or_null("Statemachine"):
				#new_tile.Statemachine.transition_to("Idle")
			
			# 让新地块认识周围邻居
			new_tile.update_connections()
			
			# 7. 销毁旧地块（如森林）
			current_tile.queue_free()
			current_tile = null
			
			# 8. 【核心】刷新全图连通性！
			# 这一步会自动探测新的伐木场周围有没有路。
			# 如果没路，它的 is_connected 会被设为 false，然后立刻变灰！
			ConnectivityManager.update_connectivity()
			
			# 播放一个小动效，庆祝改造成功
			_play_upgrade_effect(new_tile)
			
	hide()

func _on_demolish_pressed():
	# ... (保留你原有的拆除逻辑不变) ...
	if current_tile:
		if current_tile.data and current_tile.data.demolish_refund:
			var refund = current_tile.data.demolish_refund
			var gave_refund = false
			for res in refund.keys():
				if refund[res] > 0:
					GameResourceManager.stocks[res] += refund[res]
					gave_refund = true
			if gave_refund:
				GameResourceManager.resources_changed.emit(GameResourceManager.stocks)
		
		GridAutoload.unregister_tile(current_tile.grid_coordinate)
		current_tile.queue_free()
		current_tile = null
		ConnectivityManager.update_connectivity()
		
	hide()

# 新增：改造成功的 Q弹小反馈
func _play_upgrade_effect(tile: Node2D):
	var sprite = tile.get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE)
	# 如果有粉尘粒子，也可以顺便激活一下
	var dust = tile.get_node_or_null("DustParticles")
	if dust:
		dust.restart()
		dust.emitting = true
