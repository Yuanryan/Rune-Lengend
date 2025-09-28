extends ContinuousAction
class_name MoveAction

@export var velocity_x: float = 0.0
var direction: float = 0.0

func _init(dir := 0.0, _name := "Move") -> void:
	direction = dir
	name = _name

func set_velocity_x(new_velocity_x: float) -> void:
	print("[DEBUG] MoveAction.set_velocity_x called - old: ", velocity_x, ", new: ", new_velocity_x)
	velocity_x = new_velocity_x

func start(player: CharacterBody2D) -> void:
	print("[DEBUG] MoveAction.start called - velocity_x: ", velocity_x, ", direction: ", direction)
	player.velocity.x = velocity_x

func update(player: CharacterBody2D, delta: float) -> bool:
	return false

# 中斷時停止移動
func interrupt(player: CharacterBody2D) -> void:
	player.velocity.x = 0.0