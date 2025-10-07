@tool
# Button.gd
# 按鈕類別，當玩家踩到時會觸發信號
extends Area2D
class_name GameButton

signal button_pressed
signal button_released

@export var color: Color = Color(1, 1, 1, 1) : set = set_color
@export var auto_reset: bool = true
@export var reset_delay: float = 0.1

@onready var polygon : Polygon2D = %Polygon2D

var button_down: bool = false
var is_pressed: bool = false

func _ready() -> void:
    _get_polygon()
    set_color(color)
    add_to_group("buttons")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _get_polygon() -> Polygon2D:
    if polygon == null:
        polygon = get_node("%Polygon2D")
    return polygon

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("Interactive"):
        is_pressed = true
        if not button_down:
            press_button()

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("Interactive"):
        is_pressed = false
        if auto_reset and button_down:
            # 延遲釋放按鈕
            await get_tree().create_timer(reset_delay).timeout
            if not is_pressed:  # 確保玩家沒有重新踩到按鈕
                release_button()

func press_button() -> void:
    if button_down:
        return
    
    button_down = true
    button_pressed.emit()

func release_button() -> void:
    if not button_down:
        return
    
    button_down = false
    button_released.emit()

func get_button_state() -> bool:
    """獲取按鈕當前狀態"""
    return button_down

func force_press() -> void:
    """強制按下按鈕"""
    press_button()

func force_release() -> void:
    """強制釋放按鈕"""
    release_button()

func set_color(new_color: Color) -> void:
    color = new_color
    if polygon:
        polygon.color = color