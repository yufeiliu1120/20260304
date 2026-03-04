
extends StateMachine.State
class_name tile_dragging_base
# --- 属性定义 ---
const DRAG_SCALE = Vector2(1.1, 1.1)
const IDLE_SCALE = Vector2(1.0, 1.0)
const SHADOW_OFFSET = Vector2(0, 15)
const SHADOW_IDLE_A = 0.5
const SHADOW_DRAG_A = 0.2
const SPRITE_DEFAULT_Y = 3.0 # 基于你素材底座微调的默认位置

var state_name = "Dragging"
var original_grid_pos: Vector2i
var original_pixel_pos: Vector2
var ghost_sprite: Sprite2D 
var can_place_logical: bool = false

@onready var sprite: Sprite2D = $"../../Sprite2D"
@onready var shadow: Sprite2D = $"../../Shadow"
# --- 核心生命周期 ---

func enter() -> void:
	sprite.z_index += 1
	_save_original_state()
	_setup_visuals_on_drag(true)
	_create_ghost()
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(true)

func do(_delta: float) -> void:
	_handle_movement()
	_apply_floating_animation()
	_update_ghost_preview()
	_handle_input()
	
func exit() -> void:
	_setup_visuals_on_drag(false)
	_cleanup_ghost()
	sprite.z_index -= 1
	await get_tree().create_timer(0.5).timeout
	get_tree().get_first_node_in_group("ControlNode").set_mouse_is_dragging(false)
# --- 私有逻辑处理 ---

func _save_original_state() -> void:
	original_pixel_pos = actor.global_position
	original_grid_pos = GridAutoload.pixel_to_grid(original_pixel_pos)
	GridAutoload.unregister_tile(original_grid_pos)

func _handle_movement() -> void:
	actor.global_position = actor.get_global_mouse_position()

func _handle_input() -> void:
	if Input.is_action_just_pressed("mouse_left"):
		var target_grid = GridAutoload.pixel_to_grid(actor.global_position)
		
		if GridAutoload.can_place_tile(target_grid,actor):
			_finalize_placement(target_grid)
			
		else:
			_rollback_placement()

# --- 视觉与动画函数 ---

func _setup_visuals_on_drag(is_dragging: bool) -> void:
	var target_scale = DRAG_SCALE if is_dragging else IDLE_SCALE
	var shadow_pos = SHADOW_OFFSET if is_dragging else Vector2(5, 5)
	var shadow_alpha = SHADOW_DRAG_A if is_dragging else SHADOW_IDLE_A
	var sprite_pos = Vector2(0, SPRITE_DEFAULT_Y) if not is_dragging else sprite.position
	
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite, "scale", target_scale, 0.2)
	
	if shadow:
		tween.tween_property(shadow, "position", shadow_pos, 0.2)
		tween.tween_property(shadow, "modulate:a", shadow_alpha, 0.2)
	
	if not is_dragging:
		tween.tween_property(sprite, "position", sprite_pos, 0.2)
		if shadow: tween.tween_property(shadow, "scale", Vector2.ONE, 0.2)

func _apply_floating_animation() -> void:
	var time = Time.get_ticks_msec() * 0.001
	var bobbing = sin(time * 3.0) * 3.0
	var swaying = cos(time * 2.0) * 1.5
	
	sprite.position = Vector2(swaying, bobbing + SPRITE_DEFAULT_Y)
	if shadow:
		shadow.scale = IDLE_SCALE * (1.0 + bobbing * 0.02)
# --- 虚影与放置逻辑 ---

func _create_ghost() -> void:
	ghost_sprite = sprite.duplicate()
	actor.get_parent().add_child(ghost_sprite)
	ghost_sprite.z_index = -1
	ghost_sprite.modulate = Color(1, 1, 1, 0.3)

func _update_ghost_preview() -> void:
	var target_grid = GridAutoload.pixel_to_grid(actor.global_position)
	
	# 将 actor 传入，以便进行 get_overlapping_areas 检测
	var can_place = GridAutoload.can_place_tile(target_grid, actor)
	
	ghost_sprite.global_position = GridAutoload.grid_to_pixel(target_grid)
	
	if can_place:
		ghost_sprite.visible = true
		ghost_sprite.modulate = Color(0.5, 1.0, 0.5, 0.4) # 绿色：可以放
	else:
		# 如果不在区域内，我们可以让虚影更透明或者变红
		ghost_sprite.visible = true
		ghost_sprite.modulate = Color(1.0, 0.3, 0.3, 0.2) # 浅红色：禁止


func _finalize_placement(grid_pos: Vector2i) -> void:
	actor.grid_coordinate = grid_pos
	var target_pos = GridAutoload.grid_to_pixel(grid_pos)
	var tween = create_tween()
	tween.tween_property(actor, "global_position", target_pos, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(0.07).timeout.connect(_play_dust_effect)
	GridAutoload.register_tile(grid_pos, actor)
	actor.update_connections()
	state_finished.emit("Idle")


func _play_dust_effect() -> void:
	var dust = actor.get_node_or_null("DustParticles")
	if dust:
		# 强制让粒子瞬间爆发
		dust.emitting = false # 先重置
		dust.restart()
		dust.emitting = true
	# 增加一个瞬间的“压扁”反馈
	var impact_tween = create_tween()
	# 瞬间压扁
	impact_tween.tween_property(sprite, "scale", Vector2(1.1, 0.8), 0.05)
	# 快速回弹到标准大小
	impact_tween.tween_property(sprite, "scale", IDLE_SCALE, 0.1)
	
func _rollback_placement() -> void:
	var tween = create_tween()
	tween.tween_property(actor, "global_position", original_pixel_pos, 0.3).set_trans(Tween.TRANS_CUBIC)
	GridAutoload.register_tile(original_grid_pos, actor)
	state_finished.emit("Idle")

func _cleanup_ghost() -> void:
	if is_instance_valid(ghost_sprite):
		ghost_sprite.queue_free()
		

		
