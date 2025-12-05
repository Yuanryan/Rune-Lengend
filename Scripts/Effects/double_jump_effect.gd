# Scripts/Effects/double_jump_effect.gd
extends Sprite2D
class_name DoubleJumpEffect

var _frame_timer: float = 0.0
var _frame_duration: float = 0.1  # 每幀持續時間
var _current_frame: int = 0

@export var sfx: AudioStream = null
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
    frame = 0
    _current_frame = 0
    if sfx:
        _sfx_player = AudioStreamPlayer.new()
        _sfx_player.stream = sfx
        add_child(_sfx_player)
        _sfx_player.play()

func _process(delta: float) -> void:
    _frame_timer += delta
    if _frame_timer >= _frame_duration:
        _frame_timer = 0.0
        _current_frame += 1
        if _current_frame >= hframes:
            _finish_and_free()
            return
        frame = _current_frame

func _finish_and_free() -> void:
    visible = false  # 立即隱藏
    set_process(false)  # 停止處理
    if _sfx_player and _sfx_player.playing:
        await _sfx_player.finished
    queue_free()  # 移除節點
