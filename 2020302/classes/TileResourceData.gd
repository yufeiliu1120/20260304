extends Resource
class_name TileResourceData

@export_group("Identity")
@export var tile_name: String = "Unknown Tile"
@export var icon: Texture2D

@export_group("Economics")
## 每回合产出的资源
@export var production: Dictionary = {
	"wood": 0, "stone": 0, "explorer": 0, "iron": 0
}
@export var food_production: int = 0
@export var food_maintenance: int = 0
@export var upgrade_cost: Dictionary = {
	"wood": 0, "stone": 0, "food": 0
}
@export var can_be_upgraded: bool
@export var upgrade_scene: PackedScene 
## 改造所需的花费
## 【新增】距离惩罚：每离总部1格，需要额外消耗的资源。全填0或留空代表不涨价。
@export var distance_penalty: Dictionary = {
	"stone": 0,
	"wood": 0
}
@export var demolish_refund: Dictionary = {
	"stone": 0,
	"wood": 0,
	"food": 0
}

@export_group("Logic")
## 是否必须连接道路才能工作/放置
@export var requires_road: bool = true
## 是否必须与现有地块相邻才能放置（海岸/灯塔等独立地块设为 false）
@export var requires_adjacency: bool = true
## 是否可以作为物流锚点（重置建造成本）
@export var is_anchor: bool = false
## 是否允许被玩家拆除（自然地块和HQ应设为 false）
@export var can_be_demolished: bool = true
