# LevelButton.gd
# 關卡選擇按鈕組件

extends Button
class_name LevelButton

signal level_selected(level_config: Dictionary)

@onready var level_number_label: Label = %LevelNumber
@onready var level_name_label: Label = %LevelName
@onready var status_label: Label = %StatusLabel
@onready var lock_icon: Label = %LockIcon

var level_number: int = 1
var level_name: String = ""
var is_unlocked: bool = false
var is_completed: bool = false
var level_config: Dictionary = {}

func _ready() -> void:
    # 連接按鈕信號
    pressed.connect(_on_button_pressed)
    
    # 更新UI顯示
    _update_display()

func setup(level_num: int, level_title: String, unlocked: bool = false, completed: bool = false, config: Dictionary = {}) -> void:
    level_number = level_num
    level_name = level_title
    is_unlocked = unlocked
    is_completed = completed
    level_config = config
    
    _update_display()

func _update_display() -> void:
    # 更新標籤文字
    if level_number_label:
        level_number_label.text = str(level_number)
    
    if level_name_label:
        level_name_label.text = level_name
    
    # 更新狀態顯示
    if status_label:
        if is_completed:
            status_label.text = "已完成"
            status_label.modulate = Color.GREEN
        elif is_unlocked:
            status_label.text = "可遊玩"
            status_label.modulate = Color.WHITE
        else:
            status_label.text = "未解鎖"
            status_label.modulate = Color.GRAY
    
    # 更新鎖定圖示
    if lock_icon:
        lock_icon.visible = not is_unlocked
    
    # 更新按鈕狀態
    disabled = not is_unlocked
    
    # 更新按鈕顏色
    if is_completed:
        modulate = Color(0.8, 1.0, 0.8, 1.0)  # 淡綠色表示已完成
    elif is_unlocked:
        modulate = Color.WHITE
    else:
        modulate = Color(0.5, 0.5, 0.5, 1.0)  # 灰色表示未解鎖

func _on_button_pressed() -> void:
    if is_unlocked:
        level_selected.emit(level_config)
        print("選擇關卡: ", level_number, " - ", level_name)

func set_unlocked(unlocked: bool) -> void:
    is_unlocked = unlocked
    _update_display()

func set_completed(completed: bool) -> void:
    is_completed = completed
    _update_display()

func get_level_number() -> int:
    return level_number

func get_level_name() -> String:
    return level_name

func is_level_unlocked() -> bool:
    return is_unlocked

func is_level_completed() -> bool:
    return is_completed
