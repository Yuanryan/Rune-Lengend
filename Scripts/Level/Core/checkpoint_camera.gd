@tool
extends PhantomCamera2D
class_name CheckpointCamera


@onready var border: CollisionShape2D = %Border

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)