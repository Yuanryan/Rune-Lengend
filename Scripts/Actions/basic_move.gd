# Scripts/Actions/basic_move.gd
extends Action
class_name BasicMove

@export var velocity: Vector2 = Vector2.ZERO

func _init(_velocity := Vector2.ZERO, _name := "Move", _duration := 0.4) -> void:
	velocity = _velocity
	name = _name
	duration = _duration

func start(player: CharacterBody2D) -> void:
	super.start(player)
	# 只能在地板上時才允許設定 y 方向速度
	player.velocity.x = velocity.x
	if player.is_on_floor():
		player.velocity.y = velocity.y

func update(player: CharacterBody2D, delta: float) -> bool:
	var done := super.update(player, delta)
	if done:
		player.velocity = Vector2.ZERO
	return done
