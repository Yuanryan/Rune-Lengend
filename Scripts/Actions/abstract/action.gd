# abstract class for actions 
@abstract 
class_name Action
extends Resource

@export var name: String = "Action"

enum ActionType {
	MOVE_LEFT,
	MOVE_RIGHT,
	JUMP_LEFT,
	JUMP_RIGHT,
	SWITCH_ANIMAL
}

@abstract func start(_player: CharacterBody2D) -> void
@abstract func update(_player: CharacterBody2D, delta: float) -> bool
@abstract func interrupt(_player: CharacterBody2D) -> void

# 檢查動作是否可以被執行（預設為true，子類可以重寫）
func can_perform(_player: CharacterBody2D) -> bool:
	return true

