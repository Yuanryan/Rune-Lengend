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

func _ready() -> void:
    # 連接信號
    _connect_signals()
    
    # 創建關卡按鈕
    _create_level_buttons()

func _connect_signals() -> void:
    if back_button:
        back_button.pressed.connect(_on_back_pressed)


func _create_level_buttons() -> void:
    if not levels_container or not LEVEL_BUTTON_SCENE:
        push_error("無法創建關卡按鈕：缺少必要組件")
        return
    
    # 從 LevelManager 獲取所有關卡 ID
    var level_ids = LevelManager.get_all_level_ids()
    
    for i in range(level_ids.size()):
        var level_id = level_ids[i]
        var level_resource = LevelManager.get_level_resource(level_id)
        
        if not level_resource:
            continue
        
        var button: LevelButton = LEVEL_BUTTON_SCENE.instantiate()
        if not button:
            push_error("無法實例化關卡按鈕")
            continue
        
        # 創建配置
        var config = {
            "level_id": level_id,
            "level_resource": level_resource,
            "unlocked": true,  # 暫時讓所有關卡都解鎖
            "completed": false
        }
        
        # 設置按鈕
        button.setup(
            i + 1,  # 關卡編號
            level_resource.level_name,
            config.unlocked,
            config.completed,
            config
        )
        
        # 連接信號
        button.level_selected.connect(_on_level_selected)
        
        # 添加到容器
        levels_container.add_child(button)

func _on_level_selected(config: Dictionary) -> void:
    var level_id = config.level_id
    var level_resource = config.level_resource
    print("選擇關卡: ", level_id, " - ", level_resource.level_name)
    
    # 直接使用 LevelManager 載入關卡
    var level_scene = level_resource.level_scene
    if not level_scene:
        push_error("關卡資源中沒有設定場景: " + level_id)
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


func show_level_select() -> void:
    """顯示關卡選擇頁面"""
    visible = true
    process_mode = Node.PROCESS_MODE_INHERIT

func hide_level_select() -> void:
    """隱藏關卡選擇頁面"""
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED
