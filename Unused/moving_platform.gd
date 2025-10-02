@tool
extends LandTool

@export var movable: bool = false
@export var speed_pixels_per_second: float = 120.0
@export var loop: bool = true
@export var wait_time_seconds: float = 0.0

@onready var path_2d: SmoothPath = $Path2D

var _progress: float = 0.0
var _direction: int = 1
var _wait_timer: float = 0.0
var _path_length: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true) 
    else:
        movable = false

    if path_2d and path_2d.curve:
        _path_length = path_2d.curve.get_baked_length()
        # 調用 smooth 函數來平滑路徑
        path_2d.smooth(true)
        remove_child(path_2d)
        owner.add_child.call_deferred(path_2d)
    else:
        push_warning("MovingPlatform: No Path2D or curve found!")
        
func _physics_process(delta: float) -> void:
    if not movable:
        return

    if _path_length <= 0 or not path_2d or not path_2d.curve:
        return

    if _wait_timer > 0.0:
        _wait_timer -= delta
        return

    var distance_to_move: float = speed_pixels_per_second * delta
    _progress += distance_to_move * _direction

    # Handle loop or ping-pong movement
    if loop:
        _progress = fmod(_progress, _path_length)
        if _progress < 0:
            _progress += _path_length
    else:
        if _progress >= _path_length:
            _progress = _path_length
            _direction = -1
            _wait_timer = wait_time_seconds
        elif _progress <= 0:
            _progress = 0
            _direction = 1
            _wait_timer = wait_time_seconds

    # Update platform position to follow the curve
    # Curve points are local to Path2D, so add Path2D's global position
    var curve_point = path_2d.curve.sample_baked(_progress)
    global_position = path_2d.global_position + curve_point
