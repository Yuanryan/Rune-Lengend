extends Area2D
class_name Checkpoint

@export var checkpoint_id: int = 0
@export var camera_target_position: Vector2 = Vector2.ZERO
var active: bool = false

signal checkpoint_reached(checkpoint_id, camera_target_position, checkpoint_pos)

func _ready() -> void:
    add_to_group("checkpoints")
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if active:
        return
    if body is Player:
        active = true
        print("通過檢查點!") 
        checkpoint_reached.emit(checkpoint_id, camera_target_position, self.global_position)
