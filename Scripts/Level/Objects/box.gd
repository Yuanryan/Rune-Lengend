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

var player_ref : Player = null
var is_pushing: bool = false
var push_direction: Vector2 = Vector2.ZERO
var is_on_screen: bool = true

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
    
    # 檢測玩家推動
    _detect_player_push()
    if player_ref == null:
        _apply_friction()
    move_and_slide()

func _detect_player_push():
    """檢測玩家是否在推動箱子"""
    # 如果已經有保存的玩家引用，檢查該玩家是否仍在碰撞
    if player_ref != null:
        var current_collision_count = player_ref.get_slide_collision_count()
        var player_still_colliding = false
        
        # 檢查保存的玩家是否仍在碰撞
        for i in range(current_collision_count):
            var collision = player_ref.get_slide_collision(i)
            if collision.get_collider() == self:
                player_still_colliding = true
                break 

        if player_still_colliding and player_ref.animal_component.current_animal is Man:
            _apply_push_from_player(player_ref)
        else:
            # 玩家已離開，清除引用並應用摩擦力
            player_ref = null
            is_pushing = false
            push_direction = Vector2.ZERO
        return
    
    # 沒有保存的玩家，尋找新的玩家碰撞
    var collision_count = get_slide_collision_count()
    
    for i in range(collision_count):
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()

        # 檢查是否是玩家
        print("collider: ", collider)
        if collider is not Player:
            continue

        var player = collider as Player
        if not player.animal_component.current_animal is Man:
            continue
            
        var player_position = player.global_position
        var box_position = global_position
        
        # 計算推動方向
        var push_vector = (box_position - player_position).normalized()
        
        # 檢查是否從側面推動（不是從上方或下方）
        var push_from_side = abs(push_vector.y) < 0.5
        
        if push_from_side:
            # 保存玩家引用
            player_ref = player
            is_pushing = true
            push_direction = push_vector
            
            # 應用推動
            _apply_push_from_player(player)
            break

func _apply_push_from_player(player: Player):
    """從玩家應用推動力"""
    var player_velocity = player.velocity * push_force
    var player_position = player.global_position
    var box_position = global_position
    
    # 計算玩家相對於箱子的位置
    var relative_position = box_position - player_position
    var player_direction = sign(player_velocity.x)
    
    # 檢查推動方向是否正確（玩家必須在箱子後面推動）
    var correct_push_direction = false
    
    if player_direction > 0:  # 玩家向右移動
        # 玩家應該在箱子左邊（相對位置.x > 0）
        correct_push_direction = relative_position.x > 0
    elif player_direction < 0:  # 玩家向左移動
        # 玩家應該在箱子右邊（相對位置.x < 0）
        correct_push_direction = relative_position.x < 0
    
    if correct_push_direction and abs(player_velocity.x) > 0:
        # 推動方向正確，應用推動力
        push_direction.x = player_direction
        push_direction.y = 0
        
        # 設置箱子的速度為玩家的速度乘以推動力係數
        velocity.x = player_velocity.x
        
        # 觸發推動事件
        _on_box_pushed()
    else:
        is_pushing = false
        push_direction = Vector2.ZERO

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
