# Scripts/Actions/jump_action.gd
extends ConditionalAction
class_name JumpAction

@export var jump_velocity: Vector2 = Vector2.ZERO

var _has_left_ground: bool = false

func _init(_jump_velocity := Vector2.ZERO, _name := "Jump") -> void:
	jump_velocity = _jump_velocity
	name = _name

func set_jump_velocity(new_jump_velocity: Vector2) -> void:
	jump_velocity = new_jump_velocity

func start(player: CharacterBody2D) -> void:
	# 設定跳躍速度（向上和水平方向）
	player.velocity = jump_velocity
	_has_left_ground = false

func should_stop(player: CharacterBody2D, delta: float) -> bool:
	# 檢查是否已經離開地面
	if not _has_left_ground and not player.is_on_floor():
		_has_left_ground = true
	
	# 只有在離開地面後再次觸地才結束動作
	return _has_left_ground and player.is_on_floor()

func interrupt(player: CharacterBody2D) -> void:
	player.velocity = Vector2.ZERO
