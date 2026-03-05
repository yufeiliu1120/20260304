extends PanelContainer

var current_tile: Node2D = null

@onready var btn_upgrade = $VBoxContainer/BtnUpgrade
@onready var btn_demolish = $VBoxContainer/BtnDemolish

func _ready():
	# 默认隐藏
	hide()
	# 连接信号
	SignalBusAutoload.show_tile_menu.connect(_on_show_menu)
	SignalBusAutoload.hide_tile_menu.connect(hide)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_demolish.pressed.connect(_on_demolish_pressed)

func _on_show_menu(tile: Node2D, screen_pos: Vector2):
	current_tile = tile
	global_position = screen_pos
	
	# 如果地块数据里配置了不能升级，把按钮置灰
	if current_tile.data:
		btn_upgrade.disabled = not current_tile.data.can_be_upgraded
		
	# 控制拆除按钮
		# 如果资源里没有 can_be_demolished 属性（兼容老数据），默认给 true；否则按配置来
		var can_demolish = current_tile.data.get("can_be_demolished")
		if can_demolish == null:
			can_demolish = true 
			
		btn_demolish.disabled = not can_demolish
	
	show()

func _on_demolish_pressed():
	if current_tile:
		# 1. 处理拆除返还资源
		if current_tile.data and current_tile.data.demolish_refund:
			var refund = current_tile.data.demolish_refund
			var gave_refund = false
			for res in refund.keys():
				if refund[res] > 0:
					GameResourceManager.stocks[res] += refund[res]
					gave_refund = true
			# 如果真的给了资源，通知 UI 刷新顶部的库存显示
			if gave_refund:
				GameResourceManager.resources_changed.emit(GameResourceManager.stocks)
		
		# 2. 从全局网格中移除该地块的数据
		GridAutoload.unregister_tile(current_tile.grid_coordinate)
		# 3. 彻底销毁节点
		current_tile.queue_free()
		current_tile = null
		
		# 4. 关键：地块消失后，可能导致有些建筑断路，必须立刻刷新全局连通性
		ConnectivityManager.update_connectivity()
		
	# 关掉菜单
	hide()

func _on_upgrade_pressed():
	# 这里后续实现改造逻辑
	print("点击了改造！")
	hide()
