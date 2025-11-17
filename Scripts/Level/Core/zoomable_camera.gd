@tool
# ZoomableCamera.gd
# 可縮放的相機腳本
extends PhantomCamera2D
class_name ZoomableCamera

@export var zoom_speed: float = 0.1
@export var max_zoom: float = 3.0

var original_zoom: float = 1.0
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    original_zoom = get_zoom().x
    original_position = position

func _input(event: InputEvent) -> void:
    # 處理滑鼠滾輪縮放
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in_at_mouse(event)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out_at_mouse(event)

func zoom_in_at_mouse(event: InputEventMouseButton) -> void:
    """在滑鼠位置放大"""
    var cur_zoom = get_zoom()
    var new_zoom = min(cur_zoom.x + zoom_speed, max_zoom)
    if new_zoom != cur_zoom.x:
        set_zoom_at_mouse(Vector2(new_zoom - cur_zoom.x, new_zoom - cur_zoom.x), event)

func zoom_out_at_mouse(event: InputEventMouseButton) -> void:
    """在滑鼠位置縮小"""
    var cur_zoom = get_zoom()
    var new_zoom = max(cur_zoom.x - zoom_speed, original_zoom)
    if new_zoom != cur_zoom.x:
        set_zoom_at_mouse(Vector2(new_zoom - cur_zoom.x, new_zoom - cur_zoom.x), event)

func set_zoom_at_mouse(delta: Vector2, event: InputEventMouseButton) -> void:
    """在滑鼠位置設置縮放"""
    var cur_zoom = get_zoom()
    var mouse_world_pos = get_global_mouse_position()
    set_zoom(cur_zoom + delta)
    var new_mouse_world_pos = get_global_mouse_position()
    position += mouse_world_pos - new_mouse_world_pos
    
  
func set_zoom_at_origin(delta: Vector2) -> void:
    set_zoom(get_zoom() + delta)
    position = original_position
