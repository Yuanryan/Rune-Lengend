@tool
extends Path2D

@export var movable: bool = false : set = set_movable

## 動畫時間 (秒)
@export var loop_time: float = 2.0 : set = set_loop_time

## 移動速度倍率
@export var speed_scale: float = 1.0 : set = set_speed_scale

## 是否自動開始移動
@export var auto_start: bool = true

## 是否循環播放(Path2D 的頭尾相連時使用)
@export var loop: bool = false : set = set_loop

## 延遲開始時間 (秒)
@export var start_delay: float = 0.0


# 移動平台本體節點
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready():
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true) 

    # 等待下一幀確保所有子節點都已準備好
    await get_tree().process_frame
    
    # 確保 AnimationPlayer 存在
    if not animation_player:
        animation_player = get_node("%AnimationPlayer")
    
    set_loop_time(loop_time)
    set_loop(loop)
    set_speed_scale(speed_scale)
    
    # 處理延遲和自動開始
    if start_delay > 0 and is_inside_tree():
        await get_tree().create_timer(start_delay).timeout
    
    if auto_start:
        start_movement()

# 開始移動
func start_movement():
    if animation_player and movable:
        animation_player.play("move")

# 停止移動
func stop_movement():
    if animation_player:
        animation_player.stop()

# 暫停移動
func pause_movement():
    if animation_player:
        animation_player.pause()

# 恢復移動
func resume_movement():
    if animation_player:
        animation_player.play()

# 設定速度倍率
func set_speed_scale(new_speed_scale: float):
    speed_scale = new_speed_scale
    if animation_player:
        animation_player.speed_scale = speed_scale
        start_movement()

# 設定循環模式
func set_loop(new_loop: bool):
    loop = new_loop
    if animation_player and animation_player.has_animation("move"):
        var move_animation = animation_player.get_animation("move")
        move_animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_PINGPONG
        # 設定緩動
        var easing = 1.0 if loop else -1.56
        move_animation.track_set_key_transition(0, 0, easing)
        move_animation.track_set_key_transition(0, 1, easing)
        start_movement()

# 設定動畫時間
func set_loop_time(new_loop_time: float):
    loop_time = new_loop_time
    if animation_player and animation_player.has_animation("move"):
        var move_animation = animation_player.get_animation("move")
        move_animation.length = loop_time
        # 更新第二個關鍵幀的時間
        move_animation.track_set_key_time(0, 1, loop_time)
        start_movement()

# 設定可移動狀態
func set_movable(new_movable: bool):
    movable = new_movable
    if movable:
        start_movement()
    else:
        stop_movement()
