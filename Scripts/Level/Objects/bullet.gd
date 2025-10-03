# Bullet.gd
# 子彈類別，包含傷害區域
extends CharacterBody2D
class_name Bullet

# 子彈屬性
@export var speed: float = 500.0
@export var lifetime: float = 3.0
@export var damage: int = 1

# 傷害區域
@onready var damage_area: DamageArea = %DamageArea



# 計時器
var _lifetime_timer: float = 0.0

    
func _physics_process(delta: float) -> void:
    # 更新生命週期計時器
    _lifetime_timer += delta
    
    # 檢查是否超過生命週期
    if _lifetime_timer >= lifetime or velocity.length() < 0.1:
        _destroy_bullet()
    move_and_slide()

func shoot(direction: Vector2) -> void:
    """發射子彈"""
    # 設置初始速度
    velocity = direction.normalized() * speed
    # 旋轉子彈朝向移動方向
    rotation = direction.angle()

func _on_player_died(player: Player) -> void:
    """當玩家死亡時銷毀子彈"""
    _destroy_bullet()

func _destroy_bullet() -> void:
    """銷毀子彈"""
    queue_free()

func _on_body_entered(body: Node2D) -> void:
    """當子彈碰撞到其他物體時"""
    _destroy_bullet()
