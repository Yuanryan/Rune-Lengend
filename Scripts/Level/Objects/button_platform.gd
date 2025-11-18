@tool
# ButtonPlatform.gd
# 按鈕平台類別，可以通過按鈕控制開關
extends LandTool
class_name ButtonPlatform

signal button_platform_moved_to_target
signal button_platform_moved_to_original

@export_tool_button("Toggle Move", "BackBufferCopy") var toggle_platform = func(): if is_at_target or is_moving_to_target: move_to_original() else: move_to_target()
## 平台移動持續時間
@export var moved_duration: float = 3.0  
## 平台原始位置
@export var original_position: Vector2 = Vector2.ZERO
## 平台移動後的位置
@export var moved_position: Vector2 = Vector2.ZERO
## 開關動畫速度
@export var animation_speed: float = 2.0  

@onready var button: GameButton = %GameButton
@onready var timer: Timer = %PlatformTimer
@onready var platform_polygon: Polygon2D = %Polygon2D
@onready var platform_collision: CollisionPolygon2D = _find_platform_collision()

var is_at_target: bool = false
var is_moving_to_target: bool = false
var is_moving_to_original: bool = false

func _ready() -> void:

    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)
    else:
        # 確保平台的碰撞元件存在
        if platform_collision == null:
            platform_collision = _find_platform_collision()
        
        # 如果未設置原始位置，使用當前位置
        if original_position == Vector2.ZERO and platform_polygon:
            original_position = platform_polygon.position
        else:
            platform_collision.position = original_position
            platform_polygon.position = original_position
            
        # 如果未設置移動位置，使用原始位置（不移動）
        if moved_position == Vector2.ZERO:
            moved_position = original_position
        
        add_to_group("button_platforms")

        # 連接按鈕信號
        if button:
            button.button_pressed.connect(_on_button_pressed)
            button.button_released.connect(_on_button_released)
        # 設置計時器等待時間並連接信號
        timer.wait_time = moved_duration
        timer.timeout.connect(_on_timer_timeout)

        # 連接 GameManager 的狀態變化信號
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _find_platform_collision() -> CollisionPolygon2D:
    """尋找平台的碰撞元件"""
    for child in get_children():
        if child is CollisionPolygon2D:
            return child
    return null 

func _on_button_pressed() -> void:
    """當按鈕被按下時"""
    if not is_at_target:
        move_to_target()

func _on_button_released() -> void:
    """當按鈕被釋放時"""
    # 如果平台在目標位置或正在移動到目標位置，立即開始計時返回
    if (is_at_target or is_moving_to_target) and not is_moving_to_original:
        start_return_timer()

func move_to_target() -> void:
    """移動平台到目標位置"""
    if is_at_target:
        return

    is_moving_to_target = true
    
    # 停止返回計時器
    if timer.is_stopped() == false:
        timer.stop()
        
    # 播放移動動畫
    var tween = create_tween()
    tween.parallel().tween_property(platform_polygon, "position", moved_position, 1.0 / animation_speed)
    tween.parallel().tween_property(platform_collision, "position", moved_position, 1.0 / animation_speed)
    tween.tween_callback(_on_platform_moved_to_target)

func _on_platform_moved_to_target() -> void:
    """平台移動到目標位置完成"""
    is_moving_to_target = false
    is_at_target = true
    button_platform_moved_to_target.emit()

func start_return_timer() -> void:
    """開始返回計時器"""
    if timer.is_stopped():
        timer.start()

func _on_timer_timeout() -> void:
    """計時器超時，移動平台回原始位置"""
    if is_at_target and not is_moving_to_original and not is_moving_to_target:
        move_to_original()

func move_to_original() -> void:
    """移動平台回原始位置"""
    if is_moving_to_original or not is_at_target:
        return
    
    is_moving_to_original = true
        
    # 播放移動動畫
    var tween = create_tween()
    tween.parallel().tween_property(platform_polygon, "position", original_position, 1.0 / animation_speed)
    tween.parallel().tween_property(platform_collision, "position", original_position, 1.0 / animation_speed)
    tween.tween_callback(_on_platform_moved_to_original)
        
func _on_platform_moved_to_original() -> void:
    """平台移動回原始位置完成"""
    is_moving_to_original = false
    is_at_target = false
    button_platform_moved_to_original.emit()

func get_platform_state() -> bool:
    """獲取平台的當前狀態"""
    return is_at_target

func force_move_to_target() -> void:
    """強制移動平台到目標位置"""
    if not is_at_target:
        var offset = platform_collision.position - platform_polygon.position
        platform_polygon.position = moved_position
        platform_collision.position = moved_position + offset
        is_at_target = true
        button_platform_moved_to_target.emit()

func force_move_to_original() -> void:
    """強制移動平台回原始位置"""
    if is_at_target:
        var offset = platform_collision.position - platform_polygon.position
        platform_polygon.position = original_position
        platform_collision.position = original_position + offset
        is_at_target = false
        button_platform_moved_to_original.emit()

func set_moved_duration(duration: float) -> void:
    """設置平台移動持續時間"""
    moved_duration = duration
    if timer:
        timer.wait_time = duration

func set_moved_position(pos: Vector2) -> void:
    """設置平台移動後的位置"""
    moved_position = pos

func set_original_position(pos: Vector2) -> void:
    """設置平台原始位置"""
    original_position = pos

func reset_platform() -> void:
    """重置平台到初始狀態"""
    # 停止所有動畫和計時器
    if timer:
        timer.stop()
    
    # 重置狀態
    is_at_target = false
    is_moving_to_target = false
    is_moving_to_original = false
    
    force_move_to_original()
    
func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    # 當進入規劃階段時重置平台（這通常發生在關卡重載時）
    if new_state == GameManager.InGameState.PLANNING:
        reset_platform()
