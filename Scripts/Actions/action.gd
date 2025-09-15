# abstract class for actions 
# TODO: add abstract keyword after Godot 4.5
extends Resource
class_name Action

@export var name: String = "Action"

func start(_player: CharacterBody2D) -> void:
    pass

# 回傳 true 表示動作結束
func update(_player: CharacterBody2D, delta: float) -> bool:
    return false

# 當動作被中斷時調用（可選重寫）
func interrupt(_player: CharacterBody2D) -> void:
    pass