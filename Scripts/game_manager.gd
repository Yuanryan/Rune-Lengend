# GameManager.gd
# 遊戲管理器單例，用於管理全域遊戲狀態和玩家引用

extends Node

# 玩家引用
var player: Player = null
# 當前關卡引用
var current_level: Level = null
# 玩家場景資源
const player_scene: PackedScene = preload("uid://cviyl35yedewi")

func _ready() -> void:
    load_level(preload("uid://dqtphadkel0dl"))

# 載入關卡
func load_level(level_scene: PackedScene) -> Level:
    # 清除當前關卡
    if current_level:
        current_level.queue_free()
        current_level = null
        player = null
    
    # 載入新關卡
    current_level = level_scene.instantiate()
    if not current_level:
        push_error("無法載入關卡場景")
        return null
    
    # 將關卡加入場景樹
    get_tree().current_scene.add_child(current_level)
    
    # 生成玩家
    if player_scene :
        player = current_level.spawn_player(player_scene)
    
    print("關卡已載入: ", current_level.name)
    return current_level

# 設置玩家引用
func set_player(player_ref: Player) -> void:
    player = player_ref

# 獲取玩家引用
func get_player() -> Player:
    return player

# 獲取當前關卡
func get_current_level() -> Level:
    return current_level

# 檢查玩家是否存在
func has_player() -> bool:
    return player != null

# 檢查關卡是否已載入
func has_level() -> bool:
    return current_level != null
