@tool
@icon("res://Assets/icons/door-closed-solid-full.svg")
# Door.gd
# 門類別，可以通過按鈕控制開關
extends LandTool
class_name Door

signal door_opened
signal door_closed

@export_tool_button("Toggle Open/Close", "BackBufferCopy") var toggle_door = func(): if is_open or is_opening: close_door() else: open_door()
## 門開啟持續時間
@export var open_duration: float = 3.0  
## 消失/出現動畫速度
@export var animation_speed: float = 2.0  

@onready var button: GameButton = %GameButton
@onready var timer: Timer = %DoorTimer
@onready var door_polygon: Polygon2D = %Polygon2D
@onready var door_collision: CollisionPolygon2D = _find_door_collision()

var is_open: bool = false
var is_opening: bool = false
var is_closing: bool = false

func _ready() -> void:

    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true)
    else:
        # 確保門的碰撞元件存在
        if door_collision == null:
            door_collision = _find_door_collision()
        
        # 確保初始狀態是可見的
        if door_polygon:
            door_polygon.modulate.a = 1.0
        if door_collision:
            door_collision.set_deferred("disabled", false)
        
        add_to_group("doors")

        # 連接按鈕信號
        if button:
            button.button_pressed.connect(_on_button_pressed)
            button.button_released.connect(_on_button_released)
        # 設置計時器等待時間並連接信號
        timer.wait_time = open_duration
        timer.timeout.connect(_on_timer_timeout)

        # 連接 GameManager 的狀態變化信號
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _find_door_collision() -> CollisionPolygon2D:
    """尋找門的碰撞元件"""
    for child in get_children():
        if child is CollisionPolygon2D:
            return child
    return null 

func _on_button_pressed() -> void:
    """當按鈕被按下時"""
    if not is_open:
        open_door()

func _on_button_released() -> void:
    """當按鈕被釋放時"""
    # 如果門是開著的或正在開啟，立即開始計時關閉
    if (is_open or is_opening) and not is_closing:
        start_close_timer()

func open_door() -> void:
    """開啟門（消失）"""
    if is_open:
        return
    
    is_opening = true
    
    # 停止關閉計時器
    if timer.is_stopped() == false:
        timer.stop()
    
    # 播放消失動畫（淡出）
    var tween = create_tween()
    if door_polygon:
        tween.parallel().tween_property(door_polygon, "modulate:a", 0.0, 1.0 / animation_speed)
    tween.tween_callback(_on_door_opened)

func _on_door_opened() -> void:
    """門開啟完成（消失）"""
    is_opening = false
    is_open = true
    # 禁用碰撞
    if door_collision:
        door_collision.set_deferred("disabled", true)
    door_opened.emit()

func start_close_timer() -> void:
    """開始關閉計時器"""
    if timer.is_stopped():
        timer.start()

func _on_timer_timeout() -> void:
    """計時器超時，關閉門"""
    if is_open and not is_closing and not is_opening:
        close_door()

func close_door() -> void:
    """關閉門（出現）"""
    if is_closing or not is_open:
        return
    
    is_closing = true
    
    # 確保從透明開始（如果還不是）
    if door_polygon and door_polygon.modulate.a > 0.0:
        door_polygon.modulate.a = 0.0
    
    # 啟用碰撞
    if door_collision:
        door_collision.set_deferred("disabled", false)
    
    # 播放出現動畫（淡入）
    var tween = create_tween()
    if door_polygon:
        tween.parallel().tween_property(door_polygon, "modulate:a", 1.0, 1.0 / animation_speed)
    tween.tween_callback(_on_door_closed)
        
func _on_door_closed() -> void:
    """門關閉完成（出現）"""
    is_closing = false
    is_open = false
    door_closed.emit()

func get_door_state() -> bool:
    """獲取門的當前狀態"""
    return is_open

func force_open() -> void:
    """強制開啟門（立即消失）"""
    if not is_open:
        if door_polygon:
            door_polygon.modulate.a = 0.0
        if door_collision:
            door_collision.set_deferred("disabled", true)
        is_open = true
        door_opened.emit()

func force_close() -> void:
    """強制關閉門（立即出現）"""
    if is_open:
        if door_polygon:
            door_polygon.modulate.a = 1.0
        if door_collision:
            door_collision.set_deferred("disabled", false)
        is_open = false
        door_closed.emit()

func set_open_duration(duration: float) -> void:
    """設置門開啟持續時間"""
    open_duration = duration
    if timer:
        timer.wait_time = duration


func reset_door() -> void:
    """重置門到初始狀態"""
    # 停止所有動畫和計時器
    if timer:
        timer.stop()
    
    # 重置狀態
    is_open = false
    is_opening = false
    is_closing = false
    
    force_close()
    
func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    # 當進入規劃階段時重置門（這通常發生在關卡重載時）
    if new_state == GameManager.InGameState.PLANNING:
        reset_door()
