@tool
@icon("res://Assets/icons/flag-solid-full.svg")
extends Area2D
class_name Checkpoint

@export_group("Camera")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Activate Camera") var activate_camera: bool = true : set = set_activate_camera
@export var tween_duration: float = 1.0

@onready var phantom_camera: BorderedCamera = %PhantomCamera2D
@onready var anim_player: AnimationPlayer = %AnimationPlayer

var id: int = 0
var active: bool = false


signal checkpoint_reached(checkpoint: Checkpoint, checkpoint_pos: Vector2)

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)
    if not phantom_camera:
        phantom_camera = %PhantomCamera2D
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
        # 播放激活動畫
        anim_player.play("Activated")

# 設定 PhantomCamera2D 的優先級
func set_camera_priority(priority_value: int, should_tween: bool = true) -> void:
    if phantom_camera:
        if should_tween:
            phantom_camera.set_tween_duration(tween_duration)
        else:
            phantom_camera.set_tween_duration(0)
        # 設置當前相機的優先級
        phantom_camera.priority = priority_value


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
