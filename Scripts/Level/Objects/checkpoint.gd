@tool
@icon("res://Assets/icons/flag-solid-full.svg")
extends Area2D
class_name Checkpoint

@export var activate_camera: bool = true : set = set_activate_camera
@onready var phantom_camera: PhantomCamera2D = %PhantomCamera2D
var active: bool = false

signal checkpoint_reached(checkpoint: Checkpoint, checkpoint_pos: Vector2)

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)
    add_to_group("checkpoints")
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if active:
        print("檢查點已激活!")
        return
    if body is Player:
        active = true
        print("通過檢查點!") 
        checkpoint_reached.emit(self, self.global_position)

# 設定 PhantomCamera2D 的可見性
func set_camera_visible(should_show: bool) -> void:
    if phantom_camera:
        phantom_camera.visible = should_show

# 獲取 PhantomCamera2D 的可見性
func is_camera_visible() -> bool:
    if phantom_camera:
        return phantom_camera.visible
    return false

# 獲取 PhantomCamera2D 節點
func get_phantom_camera() -> PhantomCamera2D:
    return phantom_camera

# 設定 activate_camera 並同時設定相機可見性
func set_activate_camera(value: bool) -> void:
    activate_camera = value
    if phantom_camera:
        phantom_camera.visible = value
