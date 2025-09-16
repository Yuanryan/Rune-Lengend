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
func load_level_scene(level_scene: PackedScene) -> Level:
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
    
    # 保存當前動作佇列狀態（從UI獲取，因為玩家可能正在執行動作）
    var saved_action_queue = []
    var in_game_ui = UIManager.get_in_game_ui()
    if in_game_ui and in_game_ui.action_queue:
        saved_action_queue = in_game_ui.action_queue.get_action_types()
    
    # 重新載入關卡
    var reloaded_level = load_level_scene(current_level_scene)
    
    # 恢復動作佇列
    if reloaded_level and saved_action_queue.size() > 0:
        # 等待一幀確保UI已經準備好
        await get_tree().process_frame
        in_game_ui = UIManager.get_in_game_ui()
        if in_game_ui:
            in_game_ui.restore_action_queue(saved_action_queue)
    
    return reloaded_level
