extends Control
class_name ResourceBarUI
@onready var label = $VBoxContainer/HBoxContainer/ResourceLabel

func _ready():
	# 监听资源变化信号
	GameResourceManager.resources_changed.connect(_on_resources_updated)
	# 初始化显示
	_on_resources_updated(GameResourceManager.stocks)

func _on_resources_updated(stocks):
	var text = "食物: %d | 木头: %d | 石头: %d | 探险家: %d" % [
		stocks["food"], stocks["wood"], stocks["stone"], stocks["explorer"]
	]
	label.text = text
