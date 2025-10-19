extends ContinuousAction
class_name MoveAction

@export var velocity_x: float = 0.0
var direction: float = 0.0

func _init(dir := 0.0, _name := "Move") -> void:
    direction = dir
    name = _name

func set_velocity_x(new_velocity_x: float) -> void:
    velocity_x = new_velocity_x

func start(player: CharacterBody2D) -> void:
    player.velocity.x = velocity_x
    
    # 根據移動方向設置面向方向
    if direction > 0:
        player.set_facing_direction(Vector2.RIGHT)
    elif direction < 0:
        player.set_facing_direction(Vector2.LEFT)
    
func update(player: CharacterBody2D, delta: float) -> bool:
    player.velocity.x = velocity_x
    return false

# 中斷時停止移動
func interrupt(player: CharacterBody2D) -> void:
    player.velocity.x = 0.0
    player.animal_component.stop_animation()
