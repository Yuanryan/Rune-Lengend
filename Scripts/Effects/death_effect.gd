# Scripts/Effects/death_effect.gd
extends Sprite2D
class_name DeathEffect

var _frame_timer: float = 0.0
var _current_frame: int = 0

# Export 參數，可在 Inspector 調整
@export var texture_sheet: Texture2D = null
@export var frame_duration: float = 0.1  # 每幀持續時間
@export var scale_factor: float = 2.0  # 縮放倍率，預設與 DoubleJumpEffect 一致
@export var sfx: AudioStream = null
@export var shake_amplitude: float = 0.3  # 相機震動強度（輕微）
@export var shake_duration: float = 0.15  # 相機震動時長（秒）

func _ready() -> void:
    # 如果有指定貼圖，使用它
    if texture_sheet:
        texture = texture_sheet
    
    # 設定縮放
    scale = Vector2(scale_factor, scale_factor)
    
    frame = 0
    _current_frame = 0
    
    # 播放音效
    if MusicManager and sfx:
        MusicManager.play_sound_stream(sfx)
    
    # 觸發相機震動（如果有 noise_emitter）
    _trigger_camera_shake()

func _trigger_camera_shake() -> void:
    """觸發相機震動"""
    var player = GameManager.get_player()
    if not player:
        return
    
    var noise_emitter = player.get_node_or_null("PhantomCameraNoiseEmitter2D")
    if not noise_emitter:
        return
    
    # 保存原始參數
    var original_duration = noise_emitter.duration
    var original_amplitude = 10.0  # 預設值
    if noise_emitter.noise:
        original_amplitude = noise_emitter.noise.amplitude
    
    # 設定震動參數
    noise_emitter.duration = shake_duration
    if noise_emitter.noise:
        noise_emitter.noise.amplitude = shake_amplitude * 10.0  # 轉換為實際振幅值（amplitude 範圍通常是 0-1000）
    
    # 觸發震動
    noise_emitter.emit()
    
    # 恢復原始參數（在震動結束後）
    await get_tree().create_timer(shake_duration).timeout
    noise_emitter.duration = original_duration
    if noise_emitter.noise:
        noise_emitter.noise.amplitude = original_amplitude

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
    visible = false  # 立即隱藏
    set_process(false)  # 停止處理
    # 音效由 MusicManager 管理，會自動清理，無需等待
    queue_free()  # 移除節點

