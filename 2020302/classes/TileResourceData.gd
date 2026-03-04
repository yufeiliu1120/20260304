extends Resource
class_name TileResourceData

@export_group("Identity")
@export var tile_name: String = "Unknown Tile"
@export var icon: Texture2D

@export_group("Economics")
## 每回合产出的资源（木头、石头、探险家、钢铁）
@export var production: Dictionary = {
	"wood": 0,
	"stone": 0,
	"explorer": 0,
	"iron": 0
}
## 每回合产出的食物（单独列出，因为它是核心限制）
@export var food_production: int = 0
## 每回合消耗的食物（维护费）
@export var food_maintenance: int = 0
## 升级/改造此地块所需的资源
@export var upgrade_cost: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0
}
@export var can_be_upgraded:bool

@export_group("Logic")
## 是否必须连接道路才能工作
@export var requires_road: bool = true
## 是否可以作为物流锚点（重置建造成本）
@export var is_anchor: bool = false
## 升级后的目标数据（用于改造系统）
@export var upgrade_to: TileResourceData
