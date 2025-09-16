extends ContinuousAction
class_name MoveAction

@export var velocity_x: float = 0.0

func _init(_velocity_x := 0.0, _name := "Move") -> void:
	velocity_x = _velocity_x
	name = _name

func set_velocity_x(new_velocity_x: float) -> void:
	velocity_x = new_velocity_x

func start(player: CharacterBody2D) -> void:
	player.velocity.x = velocity_x

func update(player: CharacterBody2D, delta: float) -> bool:
	return false

# 中斷時停止移動
func interrupt(player: CharacterBody2D) -> void:
	player.velocity.x = 0.0