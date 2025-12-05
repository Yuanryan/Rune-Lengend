# Scripts/Effects/double_jump_effect.gd
extends Sprite2D
class_name DoubleJumpEffect

var _frame_timer: float = 0.0
var _frame_duration: float = 0.1  # 每幀持續時間
var _current_frame: int = 0

func _ready() -> void:
    frame = 0
    _current_frame = 0

func _process(delta: float) -> void:
    _frame_timer += delta
    if _frame_timer >= _frame_duration:
        _frame_timer = 0.0
        _current_frame += 1
        if _current_frame >= hframes:
            visible = false  # 立即隱藏
            set_process(false)  # 停止處理
            queue_free()  # 移除節點
            return
        frame = _current_frame
