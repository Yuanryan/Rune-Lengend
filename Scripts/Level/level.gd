# Level.gd
# 關卡類別，負責管理關卡狀態和玩家生成
@tool
extends Node2D
class_name Level

@export var level_resource: LevelResource = null
@onready var starting_point: Marker2D = $StartingPoint

func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    
    # 檢查是否有 StartingPoint 子節點
    if not has_node("StartingPoint"):
        warnings.append("Level 缺少 Marker2D 子節點 (StartingPoint)")
    elif not get_node("StartingPoint") is Marker2D:
        warnings.append("StartingPoint 必須是 Marker2D 節點")
    
    return warnings

func _ready() -> void:
    if not starting_point:
        push_error("Level 缺少 StartingPoint 子節點")
        return
    
    # 只在非編輯器模式下生成玩家
    if not Engine.is_editor_hint():
        spawn_player()

# 在起始點生成玩家
func spawn_player() -> Player:
    if not starting_point:
        push_error("無法生成玩家：缺少 StartingPoint")
        return null
    
    # 如果已經有玩家，先移除
    GameManager.remove_player()
    
    # 實例化玩家
    var player = GameManager.player_scene.instantiate()
    player.set_available_animals(level_resource.available_animals)
    GameManager.set_player(player)
    if not player:
        push_error("無法實例化玩家場景")
        return null
    
    # 設置玩家位置
    player.global_position = starting_point.global_position
    
    # 將玩家加入場景
    add_child(player)
    return player

