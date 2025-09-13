# LevelSelect.gd
# 關卡選擇頁面控制器

extends CanvasLayer
class_name LevelSelect

signal level_chosen(level_scene: PackedScene)
signal back_to_main_menu()

@onready var levels_container: GridContainer = %LevelsContainer
@onready var back_button: Button = %BackButton

# 關卡按鈕場景
const LEVEL_BUTTON_SCENE: PackedScene = preload("res://Scenes/UI/level_button.tscn")

# 動態載入的關卡配置
var level_configs: Array[Dictionary] = []

func _ready() -> void:
    # 連接信號
    _connect_signals()
    
    # 掃描關卡資料夾
    _scan_levels_folder()
    
    # 創建關卡按鈕
    _create_level_buttons()
    
    # 載入關卡進度 (暫時註釋掉，所有關卡都解鎖)
    # _load_level_progress()

func _connect_signals() -> void:
    if back_button:
        back_button.pressed.connect(_on_back_pressed)

func _scan_levels_folder() -> void:
    """掃描 Scenes/Levels 資料夾中的關卡場景"""
    level_configs.clear()
    
    var levels_dir = DirAccess.open("res://Scenes/Levels")
    if not levels_dir:
        push_error("無法開啟關卡資料夾: res://Scenes/Levels")
        return
    
    var level_number = 1
    levels_dir.list_dir_begin()
    var file_name = levels_dir.get_next()
    
    while file_name != "":
        if file_name.ends_with(".tscn") and file_name.begins_with("level_"):
            var scene_path = "res://Scenes/Levels/" + file_name
            var level_name = _get_level_name_from_filename(file_name)
            
            var config = {
                "number": level_number,
                "name": level_name,
                "scene_path": scene_path,
                "unlocked": true,  # 暫時讓所有關卡都解鎖
                "completed": false
            }
            
            level_configs.append(config)
            level_number += 1
        
        file_name = levels_dir.get_next()
    
    levels_dir.list_dir_end()
    
    # 按關卡編號排序
    level_configs.sort_custom(func(a, b): return a.number < b.number)
    
    print("掃描到 ", level_configs.size(), " 個關卡")

func _get_level_name_from_filename(filename: String) -> String:
    """從檔案名稱生成關卡名稱"""
    # 移除 .tscn 副檔名
    var level_name = filename.trim_suffix(".tscn")        
    return level_name

func _create_level_buttons() -> void:
    if not levels_container or not LEVEL_BUTTON_SCENE:
        push_error("無法創建關卡按鈕：缺少必要組件")
        return
    
    for config in level_configs:
        var button: LevelButton = LEVEL_BUTTON_SCENE.instantiate()
        if not button:
            push_error("無法實例化關卡按鈕")
            continue
        
        # 設置按鈕
        button.setup(
            config.number,
            config.name,
            config.unlocked,
            config.completed,
            config
        )
        
        # 連接信號
        button.level_selected.connect(_on_level_selected)
        
        # 添加到容器
        levels_container.add_child(button)

func _on_level_selected(config: Dictionary) -> void:
    print("選擇關卡: ", config.number, " - ", config.name)
    
    # 載入關卡場景
    var level_scene: PackedScene = load(config.scene_path)
    if not level_scene:
        push_error("無法載入關卡場景: " + config.scene_path)
        return
    
    # 發送信號
    level_chosen.emit(level_scene)

func _on_back_pressed() -> void:
    print("返回主選單")
    back_to_main_menu.emit()

# 暫時註釋掉關卡進度載入功能，所有關卡都解鎖
# func _load_level_progress() -> void:
#     # 從存檔載入關卡進度
#     # 這裡可以從 SaveGame 或 ConfigFile 載入實際的進度數據
#     var save_data = _load_save_data()
#     
#     if save_data.has("unlocked_levels"):
#         var unlocked_levels: Array = save_data.unlocked_levels
#         _update_unlocked_levels(unlocked_levels)
#     
#     if save_data.has("completed_levels"):
#         var completed_levels: Array = save_data.completed_levels
#         _update_completed_levels(completed_levels)

# func _update_unlocked_levels(unlocked_levels: Array) -> void:
#     for button in levels_container.get_children():
#         if button is LevelButton:
#             var level_num = button.get_level_number()
#             button.set_unlocked(level_num in unlocked_levels)

# func _update_completed_levels(completed_levels: Array) -> void:
#     for button in levels_container.get_children():
#         if button is LevelButton:
#             var level_num = button.get_level_number()
#             button.set_completed(level_num in completed_levels)

# func _load_save_data() -> Dictionary:
#     # 載入存檔數據
#     var save_data = {
#         "unlocked_levels": [1],  # 預設只有第一關解鎖
#         "completed_levels": []
#     }
#     
#     # 這裡可以從實際的存檔文件載入
#     # var config = ConfigFile.new()
#     # if config.load("user://savegame.cfg") == OK:
#     #     save_data = config.get_value("progress", "levels", save_data)
#     
#     return save_data

# 暫時註釋掉解鎖和完成關卡功能，所有關卡都解鎖
# func unlock_level(level_number: int) -> void:
#     """解鎖指定關卡"""
#     for button in levels_container.get_children():
#         if button is LevelButton and button.get_level_number() == level_number:
#             button.set_unlocked(true)
#             break

# func complete_level(level_number: int) -> void:
#     """標記關卡為已完成"""
#     for button in levels_container.get_children():
#         if button is LevelButton and button.get_level_number() == level_number:
#             button.set_completed(true)
#             # 自動解鎖下一關
#             unlock_level(level_number + 1)
#             break

func get_level_config(level_number: int) -> Dictionary:
    """獲取指定關卡的配置"""
    for config in level_configs:
        if config.number == level_number:
            return config
    return {}

func show_level_select() -> void:
    """顯示關卡選擇頁面"""
    visible = true
    process_mode = Node.PROCESS_MODE_INHERIT

func hide_level_select() -> void:
    """隱藏關卡選擇頁面"""
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED
