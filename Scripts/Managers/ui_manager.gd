# UIManager.gd
# UI管理器，負責管理所有UI的顯示和隱藏

extends Node

# UI引用
var main_menu_ui: MainMenu = null
var in_game_ui: CanvasLayer = null
var level_select: LevelSelect = null
var victory_ui: CanvasLayer = null

# 當前顯示的UI
var current_ui: Node = null


# 設置UI引用
func set_ui_references(main_menu: MainMenu, level_select_ui: LevelSelect, game_ui: CanvasLayer, victory_ui_ref: CanvasLayer = null) -> void:
    main_menu_ui = main_menu
    level_select = level_select_ui
    in_game_ui = game_ui
    victory_ui = victory_ui_ref

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
    
    if victory_ui:
        victory_ui.visible = false
        victory_ui.process_mode = Node.PROCESS_MODE_DISABLED
    
    # 連接GameManager信號
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)
    

# 顯示主選單
func show_main_menu() -> void:
    """顯示主選單UI"""
    _hide_all_ui()
    if main_menu_ui:
        main_menu_ui.show_main_menu()
        current_ui = main_menu_ui

# 顯示關卡選擇
func show_level_select() -> void:
    """顯示關卡選擇UI"""
    _hide_all_ui()
    if level_select:
        level_select.show_level_select()
        current_ui = level_select
# 顯示遊戲UI
func show_game_ui() -> void:
    """顯示遊戲內UI"""
    _hide_all_ui()
    if in_game_ui:
        in_game_ui.visible = true
        in_game_ui.process_mode = Node.PROCESS_MODE_INHERIT
        current_ui = in_game_ui

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


# 從關卡創建卡片
func create_cards_from_level(level: Level) -> void:
    """根據關卡資源創建卡片"""
    if not level or not level.level_resource:
        push_error("關卡或關卡資源不存在，無法創建卡片")
        return
    if in_game_ui:
        in_game_ui.card_deck.create_cards_from_level_resource(level.level_resource)
        # 連接卡片組到動作佇列以監聽變化
        if in_game_ui.action_queue:
            in_game_ui.card_deck.connect_to_action_queue(in_game_ui.action_queue)

func get_in_game_ui() -> CanvasLayer:
    """獲取遊戲內UI"""
    return in_game_ui

# 顯示勝利UI
func show_victory() -> void:
    """顯示勝利UI"""
    if victory_ui:
        victory_ui.process_mode = Node.PROCESS_MODE_INHERIT
        victory_ui.show_victory()
        # 連接返回按鈕信號
        if not victory_ui.return_to_level_select_requested.is_connected(_on_return_to_level_select_requested):
            victory_ui.return_to_level_select_requested.connect(_on_return_to_level_select_requested)

# 隱藏勝利UI
func hide_victory() -> void:
    """隱藏勝利UI"""
    if victory_ui:
        victory_ui.hide_victory()
        victory_ui.process_mode = Node.PROCESS_MODE_DISABLED

# 處理遊戲內狀態變化
func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """響應遊戲內狀態變化"""
    match new_state:
        GameManager.InGameState.VICTORY:
            show_victory()
        _:
            # 其他狀態時隱藏勝利UI
            if victory_ui and victory_ui.visible:
                hide_victory()

# 處理返回關卡選擇請求
func _on_return_to_level_select_requested() -> void:
    """當勝利UI的返回按鈕被按下時"""
    # 隱藏勝利UI
    hide_victory()
    
    # 卸載當前關卡
    LevelManager.unload_level()
    
    # 設置遊戲狀態為關卡選擇
    GameManager.set_game_state(GameManager.GameState.LEVEL_SELECT)
    
    print("已回到關卡選擇畫面")
