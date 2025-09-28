# LevelManager.gd
# 關卡管理器單例，負責載入和管理關卡場景
extends Node

# 當前關卡場景
var current_level_scene: PackedScene = null
var current_level: Level = null

# 關卡場景字典
var level_scenes: Dictionary = {}


# 信號
signal level_loaded(level_scene: Level)
signal level_unloaded()
signal player_spawned(player: Player)

func _ready() -> void:
    _initialize_level_scenes()

# 初始化關卡場景
func _initialize_level_scenes() -> void:
    _scan_and_load_levels()

# 掃描並載入所有關卡
func _scan_and_load_levels() -> void:
    var scenes_dir = "res://Scenes/Levels/"
    
    # 掃描場景檔案
    var scene_files = _get_files_in_directory(scenes_dir, ".tscn")
    
    for scene_file in scene_files:
        var level_name = scene_file.replace(".tscn", "")  # 例如: "level_1"
        var scene_path = scenes_dir + scene_file
        _load_level_from_scene(level_name, scene_path)

# 從場景檔案載入關卡
func _load_level_from_scene(level_id: String, scene_path: String) -> void:
    # 檢查檔案是否存在
    if not FileAccess.file_exists(scene_path):
        print("關卡場景檔案不存在: ", scene_path)
        return
    
    # 載入關卡場景
    var scene = load(scene_path)
    if not scene:
        print("無法載入關卡場景: ", scene_path)
        return
    
    # 檢查是否為 PackedScene
    if not scene is PackedScene:
        print("檔案不是有效的場景檔案: ", scene_path)
        return
    
    # 儲存到關卡場景字典
    level_scenes[level_id] = scene

# 獲取目錄中的檔案
func _get_files_in_directory(path: String, extension: String) -> Array[String]:
    var files: Array[String] = []
    var dir = DirAccess.open(path)
    
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            if file_name.ends_with(extension):
                files.append(file_name)
            file_name = dir.get_next()
        
        dir.list_dir_end()
    
    return files

# 獲取所有關卡 ID
func get_all_level_ids() -> Array[String]:
    var ids: Array[String] = []
    for level_id in level_scenes.keys():
        ids.append(level_id)
    ids.sort()
    return ids

# ========== 核心功能 ==========

# 載入關卡場景
func load_level_scene(level_scene: PackedScene, spawn_position: Vector2 = Vector2.ZERO) -> Level:
    # 清除當前關卡
    if current_level:
        current_level.queue_free()
        current_level = null
        GameManager.remove_player()
    
    # 設定當前關卡場景
    current_level_scene = level_scene
    
    # 實例化關卡場景
    current_level = level_scene.instantiate()
    if not current_level:
        push_error("無法載入關卡場景")
        return null
    
    # 將關卡加入場景樹
    get_tree().current_scene.add_child(current_level)
    
    # 如果指定了生成位置，設置起始點並生成玩家
    if spawn_position != Vector2.ZERO:
        current_level.starting_point.global_position = spawn_position
    current_level.spawn_player()
    
    # 通知 UI Manager 創建卡片
    UIManager.create_cards_from_level(current_level)
    GameManager.set_game_state(GameManager.GameState.GAME_PLAY)

    level_loaded.emit(current_level)
    return current_level

# 卸載關卡
func unload_level() -> void:
    if current_level:
        current_level.queue_free()
        current_level = null
        GameManager.remove_player()
        current_level_scene = null
        level_unloaded.emit()
        print("關卡已卸載")

# 獲取當前關卡
func get_current_level() -> Level:
    return current_level

# 獲取所有關卡場景
func get_all_level_scenes() -> Dictionary:
    return level_scenes

# 重新載入當前關卡
func reload_current_level() -> Level:
    """重新載入當前關卡，保持動作佇列狀態"""
    if not current_level_scene:
        push_error("沒有當前關卡場景可以重新載入")
        return null
    
    # 保存動作佇列狀態
    var saved_action_queue = _save_action_queue()
    
    # 重新載入關卡
    var reloaded_level = load_level_scene(current_level_scene)
    
    # 恢復動作佇列
    if reloaded_level:
        await _restore_action_queue(saved_action_queue)
    
    return reloaded_level

# 保存和恢復動作佇列的通用方法
func _save_action_queue() -> Array:
    """保存當前動作佇列狀態"""
    var saved_action_queue = []
    var in_game_ui = UIManager.get_in_game_ui()
    if in_game_ui and in_game_ui.action_queue:
        saved_action_queue = in_game_ui.action_queue.get_action_descriptors()
    return saved_action_queue

func _restore_action_queue(saved_action_queue: Array) -> void:
    """恢復動作佇列狀態"""
    if saved_action_queue.size() > 0:
        await get_tree().process_frame
        var in_game_ui = UIManager.get_in_game_ui()
        if in_game_ui:
            in_game_ui.restore_action_queue(saved_action_queue)

# 從最後檢查點重新載入關卡
func reload_level_from_last_checkpoint() -> Level:
    """從最後到達的檢查點重新載入關卡"""
    if not current_level_scene:
        push_error("沒有當前關卡場景可以重新載入")
        return null
    
    # 保存當前檢查點ID和動作佇列狀態
    var saved_checkpoint_id = 0
    var spawn_position = Vector2.ZERO
    
    if current_level:
        saved_checkpoint_id = current_level.get_current_checkpoint_id()
        print("保存的檢查點ID: ", saved_checkpoint_id)
        
        # 獲取檢查點位置
        if saved_checkpoint_id > 0:
            var checkpoint = current_level.get_checkpoint_by_id(saved_checkpoint_id)
            if checkpoint:
                spawn_position = checkpoint.global_position
                print("檢查點位置: ", spawn_position)
    
    var saved_action_queue = _save_action_queue()
    
    # 重新載入關卡並在檢查點位置生成玩家
    var reloaded_level = load_level_scene(current_level_scene, spawn_position)
    
    # 恢復動作佇列
    if reloaded_level:
        await _restore_action_queue(saved_action_queue)
    
    return reloaded_level

# 從指定檢查點重新載入關卡
func reload_level_from_specific_checkpoint(checkpoint_id: int) -> Level:
    """從指定檢查點重新載入關卡"""
    if not current_level_scene:
        push_error("沒有當前關卡場景可以重新載入")
        return null
    
    # 獲取指定檢查點位置
    var spawn_position = Vector2.ZERO
    if current_level:
        var checkpoint = current_level.get_checkpoint_by_id(checkpoint_id)
        if checkpoint:
            spawn_position = checkpoint.global_position
            print("指定檢查點位置: ", spawn_position)
        else:
            print("找不到檢查點: ", checkpoint_id)
    
    var saved_action_queue = _save_action_queue()
    
    # 重新載入關卡並在指定檢查點位置生成玩家
    var reloaded_level = load_level_scene(current_level_scene, spawn_position)
    
    # 恢復動作佇列
    if reloaded_level:
        await _restore_action_queue(saved_action_queue)
    
    return reloaded_level
