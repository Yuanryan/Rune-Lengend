# Scripts/Actions/jump_action.gd
extends ConditionalAction
class_name JumpAction

@export var jump_velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO

var _has_left_ground: bool = false

func _init(dir := Vector2.ZERO, _name := "Jump") -> void:
	direction = dir
	name = _name

func set_jump_velocity(new_jump_velocity: Vector2) -> void:
	jump_velocity = new_jump_velocity

func start(player: CharacterBody2D) -> void:
	# 設定跳躍速度（向上和水平方向）
	player.velocity = jump_velocity
	_has_left_ground = false
	
	# 根據跳躍方向設置面向方向
	if direction.x > 0:
		player.set_facing_direction(Vector2.RIGHT)
	elif direction.x < 0:
		player.set_facing_direction(Vector2.LEFT)
	
	# 增加跳躍計數（如果玩家有這個方法）
	if not player.is_on_floor():
		player._air_jump_count += 1

func should_stop(player: CharacterBody2D, delta: float) -> bool:
	# 檢查是否已經離開地面
	if not _has_left_ground and not player.is_on_floor():
		_has_left_ground = true
	
	# 只有在離開地面後再次觸地才結束動作
	return _has_left_ground and player.is_on_floor()

func interrupt(player: CharacterBody2D) -> void:
	pass

# 檢查跳躍動作是否可以被執行
func can_perform(player: CharacterBody2D) -> bool:
	# 如果在地面上，總是允許跳躍
	if player.is_on_floor():
		return true	# 獲取玩家的跳躍計數和最大空中跳躍次數
	
	# 檢查是否還有空中跳躍次數
	return player._air_jump_count < player.get_max_air_jumps()