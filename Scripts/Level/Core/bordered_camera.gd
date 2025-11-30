@tool
class_name BorderedCamera
extends PhantomCamera2D

@onready var camera_border: CollisionShape2D = %CameraBorder

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)

func set_border(border: CollisionShape2D) -> void:
    set_limit_target(border.get_path())
