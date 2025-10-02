# ZoomableCamera.gd
# 可縮放的相機腳本
extends Camera2D
class_name ZoomableCamera

@export var zoom_speed: float = 0.1
@export var max_zoom: float = 3.0

var original_zoom: float = 1.0

func _ready() -> void:
    original_zoom = zoom.x

func _input(event: InputEvent) -> void:
    # 處理滑鼠滾輪縮放
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in_at_mouse(event)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out_at_mouse(event)

func zoom_in_at_mouse(event: InputEventMouseButton) -> void:
    """在滑鼠位置放大"""
    var new_zoom = min(zoom.x + zoom_speed, max_zoom)
    if new_zoom != zoom.x:
        set_zoom_at_mouse(Vector2(new_zoom - zoom.x, new_zoom - zoom.x), event)

func zoom_out_at_mouse(event: InputEventMouseButton) -> void:
    """在滑鼠位置縮小"""
    var new_zoom = max(zoom.x - zoom_speed, original_zoom)
    if new_zoom != zoom.x:
        set_zoom_at_mouse(Vector2(new_zoom - zoom.x, new_zoom - zoom.x), event)

func set_zoom_at_mouse(delta: Vector2, event: InputEventMouseButton) -> void:
    """在滑鼠位置設置縮放"""
    # 完全關閉所有平滑
    position_smoothing_enabled = false
    enabled = false
    
    var screen_size = get_viewport().get_visible_rect().size
    var mouse_world_pos = ((event.position - Vector2(screen_size.x/2, screen_size.y/2)) / zoom) + position
    zoom += delta
    var new_mouse_world_pos = ((event.position - Vector2(screen_size.x/2, screen_size.y/2)) / zoom) + position
    position += mouse_world_pos - new_mouse_world_pos
    
    # 重新啟用相機
    enabled = true
