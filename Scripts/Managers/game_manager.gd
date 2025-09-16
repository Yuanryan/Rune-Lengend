# GameManager.gd
# 遊戲管理器單例，專注於遊戲狀態管理和玩家實例記錄

extends Node

# 遊戲狀態枚舉
enum GameState {
    MAIN_MENU,
    LEVEL_SELECT,
    GAME_PLAY
}

# 玩家實例記錄
var player: Player = null
var player_scene: PackedScene = preload("uid://cviyl35yedewi")
# 遊戲狀態
var current_state: GameState = GameState.MAIN_MENU


# 信號
signal game_state_changed(new_state: GameState)
signal level_chosen(level_id: String)

func _ready() -> void:
    # 設置為自動載入單例
    pass

# 初始化遊戲
func initialize_game() -> void:
    UIManager.initialize_ui()
    _setup_level_manager_signals()
    set_game_state(GameState.MAIN_MENU)

# 設置 LevelManager 信號連接
func _setup_level_manager_signals() -> void:
    LevelManager.player_spawned.connect(_on_player_spawned)
    LevelManager.level_unloaded.connect(_on_level_unloaded)

# 玩家生成時更新引用
func _on_player_spawned(new_player: Player) -> void:
    player = new_player

# 關卡卸載時清理引用
func _on_level_unloaded() -> void:
    player = null

# 設置關卡選擇信號
func setup_level_select_signals(level_select_ui: LevelSelect) -> void:
    if level_select_ui:
        level_select_ui.level_chosen.connect(_on_level_chosen)
        level_select_ui.back_to_main_menu.connect(_on_back_to_main_menu)

# 遊戲狀態管理
func set_game_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    
    current_state = new_state
    game_state_changed.emit(new_state)
    
    match new_state:
        GameState.MAIN_MENU:
            UIManager.show_main_menu()
        GameState.LEVEL_SELECT:
            UIManager.show_level_select()
        GameState.GAME_PLAY:
            UIManager.show_game_ui()


# 信號處理
func _on_level_chosen(level_id: String) -> void:
    # 關卡載入由 LevelManager 處理
    LevelManager.load_level_by_id(level_id)
    set_game_state(GameState.GAME_PLAY)
    level_chosen.emit(level_id)

func _on_back_to_main_menu() -> void:
    set_game_state(GameState.MAIN_MENU)

# 設置玩家引用
func set_player(player_ref: Player) -> void:
    player = player_ref

func remove_player() -> void:
    if has_player():
        player.queue_free()
        player = null

# 獲取玩家引用
func get_player() -> Player:
    return player

# 檢查玩家是否存在
func has_player() -> bool:
    return player != null

# 處理ESC鍵輸入
func handle_escape_key() -> void:
    """處理ESC鍵返回主選單"""
    match current_state:
        GameState.LEVEL_SELECT:
            set_game_state(GameState.MAIN_MENU)
        GameState.GAME_PLAY:
            # 關卡卸載由 LevelManager 處理
            LevelManager.unload_level()
            set_game_state(GameState.LEVEL_SELECT)
