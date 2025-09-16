# Scripts/Actions/jump_action.gd
extends ConditionalAction
class_name JumpAction

@export var jump_force: float = 400.0
@export var horizontal_force: float = 200.0

func _init(_jump_force := 400.0, _horizontal_force := 200.0, _name := "Jump") -> void:
	jump_force = _jump_force
	horizontal_force = _horizontal_force
	name = _name

func start(player: CharacterBody2D) -> void:
	# 設定跳躍速度（向上和水平方向）
	player.velocity = Vector2(horizontal_force, -jump_force)

func should_stop(player: CharacterBody2D, delta: float) -> bool:
	# 檢查是否觸地，如果觸地則立即結束動作
	return player.is_on_floor()

func interrupt(player: CharacterBody2D) -> void:
	pass
