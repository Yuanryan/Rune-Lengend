# 時間動作基類 - 基於時間條件結束
extends ConditionalAction
class_name TimedAction

@export var duration: float = 0.4  # 動作持續時間（秒）

var _time_left: float = 0.0

func start(_player: CharacterBody2D) -> void:
    _time_left = duration

# 時間條件：時間到期時停止
func should_stop(_player: CharacterBody2D, delta: float) -> bool:
    _time_left -= delta
    return _time_left <= 0.0

func interrupt(player: CharacterBody2D) -> void:
    pass