# 持續動作基類 - 永遠不會自動結束，需要外部條件來停止
@abstract
class_name ContinuousAction
extends Action
# 持續動作永遠不會自動結束，需要外部條件來停止

func update(_player: CharacterBody2D, delta: float) -> bool:
    # 持續動作永遠回傳 false，表示不會自動結束
    return false
