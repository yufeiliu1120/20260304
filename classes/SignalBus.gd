extends Node
class_name SignalBus

# 现有的提示信号
signal update_cost_preview(status: int, penalty: Dictionary, is_visible: bool)

# 右键菜单信号
# tile: 传递被点击的地块节点本身； screen_pos: 传递鼠标在屏幕上的位置
signal show_tile_menu(tile: Node2D, screen_pos: Vector2)
signal hide_tile_menu()

# 当地图的连通性或状态发生重大改变时触发
signal map_state_changed()
# 游戏胜利时触发，用于 UI 弹出结算画面
signal game_won(message: String)
#开场动画结束时，触发这个信号
signal game_start()
