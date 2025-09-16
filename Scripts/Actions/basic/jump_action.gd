# Scripts/Actions/jump_action.gd
extends ConditionalAction
class_name JumpAction

@export var jump_velocity: Vector2 = Vector2.ZERO

func _init(_jump_velocity := Vector2.ZERO, _name := "Jump") -> void:
	jump_velocity = _jump_velocity
	name = _name

func set_jump_velocity(new_jump_velocity: Vector2) -> void:
	jump_velocity = new_jump_velocity

func start(player: CharacterBody2D) -> void:
	# 設定跳躍速度（向上和水平方向）
	player.velocity = jump_velocity

func should_stop(player: CharacterBody2D, delta: float) -> bool:
	# 檢查是否觸地，如果觸地則立即結束動作
	return player.is_on_floor()

func interrupt(player: CharacterBody2D) -> void:
	pass
