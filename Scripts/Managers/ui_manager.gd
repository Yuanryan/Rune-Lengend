# UIManager.gd
# UI管理器，負責管理所有UI的顯示和隱藏

extends Node

# UI引用
var main_menu_ui: MainMenu = null
var in_game_ui: CanvasLayer = null
var level_select: LevelSelect = null

# 當前顯示的UI
var current_ui: Node = null


# 設置UI引用
func set_ui_references(main_menu: MainMenu, level_select_ui: LevelSelect, game_ui: CanvasLayer) -> void:
    main_menu_ui = main_menu
    level_select = level_select_ui
    in_game_ui = game_ui

# 初始化UI狀態
func initialize_ui() -> void:
    """初始化所有UI的狀態"""
    if main_menu_ui:
        main_menu_ui.visible = true
        main_menu_ui.process_mode = Node.PROCESS_MODE_INHERIT
    
    if in_game_ui:
        in_game_ui.visible = false
        in_game_ui.process_mode = Node.PROCESS_MODE_DISABLED
    
    if level_select:
        level_select.visible = false
        level_select.process_mode = Node.PROCESS_MODE_DISABLED

# 顯示主選單
func show_main_menu() -> void:
    """顯示主選單UI"""
    _hide_all_ui()
    if main_menu_ui:
        main_menu_ui.show_main_menu()
        current_ui = main_menu_ui
    print("顯示主選單")

# 顯示關卡選擇
func show_level_select() -> void:
    """顯示關卡選擇UI"""
    _hide_all_ui()
    if level_select:
        level_select.show_level_select()
        current_ui = level_select
    print("顯示關卡選擇")

# 顯示遊戲UI
func show_game_ui() -> void:
    """顯示遊戲內UI"""
    _hide_all_ui()
    if in_game_ui:
        in_game_ui.visible = true
        in_game_ui.process_mode = Node.PROCESS_MODE_INHERIT
        current_ui = in_game_ui
    print("顯示遊戲UI")

# 隱藏所有UI
func _hide_all_ui() -> void:
    """隱藏所有UI"""
    if main_menu_ui:
        main_menu_ui.hide_main_menu()
    
    if level_select:
        level_select.hide_level_select()
    
    if in_game_ui:
        in_game_ui.visible = false
        in_game_ui.process_mode = Node.PROCESS_MODE_DISABLED

# 獲取當前UI
func get_current_ui() -> Node:
    return current_ui

# 檢查UI是否可見
func is_ui_visible(ui: Node) -> bool:
    if ui == main_menu_ui:
        return main_menu_ui.visible if main_menu_ui else false
    elif ui == level_select:
        return level_select.visible if level_select else false
    elif ui == in_game_ui:
        return in_game_ui.visible if in_game_ui else false
    return false
