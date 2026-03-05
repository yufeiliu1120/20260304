extends Node
class_name SignalBus

# 现有的提示信号
signal update_cost_preview(status: int, penalty: Dictionary, is_visible: bool)

# 【新增】右键菜单信号
# tile: 传递被点击的地块节点本身； screen_pos: 传递鼠标在屏幕上的位置
signal show_tile_menu(tile: Node2D, screen_pos: Vector2)
signal hide_tile_menu()
