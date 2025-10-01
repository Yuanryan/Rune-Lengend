# Button.gd
# 按鈕類別，當玩家踩到時會觸發信號
extends Area2D
class_name GameButton

signal button_pressed
signal button_released

@export var button_id: int = 0
@export var auto_reset: bool = true
@export var reset_delay: float = 0.1

var is_pressed: bool = false
var player_on_button: bool = false

func _ready() -> void:
    add_to_group("buttons")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body is Player:
        player_on_button = true
        if not is_pressed:
            press_button()

func _on_body_exited(body: Node) -> void:
    if body is Player:
        player_on_button = false
        if auto_reset and is_pressed:
            # 延遲釋放按鈕
            await get_tree().create_timer(reset_delay).timeout
            if not player_on_button:  # 確保玩家沒有重新踩到按鈕
                release_button()

func press_button() -> void:
    if is_pressed:
        return
    
    is_pressed = true
    print("按鈕被按下: ", button_id)
    button_pressed.emit()

func release_button() -> void:
    if not is_pressed:
        return
    
    is_pressed = false
    print("按鈕被釋放: ", button_id)
    button_released.emit()

func get_button_state() -> bool:
    """獲取按鈕當前狀態"""
    return is_pressed

func force_press() -> void:
    """強制按下按鈕"""
    press_button()

func force_release() -> void:
    """強制釋放按鈕"""
    release_button()
