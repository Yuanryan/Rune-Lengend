# abstract class for actions 
# TODO: add abstract keyword after Godot 4.5
extends Resource
class_name Action

@export var name: String = "Action"
@export var duration: float = 0.4  # 每個動作預設持續時間（秒）

var _time_left: float = 0.0

func start(_player: CharacterBody2D) -> void:
    _time_left = duration

# 回傳 true 表示動作結束
func update(_player: CharacterBody2D, delta: float) -> bool:
    _time_left -= delta
    return _time_left <= 0.0