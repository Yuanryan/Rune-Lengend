@tool
# Door.gd
# 門類別，可以通過按鈕控制開關
extends StaticBody2D
class_name Door

signal door_opened
signal door_closed

@export var door_id: int = 0
@export var open_duration: float = 3.0  # 門開啟持續時間
@export var open_height: float = 64.0  # 門開啟的高度
@export var animation_speed: float = 2.0  # 開關動畫速度

var is_open: bool = false
var is_opening: bool = false
var is_closing: bool = false
@onready var button: GameButton = %GameButton
@onready var timer: Timer = %DoorTimer
@onready var door_sprite: Sprite2D = %Sprite2D
@onready var door_collision: CollisionShape2D = %CollisionShape2D

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)
    else:
        add_to_group("doors")
        
        # 連接按鈕信號
        if button:
            button.button_pressed.connect(_on_button_pressed)
            button.button_released.connect(_on_button_released)
        else:
            push_error("門 ", door_id, " 沒有找到按鈕子節點")
        
        # 設置計時器等待時間並連接信號
        timer.wait_time = open_duration
        timer.timeout.connect(_on_timer_timeout)
        
        # 連接 GameManager 的狀態變化信號
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _on_button_pressed() -> void:
    """當按鈕被按下時"""
    if not is_open and not is_opening:
        open_door()

func _on_button_released() -> void:
    """當按鈕被釋放時"""
    # 如果門是開著的或正在開啟，立即開始計時關閉
    if (is_open or is_opening) and not is_closing:
        start_close_timer()

func open_door() -> void:
    """開啟門"""
    if is_opening or is_open:
        return
    
    is_opening = true
    
    # 停止關閉計時器
    if timer.is_stopped() == false:
        timer.stop()
    
    # 播放開啟動畫
    var tween = create_tween()
    tween.parallel().tween_property(door_sprite, "position", door_sprite.position + Vector2(0, -open_height), 1.0 / animation_speed)
    tween.parallel().tween_property(door_collision, "position", door_collision.position + Vector2(0, -open_height), 1.0 / animation_speed)
    tween.tween_callback(_on_door_opened)

func _on_door_opened() -> void:
    """門開啟完成"""
    is_opening = false
    is_open = true
    door_opened.emit()

func start_close_timer() -> void:
    """開始關閉計時器"""
    if timer.is_stopped():
        timer.start()

func _on_timer_timeout() -> void:
    """計時器超時，關閉門"""
    if is_open and not is_closing:
        close_door()

func close_door() -> void:
    """關閉門"""
    if is_closing or not is_open:
        return
    
    is_closing = true
    
    # 播放關閉動畫
    var tween = create_tween()
    tween.parallel().tween_property(door_sprite, "position", door_sprite.position + Vector2(0, open_height), 1.0 / animation_speed)
    tween.parallel().tween_property(door_collision, "position", door_collision.position + Vector2(0, open_height), 1.0 / animation_speed)
    tween.tween_callback(_on_door_closed)

func _on_door_closed() -> void:
    """門關閉完成"""
    is_closing = false
    is_open = false
    door_closed.emit()

func get_door_state() -> bool:
    """獲取門的當前狀態"""
    return is_open

func force_open() -> void:
    """強制開啟門"""
    if not is_open:
        door_sprite.position += Vector2(0, -open_height)
        door_collision.position += Vector2(0, -open_height)
        is_open = true
        door_opened.emit()

func force_close() -> void:
    """強制關閉門"""
    if is_open:
        door_sprite.position += Vector2(0, open_height)
        door_collision.position += Vector2(0, open_height)
        is_open = false
        door_closed.emit()

func set_open_duration(duration: float) -> void:
    """設置門開啟持續時間"""
    open_duration = duration
    if timer:
        timer.wait_time = duration

func set_open_height(height: float) -> void:
    """設置門開啟高度"""
    open_height = height

func reset_door() -> void:
    """重置門到初始狀態"""
    # 停止所有動畫和計時器
    if timer:
        timer.stop()
    
    # 重置狀態
    is_open = false
    is_opening = false
    is_closing = false
    
    # 重置門的位置到初始狀態（關閉狀態）
    if door_sprite and door_collision:
        door_sprite.position = Vector2(0, 0)
        door_collision.position = Vector2(0, 0)
    
    print("門 ", door_id, " 已重置到初始狀態")

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    # 當進入規劃階段時重置門（這通常發生在關卡重載時）
    if new_state == GameManager.InGameState.PLANNING:
        reset_door()
