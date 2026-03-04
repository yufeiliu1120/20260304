extends Area2D
class_name TileBase
# --- 用来确定距离HQ的距离 ---
var distance_to_source: int = 999
@onready var Statemachine:StateMachine = $Statemachine
# --- 属性暴露 ---
@export_group("Economics")
@export var data: TileResourceData:
	set(value):
		data = value
		_update_visual_status() # 数据变化时刷新视觉

@export_group("Status")
@export var is_active: bool = true:
	set(value):
		is_active = value
		_update_visual_status()

var is_connected: bool = false:
	set(value):
		is_connected = value
		_update_visual_status()

# --- 内部变量 ---
var grid_coordinate: Vector2i = Vector2i(-999, -999)
var connected_tiles: Array[Node] = []

# --- 核心逻辑 ---

func _ready():
	if get_parent():
		get_parent().y_sort_enabled = true
	snap_to_nearest_grid()
	
	# 连接输入信号
	input_pickable = true
	input_event.connect(_on_tile_input_event)

func snap_to_nearest_grid():
	var grid_coord = GridAutoload.pixel_to_grid(global_position)
	global_position = GridAutoload.grid_to_pixel(grid_coord)

func update_connections():
	connected_tiles.clear()
	var neighbors = GridAutoload.get_neighbors(grid_coordinate)
	for n_pos in neighbors:
		if GridAutoload.active_tiles.has(n_pos):
			var neighbor_node = GridAutoload.active_tiles[n_pos]
			connected_tiles.append(neighbor_node)
			if not neighbor_node.connected_tiles.has(self):
				neighbor_node.connected_tiles.append(self)

func is_working() -> bool:
	# 如果没有 data，默认不工作或根据需求调整
	if not data: return false
	if not is_active: return false 
	if data.requires_road and not is_connected: return false 
	return true

func _update_visual_status():
	# 确保在节点进入场景树后才执行（防止初始化时报错）
	if not is_inside_tree(): return
	
	if is_working():
		modulate = Color(1, 1, 1) 
	else:
		# 变灰暗并带一点透明度，增强“停工”感
		modulate = Color(0.4, 0.4, 0.4, 0.8) 

# --- 交互逻辑 ---

func _on_tile_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# 右键点击弹出菜单
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 这里假设你有一个状态机实例在 Actor 上，或者全局判断
			# 我们暂定在全局单例里判断当前是否处于可操作状态
			_try_open_context_menu()

func _try_open_context_menu():
	# 这里后续会连接到 UI 层
	# 例如：SignalBus.show_context_menu.emit(self, get_global_mouse_position())
	print("右键点击了地块: ", data.tile_name if data else "无数据")
