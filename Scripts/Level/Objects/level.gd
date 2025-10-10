# Level.gd
# 關卡類別，負責管理關卡狀態和玩家生成
@tool
extends Node2D
class_name Level

@export var level_resource: LevelResource = null
@onready var starting_point: Marker2D = %StartingPoint
@onready var starting_camera: PhantomCamera2D = %StartingCamera

# 檢查點陣列
var checkpoints: Array[Checkpoint] = []
# 當前檢查點ID（最後到達的檢查點）
var current_checkpoint_id: int = 0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	# 檢查是否有 StartingPoint 子節點
	if not has_node("%StartingPoint"):
		warnings.append("Level 缺少 Marker2D 子節點 (StartingPoint)")
	elif not get_node("%StartingPoint") is Marker2D:
		warnings.append("StartingPoint 必須是 Marker2D 節點")
	
	if not has_node("%StartingCamera"):
		warnings.append("Level 缺少 PhantomCamera2D 子節點 (StartingCamera)")
	elif not get_node("%StartingCamera") is PhantomCamera2D:
		warnings.append("StartingCamera 必須是 PhantomCamera2D 節點")
	
	return warnings

func _ready() -> void:
	if not starting_point:
		push_error("Level 缺少 StartingPoint 子節點")
	# 只在非編輯器模式下生成玩家
	if not Engine.is_editor_hint():
		initialize_checkpoints()
		_initialize_camera_state()

# 初始化檢查點陣列
func initialize_checkpoints() -> void:
	checkpoints.clear()
	
	# 僅從本節點的直接子節點收集檢查點
	for checkpoint in get_tree().get_nodes_in_group("Checkpoint"):
		if checkpoint.owner == self and checkpoint is Checkpoint:
			checkpoints.append(checkpoint)
			checkpoint.checkpoint_reached.connect(_on_checkpoint_reached)
	
	print("已初始化 ", checkpoints.size(), " 個檢查點")

# 初始化相機狀態
func _initialize_camera_state() -> void:
	# 隱藏所有檢查點的 PhantomCamera2D
	PhantomCameraManager.get_phantom_camera_2ds().map(func(pcam: PhantomCamera2D): pcam.visible = false)
	_activate_starting_camera()


func _on_checkpoint_reached(checkpoint_id: int, checkpoint_pos: Vector2) -> void:
	# 更新當前檢查點ID
	current_checkpoint_id = checkpoint_id
	
	# 獲取檢查點並檢查是否需要激活相機
	var target_checkpoint = get_checkpoint_by_id(checkpoint_id)
	if target_checkpoint and target_checkpoint.activate_camera:
		_switch_to_checkpoint_camera(target_checkpoint)
   
	starting_point.global_position = checkpoint_pos
	
	# 重置遊戲狀態到規劃階段
	GameManager.reset_to_planning()
	
	print("到達檢查點: ", checkpoint_id)

# 切換到指定檢查點的 PhantomCamera2D
func _switch_to_checkpoint_camera(target: Checkpoint) -> void:
	PhantomCameraManager.get_phantom_camera_2ds().map(func(pcam: PhantomCamera2D): pcam.visible = false)
	
	# 顯示指定檢查點的 PhantomCamera2D
	if target and target.phantom_camera:
		target.set_camera_visible(true)
	else:
		_activate_starting_camera()

# 啟動起始相機
func _activate_starting_camera() -> void:
	if starting_camera:
		starting_camera.visible = true

# 在起始點生成玩家
func spawn_player() -> Player:
	if not starting_point:
		push_error("無法生成玩家：缺少 StartingPoint")
		return null
	
	# 如果已經有玩家，先移除
	GameManager.remove_player()
	
	# 實例化玩家
	var player = GameManager.player_scene.instantiate()
	GameManager.set_player(player)
	player.set_available_animals.call_deferred(level_resource.available_animals)
	if not player:
		push_error("無法實例化玩家場景")
		return null
	
	# 設置玩家位置
	player.global_position = starting_point.global_position
	# 將玩家加入場景
	add_child(player)
	return player

func get_starting_point_position() -> Vector2:
	"""獲取起始點位置"""
	if starting_point:
		return starting_point.global_position
	else:
		push_error("無法獲取起始點位置：StartingPoint 不存在")
		return Vector2.ZERO

# 檢查點管理方法
func get_checkpoints() -> Array[Checkpoint]:
	"""獲取所有檢查點"""
	return checkpoints

func get_checkpoint_count() -> int:
	"""獲取檢查點數量"""
	return checkpoints.size()

func get_checkpoint_by_id(checkpoint_id: int) -> Checkpoint:
	"""根據ID獲取檢查點"""
	for checkpoint in checkpoints:
		if checkpoint.checkpoint_id == checkpoint_id:
			return checkpoint
	return null

func get_active_checkpoints() -> Array[Checkpoint]:
	"""獲取已激活的檢查點"""
	var active_checkpoints: Array[Checkpoint] = []
	for checkpoint in checkpoints:
		if checkpoint.active:
			active_checkpoints.append(checkpoint)
	return active_checkpoints

func get_current_checkpoint_id() -> int:
	"""獲取當前檢查點ID（最後到達的檢查點）"""
	return current_checkpoint_id

func get_current_checkpoint() -> Checkpoint:
	"""獲取當前檢查點物件（最後到達的檢查點）"""
	return get_checkpoint_by_id(current_checkpoint_id)

func set_starting_point_to_checkpoint(checkpoint: Checkpoint) -> void:
	"""將起始點設置到指定檢查點的位置"""
	if checkpoint:
		starting_point.global_position = checkpoint.global_position
		# 使用 PhantomCamera2D 切換相機
		_switch_to_checkpoint_camera(get_checkpoint_by_id(checkpoint.checkpoint_id))

func set_starting_point_to_checkpoint_by_id(checkpoint_id: int) -> void:
	"""根據ID將起始點設置到指定檢查點的位置"""
	var checkpoint = get_checkpoint_by_id(checkpoint_id)
	if checkpoint:
		set_starting_point_to_checkpoint(checkpoint)
	else:
		print("找不到檢查點: ", checkpoint_id)

func set_starting_point_to_current_checkpoint() -> void:
	"""將起始點設置到當前檢查點的位置"""
	if current_checkpoint_id > 0:
		set_starting_point_to_checkpoint_by_id(current_checkpoint_id)
	else:
		print("沒有當前檢查點，保持原始起始點位置")
