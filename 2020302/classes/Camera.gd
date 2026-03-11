extends Camera2D

# --- 移动与缩放参数 ---
@export_group("Movement")
@export var speed: float = 500.0

@export_group("Zoom Settings")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_step: float = 0.2
@export var zoom_lerp_speed: float = 10.0

# --- 边界控制 ---
@export_group("Bounds Settings")
# 在编辑器中指定一个用于界定范围的节点，强烈推荐使用 ReferenceRect
@export var boundary_node: Control 

# --- 细节控制 ---
@export_group("Detail Control")
@export_range(0.0, 1.0) var detail_threshold_percent: float = 0.5
@export var start_with_details: bool = true

# 信号：当状态改变时通知所有已存在的监听者
signal detail_mode_changed(is_detailed: bool)

# 公开变量：供新加载的场景随时查询当前状态
var is_current_detailed: bool = true
var can_control: bool = true
var _target_zoom: float = 1.0

func _ready():
	_target_zoom = zoom.x
	# 初始化全局状态
	is_current_detailed = start_with_details
	# 延迟一帧发送信号，确保其他节点的 _ready 已执行
	detail_mode_changed.emit.call_deferred(is_current_detailed)

func _process(delta):
	if can_control:
		_handle_movement(delta)
		_handle_zoom(delta)
	_check_detail_level()
	_apply_bounds() #每一帧应用边界约束

func _handle_movement(delta):
	# 使用WASD控制相机的移动
	var direction = Input.get_vector("A", "D", "W", "S")
	position += direction * speed * delta * (1.0 / zoom.x)

func _handle_zoom(delta):
	var next_zoom_val = lerp(zoom.x, _target_zoom, zoom_lerp_speed * delta)
	zoom = Vector2(next_zoom_val, next_zoom_val)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom += zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom -= zoom_step
		_target_zoom = clamp(_target_zoom, min_zoom, max_zoom)

func _check_detail_level():
	var current_threshold = lerp(min_zoom, max_zoom, detail_threshold_percent)
	
	# 逻辑触发：改变时更新公开变量并发送信号
	if zoom.x > current_threshold:
		if not is_current_detailed:
			is_current_detailed = true
			detail_mode_changed.emit(true)
	else:
		if is_current_detailed:
			is_current_detailed = false
			detail_mode_changed.emit(false)

# ---边界处理核心逻辑 ---
func _apply_bounds():
	if not boundary_node:
		return

	# 1. 获取检测区域的全局矩形范围
	var rect = boundary_node.get_global_rect()
	
	# 2. 获取当前游戏窗口/视野的尺寸
	var viewport_size = get_viewport_rect().size
	
	# 3. 计算在当前缩放比例下，相机实际覆盖的物理尺寸
	# 举例：如果视野是 1920x1080，zoom 是 0.5，那么实际看到的范围是 3840x2160
	var view_size_scaled = viewport_size / zoom
	
	# 4. 计算相机的合法活动区间（中心点）
	var margin_x = view_size_scaled.x / 2.0
	var margin_y = view_size_scaled.y / 2.0
	
	var min_x = rect.position.x + margin_x
	var max_x = rect.end.x - margin_x
	var min_y = rect.position.y + margin_y
	var max_y = rect.end.y - margin_y
	
	# 5. 应用限制，并处理视野大于整个地图的极端情况
	if min_x > max_x:
		# 如果视野太宽，把相机锁在地图水平中心
		position.x = rect.position.x + rect.size.x / 2.0
	else:
		position.x = clamp(position.x, min_x, max_x)
		
	if min_y > max_y:
		# 如果视野太高，把相机锁在地图垂直中心
		position.y = rect.position.y + rect.size.y / 2.0
	else:
		position.y = clamp(position.y, min_y, max_y)
