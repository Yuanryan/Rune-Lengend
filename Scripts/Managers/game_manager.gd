# GameManager.gd
# 遊戲管理器單例，專注於遊戲狀態管理和玩家實例記錄

extends Node

# 遊戲狀態枚舉
enum GameState {
    MAIN_MENU,
    LEVEL_SELECT,
    GAME_PLAY
}

# 遊戲內狀態枚舉
enum InGameState {
    PLANNING,      # 規劃階段：玩家可以拖拽卡片建立動作序列
    EXECUTING,     # 執行階段：動作正在執行中
    COMPLETED,     # 完成階段：動作執行完成
    PAUSED,        # 暫停階段：遊戲暫停
    FAILED,        # 失敗階段：玩家死亡或失敗
    VICTORY        # 勝利階段：關卡完成
}

# 玩家實例記錄
var player: Player = null
var player_scene: PackedScene = preload("uid://cviyl35yedewi")
var current_state: GameState = GameState.MAIN_MENU
var current_in_game_state: InGameState = InGameState.PLANNING
var in_game_state_before_pause: InGameState = InGameState.PLANNING

# 信號
signal game_state_changed(new_state: GameState)
signal in_game_state_changed(new_state: InGameState)
signal level_chosen(level_id: String)

func _ready() -> void:
    # 設置為自動載入單例
    pass

# 初始化遊戲
func initialize_game() -> void:
    UIManager.initialize_ui()
    _setup_level_manager_signals()
    set_game_state(GameState.MAIN_MENU)
    set_in_game_state(InGameState.PLANNING)

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
            # 進入遊戲時重置為規劃階段
            set_in_game_state(InGameState.PLANNING)
            # 播放遊玩關卡音樂
            MusicManager.play_gameplay_music()

# 遊戲內狀態管理
func set_in_game_state(new_state: InGameState) -> void:
    if current_in_game_state == new_state and new_state != InGameState.PLANNING:
        return
    
    current_in_game_state = new_state
    in_game_state_changed.emit(new_state)


# 輔助方法
func _get_state_name(state: InGameState) -> String:
    """獲取狀態名稱"""
    match state:
        InGameState.PLANNING:
            return "規劃階段"
        InGameState.EXECUTING:
            return "執行階段"
        InGameState.COMPLETED:
            return "完成階段"
        InGameState.PAUSED:
            return "暫停階段"
        InGameState.FAILED:
            return "失敗階段"
        _:
            return "未知狀態"


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

# 狀態檢查方法
func is_in_planning_state() -> bool:
    return current_in_game_state == InGameState.PLANNING

func is_in_executing_state() -> bool:
    return current_in_game_state == InGameState.EXECUTING

func is_in_completed_state() -> bool:
    return current_in_game_state == InGameState.COMPLETED

func is_in_paused_state() -> bool:
    return current_in_game_state == InGameState.PAUSED

func is_in_failed_state() -> bool:
    return current_in_game_state == InGameState.FAILED

# 狀態轉換方法
func start_execution() -> void:
    """開始執行動作序列"""
    if is_in_planning_state():
        set_in_game_state(InGameState.EXECUTING)

func complete_execution() -> void:
    """完成動作執行"""
    if is_in_executing_state():
        set_in_game_state(InGameState.COMPLETED)

func fail_execution() -> void:
    """動作執行失敗"""
    if is_in_executing_state():
        set_in_game_state(InGameState.FAILED)

func reset_to_planning() -> void:
    """重置到規劃階段"""
    set_in_game_state(InGameState.PLANNING)


func pause_game() -> void:
    """暫停遊戲"""
    in_game_state_before_pause = current_in_game_state
    set_in_game_state(InGameState.PAUSED)
    get_tree().paused = true
    MusicManager.change_music_volume(MusicManager.get_music_volume() / 2.0)
   

func resume_game() -> void:
    """恢復遊戲"""
    get_tree().set_deferred("paused", false)
    MusicManager.change_music_volume(MusicManager.get_music_volume() * 2.0)
    set_in_game_state(in_game_state_before_pause)

func achieve_victory() -> void:
    """達成勝利"""
    set_in_game_state(InGameState.VICTORY)

# 設置玩家相機優先級
func set_player_camera_priority(priority: int) -> void:
    """設置玩家相機的優先級"""
    if has_player() and player.player_camera and player.player_camera.activate:
        player.player_camera.priority = priority    
        player.player_camera.visible = true

# 設置玩家相機邊界
func set_player_camera_border_from_checkpoint_camera(camera: BorderedCamera) -> void:
    """從指定的 PhantomCamera2D 獲取邊界並設置到玩家相機"""
    if not has_player() or not player.player_camera:
        return
    
    # 查找 PhantomCamera2D 下的 CameraBorder 子節點
    if camera.camera_border:
        # 設置玩家相機的邊界
        player.player_camera.set_border(camera.camera_border)


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
