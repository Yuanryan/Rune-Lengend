@icon("res://Assets/icons/box-solid-full.svg")
extends CharacterBody2D
class_name Box


var size_scale : Vector2 = Vector2(1.0, 1.0) : set = set_size_scale
## 推動力係數（相對於玩家速度）
@export var push_force: float = 0.8  
## 摩擦力，讓箱子逐漸停下 
@export var friction: float = 0.95     

@onready var polygon = %Polygon2D
@onready var collision_polygon = %CollisionPolygon2D
@onready var visible_on_screen : VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var is_pushing: bool = false
var push_direction: Vector2 = Vector2.ZERO
var is_on_screen: bool = true
# 玩家在本物理幀回報的推動（由 Player 呼叫 push() 設定）
var _pending_push_velocity_x: float = 0.0
var _has_pending_push: bool = false

func _ready():
    set_size_scale(size_scale)
    # 加入 Interactive 群組，讓按鈕能偵測到
    add_to_group("Interactive")
    visible_on_screen.screen_entered.connect(func(): is_on_screen = true)
    visible_on_screen.screen_exited.connect(func(): is_on_screen = false)
    is_on_screen = visible_on_screen.is_on_screen()

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_screen:
        return
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
    
    # 套用玩家回報的推動；沒有推動時套用摩擦力
    if _has_pending_push:
        velocity.x = _pending_push_velocity_x
        _has_pending_push = false
    else:
        is_pushing = false
        push_direction = Vector2.ZERO
        _apply_friction()
    move_and_slide()

func push(player: Player, player_velocity_x: float, collision_normal: Vector2) -> void:
    """由 Player 在 move_and_slide 撞到箱子後呼叫。
    箱子的 collision_mask 不含 Player 層，所以箱子自己偵測不到玩家，
    也不會被玩家的碰撞分離（depenetration）慢慢擠動。"""
    # 只有人可以推箱子
    if not player.animal_component.current_animal is Man:
        return
    # 只接受從側面推（normal 指向玩家，水平分量要夠大）
    if abs(collision_normal.x) < 0.7:
        return
    # 玩家必須朝箱子移動（速度與 normal 反向）
    if player_velocity_x * collision_normal.x >= 0:
        return

    is_pushing = true
    push_direction = Vector2(sign(player_velocity_x), 0)
    # 箱子速度略慢於玩家，讓玩家持續貼著箱子
    _pending_push_velocity_x = player_velocity_x * push_force
    _has_pending_push = true
    _on_box_pushed()

func _apply_friction():
    """應用摩擦力"""
    if is_on_floor():
        velocity.x *= friction
        # 當速度很小時停止


func _on_box_pushed():
    """箱子被推動時的回調"""
    # 在這裡可以添加推動箱子時的效果
    # 例如：音效、粒子效果等
    pass


func get_push_state() -> Dictionary:
    """獲取推動狀態信息"""
    return {
        "is_pushing": is_pushing,
        "push_direction": push_direction,
        "velocity": velocity
    }

func set_push_force(force: float) -> void:
    """設置推動力大小"""
    push_force = force

func set_friction(friction_value: float) -> void:
    """設置摩擦力"""
    friction = clamp(friction_value, 0.0, 1.0)

func set_size_scale(value: Vector2) -> void:
    if not is_node_ready():
        await ready
    size_scale = value
    polygon.scale = value
    collision_polygon.scale = value
