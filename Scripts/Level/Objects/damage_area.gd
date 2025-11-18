@tool
# DamageArea.gd
# 傷害區域基礎類別，當玩家觸碰時會導致玩家死亡
extends Area2D
class_name DamageArea

# 信號
signal player_died(player: Player)

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true) 
    else:
        body_entered.connect(_on_body_entered)
    

func _on_body_entered(body: Node2D) -> void:
    # 檢查是否為玩家
    if body is Player:
        var player = body as Player
        
        # 發出玩家死亡信號
        player_died.emit(player)
        
        # 處理玩家死亡
        _handle_player_death(player)

func _handle_player_death(player: Player) -> void:
    """處理玩家死亡邏輯"""
    # 直接調用玩家的死亡方法
    player.die()
