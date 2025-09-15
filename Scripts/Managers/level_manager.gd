# LevelManager.gd
# 關卡管理器單例，負責載入和管理關卡資源
extends Node

# 當前關卡資源
var current_level_resource = null
var current_level: Level = null


# 關卡資源字典
var level_resources: Dictionary = {}

# 信號
signal level_loaded(level_scene: Level)
signal level_unloaded()
signal player_spawned(player: Player)

func _ready() -> void:
    _initialize_level_resources()

# 初始化關卡資源
func _initialize_level_resources() -> void:
    _scan_and_load_levels()
    print("已初始化 %d 個關卡資源" % level_resources.size())

# 掃描並載入所有關卡
func _scan_and_load_levels() -> void:
    var resources_dir = "res://Resources/Levels/"
    
    # 掃描資源檔案
    var resource_files = _get_files_in_directory(resources_dir, ".tres")
    
    for resource_file in resource_files:
        var level_name = resource_file.replace(".tres", "")  # 例如: "level_1"
        var resource_path = resources_dir + resource_file
        _load_level_from_resource(level_name, resource_path)

# 從資源檔案載入關卡
func _load_level_from_resource(level_id: String, resource_path: String) -> void:
    # 檢查檔案是否存在
    if not FileAccess.file_exists(resource_path):
        print("關卡資源檔案不存在: ", resource_path)
        return
    

    # 載入關卡資源
    var resource = load(resource_path)
    if not resource:
        print("無法載入關卡資源: ", resource_path)
        return
    
    # 檢查資源是否有必要的屬性
    if not resource.has_method("get_level_info"):
        print("關卡資源格式不正確，缺少 get_level_info 方法: ", resource_path)
        return
    
    # 檢查資源中是否包含場景
    if not resource.level_scene:
        print("警告: 關卡資源中沒有設定場景: ", resource_path)
        return
    
    # 儲存到關卡資源字典
    level_resources[level_id] = resource
    print("已載入關卡: %s (資源: %s)" % [level_id, resource_path])

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
    for level_id in level_resources.keys():
        ids.append(level_id)
    ids.sort()
    return ids

# ========== 核心功能 ==========

# 載入關卡（通過關卡 ID）
func load_level_by_id(level_id: String) -> Level:
    if level_id not in level_resources:
        push_error("找不到關卡: " + level_id)
        return null
    
    var level_resource = level_resources[level_id]
    if not level_resource.level_scene:
        push_error("關卡資源中沒有設定場景: " + level_id)
        return null
    
    return load_level_scene(level_resource.level_scene, level_resource)

# 載入關卡場景
func load_level_scene(level_scene: PackedScene, level_resource = null) -> Level:
    # 清除當前關卡
    if current_level:
        current_level.queue_free()
        current_level = null
        GameManager.remove_player()
    
    # 載入新關卡
    current_level = level_scene.instantiate()
    if not current_level:
        push_error("無法載入關卡場景")
        return null
    
    # 設定當前關卡資源
    current_level_resource = level_resource
    
    # 將關卡加入場景樹
    get_tree().current_scene.add_child(current_level)
    
    level_loaded.emit(current_level)
    print("關卡已載入: ", current_level.name)
    return current_level

# 卸載關卡
func unload_level() -> void:
    if current_level:
        current_level.queue_free()
        current_level = null
        GameManager.remove_player()
        current_level_resource = null
        level_unloaded.emit()
        print("關卡已卸載")

# 獲取當前關卡
func get_current_level() -> Level:
    return current_level

# 獲取當前關卡資源
func get_current_level_resource():
    return current_level_resource

# 獲取關卡資源
func get_level_resource(level_id: String):
    if level_id in level_resources:
        return level_resources[level_id]
    return null
