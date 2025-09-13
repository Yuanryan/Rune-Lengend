# GameManager.gd
# 遊戲管理器單例，用於管理全域遊戲狀態和玩家引用

extends Node

# 遊戲狀態枚舉
enum GameState {
    MAIN_MENU,
    LEVEL_SELECT,
    GAME_PLAY
}

# 玩家引用
var player: Player = null
# 當前關卡引用
var current_level: Level = null
# 玩家場景資源
const player_scene: PackedScene = preload("uid://cviyl35yedewi")

# 遊戲狀態
var current_state: GameState = GameState.MAIN_MENU


# 信號
signal game_state_changed(new_state: GameState)
signal level_chosen(level_scene: PackedScene)

func _ready() -> void:
    # 設置為自動載入單例
    pass

# 初始化遊戲
func initialize_game() -> void:
    UIManager.initialize_ui()
    set_game_state(GameState.MAIN_MENU)

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


# 載入關卡
func load_level(level_scene: PackedScene) -> Level:
    # 清除當前關卡
    if current_level:
        current_level.queue_free()
        current_level = null
        player = null
    
    # 載入新關卡
    current_level = level_scene.instantiate()
    if not current_level:
        push_error("無法載入關卡場景")
        return null
    
    # 將關卡加入場景樹
    get_tree().current_scene.add_child(current_level)
    
    # 生成玩家
    if player_scene :
        player = current_level.spawn_player(player_scene)
    
    print("關卡已載入: ", current_level.name)
    return current_level

# 卸載關卡
func unload_level() -> void:
    if current_level:
        current_level.queue_free()
        current_level = null
        player = null
        print("關卡已卸載")

# 信號處理
func _on_level_chosen(level_scene: PackedScene) -> void:
    load_level(level_scene)
    set_game_state(GameState.GAME_PLAY)
    level_chosen.emit(level_scene)

func _on_back_to_main_menu() -> void:
    set_game_state(GameState.MAIN_MENU)

# 設置玩家引用
func set_player(player_ref: Player) -> void:
    player = player_ref

# 獲取玩家引用
func get_player() -> Player:
    return player

# 獲取當前關卡
func get_current_level() -> Level:
    return current_level

# 檢查玩家是否存在
func has_player() -> bool:
    return player != null

# 檢查關卡是否已載入
func has_level() -> bool:
    return current_level != null

# 處理ESC鍵輸入
func handle_escape_key() -> void:
    """處理ESC鍵返回主選單"""
    match current_state:
        GameState.LEVEL_SELECT:
            set_game_state(GameState.MAIN_MENU)
        GameState.GAME_PLAY:
            # 卸載關卡並返回關卡選擇
            unload_level()
            set_game_state(GameState.LEVEL_SELECT)
