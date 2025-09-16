# LevelResource.gd
# 關卡資源，定義關卡的基本屬性和限制
extends Resource
class_name LevelResource

@export var level_name: String = "Unnamed Level"
@export var level_description: String = ""

@export var max_total_actions: int = 5  # 最多可放置的動作數量

@export var individual_action_limits: Dictionary[Action.ActionType, int] = {
    Action.ActionType.MOVE_LEFT: 2,
    Action.ActionType.MOVE_RIGHT: 2,
    Action.ActionType.JUMP_LEFT: 1,
    Action.ActionType.JUMP_RIGHT: 1,
    Action.ActionType.SWITCH_ANIMAL: 1
}
# 可用動物列表（動物名稱）
@export var available_animals: Array[Animal.AnimalType] = []

# 檢查是否達到動作數量限制
func is_action_limit_reached(current_count: int) -> bool:
    return current_count >= max_total_actions
