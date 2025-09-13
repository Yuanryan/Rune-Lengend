# MainMenu.gd
# 主選單UI控制器

extends CanvasLayer
class_name MainMenu

@onready var start_button: Button = %StartButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
    # 連接按鈕信號
    _connect_signals()

func _connect_signals() -> void:
    if start_button:
        start_button.pressed.connect(_on_start_pressed)
    
    if exit_button:
        exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
    """開始遊戲按鈕被點擊"""
    print("開始遊戲")
    if GameManager:
        GameManager.set_game_state(GameManager.GameState.LEVEL_SELECT)

func _on_exit_pressed() -> void:
    """退出遊戲按鈕被點擊"""
    print("退出遊戲")
    get_tree().quit()

func show_main_menu() -> void:
    """顯示主選單"""
    visible = true
    process_mode = Node.PROCESS_MODE_INHERIT

func hide_main_menu() -> void:
    """隱藏主選單"""
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED