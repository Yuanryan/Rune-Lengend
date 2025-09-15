# LevelResource.gd
# 關卡資源，定義關卡的基本屬性和限制
extends Resource
class_name LevelResource

@export var level_name: String = "Unnamed Level"
@export var level_description: String = ""

# 關卡限制
@export var max_animals: int = 2  # 最多可使用的動物數量
@export var max_actions: int = 5  # 最多可放置的動作數量

# 關卡場景
@export var level_scene: PackedScene

# 關卡難度
@export var difficulty: int = 1  # 1-5 難度等級

# 可用動物列表（動物名稱）
@export var available_animals: Array[String] = ["Rabbit", "Wolf"]

# 關卡完成條件
@export var completion_conditions: Array[String] = []

# 檢查是否可以使用指定動物
func can_use_animal(animal_name: String) -> bool:
    return animal_name in available_animals

# 檢查是否達到動物數量限制
func is_animal_limit_reached(current_count: int) -> bool:
    return current_count >= max_animals

# 檢查是否達到動作數量限制
func is_action_limit_reached(current_count: int) -> bool:
    return current_count >= max_actions

# 獲取關卡資訊字串
func get_level_info() -> String:
    return "關卡: %s\n難度: %d\n動物限制: %d\n動作限制: %d" % [level_name, difficulty, max_animals, max_actions]
