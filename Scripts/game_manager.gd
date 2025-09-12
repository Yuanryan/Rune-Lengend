# GameManager.gd
# 遊戲管理器單例，用於管理全域遊戲狀態和玩家引用

extends Node

# 玩家引用
var player: Player = null

# 初始化函數
func _ready() -> void:
	print("GameManager 已初始化")

# 設置玩家引用
func set_player(player_ref: Player) -> void:
	player = player_ref

# 獲取玩家引用
func get_player() -> Player:
	return player

# 檢查玩家是否存在
func has_player() -> bool:
	return player != null
