# Level.gd
# 關卡類別，負責管理關卡狀態和玩家生成
@tool
extends Node2D
class_name Level

@export var level_resource: LevelResource = null
@onready var starting_point: Marker2D = %StartingPoint
@onready var starting_camera: PhantomCamera2D = %StartingCamera
@onready var camera: Camera2D = %Camera2D

# 檢查點陣列
var checkpoints: Array[Checkpoint] = []
# 當前檢查點索引（最後到達的檢查點）
var current_checkpoint_index: int = -1
# 儲存起始相機的原始 tween_duration
var original_starting_camera_tween_duration: float = 1.0

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
    # 儲存起始相機的原始 tween_duration
    if starting_camera:
        original_starting_camera_tween_duration = starting_camera.tween_duration
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
    

# 初始化相機狀態
func _initialize_camera_state() -> void:
    # 將所有相機的優先級設為 0
    camera.make_current()
    PhantomCameraManager.get_phantom_camera_2ds().map(func(pcam: PhantomCamera2D): 
        if pcam != starting_camera:
            pcam.priority = 0
            pcam.visible = false
    )
    _activate_starting_camera()


func _on_checkpoint_reached(checkpoint: Checkpoint, checkpoint_pos: Vector2) -> void:
    # 找到檢查點在陣列中的索引
    current_checkpoint_index = checkpoints.find(checkpoint)
    
    print("檢查點到達: ", checkpoint.name, " (索引: ", current_checkpoint_index, ")")
    
    # 檢查是否需要激活相機
    if checkpoint and checkpoint.activate_camera:
        _switch_to_checkpoint_camera(checkpoint)

    starting_point.global_position = checkpoint_pos
    
    # 觸碰檢查點時自動切換到人類
    GameManager.player.switch_animal(Animal.animal_from_type(Animal.AnimalType.MAN))
    
    # 重置遊戲狀態到規劃階段
    GameManager.reset_to_planning()
    

# 切換到指定檢查點的 PhantomCamera2D
func _switch_to_checkpoint_camera(target: Checkpoint, should_tween: bool = true) -> void:    
    # 直接設置指定檢查點相機的優先級（使用陣列索引）
    if target and target.phantom_camera:
        var checkpoint_index = checkpoints.find(target)
        var priority_value = checkpoint_index + 11  # 索引從0開始，優先級從1開始
        target.set_camera_priority(priority_value, should_tween)
    else:
        _activate_starting_camera()


# 啟動起始相機
func _activate_starting_camera() -> void:
    if not starting_camera:
        return
    
    # 重置所有 PhantomCamera2D，確保只有起始相機具有較高優先級
    PhantomCameraManager.get_phantom_camera_2ds().map(func(pcam: PhantomCamera2D):
        if pcam == starting_camera:
            return
        pcam.priority = 0
        pcam.visible = false
    )
    
    # 起始相機不需要補間：設定為即時切換
    starting_camera.tween_duration = 0.0
    
    # 設置起始相機為可見並提升優先級
    starting_camera.visible = true
    starting_camera.priority = 10




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

func get_checkpoint_by_index(index: int) -> Checkpoint:
    """根據索引獲取檢查點"""
    if index >= 0 and index < checkpoints.size():
        return checkpoints[index]
    return null

func get_active_checkpoints() -> Array[Checkpoint]:
    """獲取已激活的檢查點"""
    var active_checkpoints: Array[Checkpoint] = []
    for checkpoint in checkpoints:
        if checkpoint.active:
            active_checkpoints.append(checkpoint)
    return active_checkpoints

func get_current_checkpoint_index() -> int:
    """獲取當前檢查點索引（最後到達的檢查點）"""
    return current_checkpoint_index

func get_current_checkpoint() -> Checkpoint:
    """獲取當前檢查點"""
    if current_checkpoint_index >= 0 and current_checkpoint_index < checkpoints.size():
        return checkpoints[current_checkpoint_index]
    return null



func set_starting_point_to_checkpoint(checkpoint: Checkpoint) -> void:
    """將起始點設置到指定檢查點的位置"""
    if checkpoint:
        starting_point.global_position = checkpoint.global_position
        # 使用 PhantomCamera2D 切換相機，重新載入時禁用 tween
        _switch_to_checkpoint_camera(checkpoint, false)

func set_starting_point_to_checkpoint_by_index(index: int) -> void:
    """根據索引將起始點設置到指定檢查點的位置"""
    var checkpoint = get_checkpoint_by_index(index)
    if checkpoint:
        set_starting_point_to_checkpoint(checkpoint)

func set_starting_point_to_current_checkpoint() -> void:
    """將起始點設置到當前檢查點的位置"""
    if current_checkpoint_index >= 0:
        set_starting_point_to_checkpoint_by_index(current_checkpoint_index)
