# MainScene.gd
# 主場景控制器，負責設置UI引用和處理輸入

extends Node2D

@onready var main_menu_ui: MainMenu = %MainMenu
@onready var level_select: LevelSelect = %LevelSelect
@onready var in_game_ui: CanvasLayer = %InGameUI

func _ready() -> void:
    UIManager.set_ui_references(main_menu_ui, level_select, in_game_ui)
    
    GameManager.setup_level_select_signals(level_select)
    GameManager.initialize_game()

func _input(event: InputEvent) -> void:
    # 處理ESC鍵返回主選單
    if event.is_action_pressed("ui_cancel") and GameManager:
        GameManager.handle_escape_key()
