extends Sprite2D
class_name TransformEffect

@export var frame_duration: float = 0.08  # 每幀時間，可在需要時調整
@export var sfx: AudioStream = null

var _frame_timer: float = 0.0
var _current_frame: int = 0

func _ready() -> void:
    frame = 0
    _current_frame = 0
    if MusicManager and sfx:
        MusicManager.play_sound_stream(sfx)

func _process(delta: float) -> void:
    _frame_timer += delta
    if _frame_timer >= frame_duration:
        _frame_timer = 0.0
        _current_frame += 1
        if _current_frame >= hframes:
            _finish_and_free()
            return
        frame = _current_frame

func _finish_and_free() -> void:
    visible = false
    set_process(false)
    queue_free()

