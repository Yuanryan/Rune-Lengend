extends Area2D
class_name Checkpoint

@export var checkpoint_id: String = ""
@export var camera_target_position: Vector2 = Vector2.ZERO
var active: bool = false

signal checkpoint_reached(checkpoint_id, camera_target_position, checkpoint_pos)

func _ready() -> void:
    add_to_group("checkpoints")
    connect("body_entered", _on_body_entered)
    assign_id()
    print("hi")

func assign_id() -> void:
    checkpoint_id = "checkpoint_" + str(get_instance_id())
    print("Assigned Checkpoint ID: ", checkpoint_id)

func _on_body_entered(body: Node) -> void:
    if active:
        return
    if body is Player:
        active = true
        print("通過檢查點!") 
        checkpoint_reached.emit(checkpoint_id, camera_target_position, self.global_position)
