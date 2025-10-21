extends CanvasLayer


signal transition_screen_covered
signal transition_finished

@onready var card_deck: CardDeck = %CardDeck
@onready var action_queue: QueuePanel = %ActionQueue
@onready var execute_button: Button = %ExecuteButton
@onready var clear_button: Button = %ClearButton
@onready var reset_button: Button = %ResetButton
@onready var menu_button: Button = %MenuButton
@onready var full_screen: Button = %FullScreenButton
@onready var info_label: Label = %InfoLabel
@onready var trans_animator: AnimationPlayer = %TransAnimator

# 過渡狀態追蹤
var is_transitioning: bool = false
var pending_reset: bool = false

func _ready() -> void:
    _connect_signals.call_deferred()
    _update_ui.call_deferred()
    _connect_game_manager_signals()
    _setup_card_deck_reference()
    update_fullscreen_button_text()

func _connect_signals() -> void:
    # Connect queue signals
    if action_queue:
        action_queue.action_added.connect(_on_action_added)
        action_queue.action_removed.connect(_on_action_removed)
        action_queue.queue_cleared.connect(_on_queue_cleared)
    
    # Connect card deck signals
    if card_deck:
        card_deck.card_selected.connect(_on_card_selected)
    
    # Connect button signals
    if execute_button:
        execute_button.pressed.connect(_on_execute_pressed)
    if clear_button:
        clear_button.pressed.connect(_on_clear_pressed)
    if reset_button:
        reset_button.pressed.connect(_on_reset_pressed)
    if menu_button:
        menu_button.pressed.connect(_on_menu_pressed)
    if full_screen:
        full_screen.pressed.connect(_on_fullscreen_pressed)
    

func _connect_game_manager_signals() -> void:
    """連接 GameManager 的狀態變化信號"""
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _setup_card_deck_reference() -> void:
    """設置卡片組引用到動作佇列"""
    # 這個方法現在在 create_cards_from_level_resource 中調用
    pass

func _on_card_selected(card: CardTile) -> void:
    """當卡片被點擊時，將其添加到動作佇列末尾"""
    if not action_queue or not card:
        return
    
    # 使用 QueuePanel 的 add_card_at_tail 方法將卡片添加到佇列末尾
    action_queue.add_card_at_tail(card)

func _on_action_added(action_type: Action.ActionType, index: int) -> void:
    _update_ui()

func _on_action_removed(action_type: Action.ActionType, index: int) -> void:
    _update_ui()

func _on_queue_cleared() -> void:
    _update_ui()

func _on_execute_pressed() -> void:
    execute_button.release_focus()
    execute_sequence()

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    
    # 根據狀態執行相應的處理
    # 當狀態不是執行中且不是暫停時，解鎖佇列允許修改
    if new_state != GameManager.InGameState.EXECUTING and new_state != GameManager.InGameState.PAUSED:
        if action_queue:
            action_queue.unlock_queue() 
    
    # 勝利狀態時禁用所有按鈕
    if new_state == GameManager.InGameState.VICTORY:
        disable_buttons()
    
    _update_ui()

func _on_clear_pressed() -> void:
    clear_button.release_focus()
    clear_sequence()

func _on_reset_pressed() -> void:
    reset_button.release_focus()
    reset_player()

func _on_menu_pressed() -> void:
    menu_button.release_focus()
    LevelManager.unload_level()
    GameManager.set_game_state(GameManager.GameState.LEVEL_SELECT)

func _on_fullscreen_pressed() -> void:
    full_screen.release_focus()
    UIManager.toggle_fullscreen()

func update_fullscreen_button_text() -> void:
    """更新全螢幕按鈕文字（由UIManager調用）"""
    if full_screen:
        full_screen.text = UIManager.get_fullscreen_button_text()

func execute_sequence() -> void:
    if action_queue:
        var actions = action_queue.get_action_descriptors()
        if actions.size() > 0:
            # 鎖定隊列防止修改
            action_queue.lock_queue()
            GameManager.get_player().load_actions_from_ui(actions)
            # 使用新的狀態系統
            GameManager.start_execution()
            _update_ui()
        else:
            print("No actions in queue to execute")
            _show_message("No actions in queue!")

func clear_sequence() -> void:
    if action_queue:
        action_queue.clear_queue()

func reset_player() -> void:
    """重新載入關卡並保持動作佇列，播放過渡動畫"""
    if is_transitioning:
        return  # 如果正在過渡中，忽略重置請求
    
    # 設置過渡狀態
    is_transitioning = true
    pending_reset = true
    
    # 鎖定玩家控制
    _lock_player_control()
    
    # 播放過渡動畫
    trans_animator.play("Transition/Diagonal Wipe")

func _on_transition_covered() -> void:
    """當過渡動畫覆蓋螢幕時觸發"""
    transition_screen_covered.emit()
    
    # 如果有待處理的重置，現在執行
    if pending_reset:
        _execute_level_reset()

func _on_transition_finished() -> void:
    """當過渡動畫完成時觸發"""
    transition_finished.emit()
    
    # 解鎖玩家控制
    _unlock_player_control()
    
    # 重置過渡狀態
    is_transitioning = false
    pending_reset = false

func _execute_level_reset() -> void:
    """執行實際的關卡重置"""
    # 停止玩家正在執行的動作
    var player = GameManager.get_player()
    if player:
        player.interrupt_current_action()
        player.is_executing_actions = false
    
    # 解鎖隊列（如果被鎖定的話）
    if action_queue:
        action_queue.unlock_queue()
        action_queue.clear_executing_action()
    
    # 重置動作使用計數
    if card_deck:
        card_deck.reset_action_usage()
    
    # 重置到規劃階段
    GameManager.reset_to_planning()
    
    # 重新載入關卡（LevelManager會自動保存和恢復動作佇列）
    LevelManager.reload_level_from_last_checkpoint()

func _lock_player_control() -> void:
    """鎖定玩家控制"""
    var player = GameManager.get_player()
    if player:
        # 禁用玩家輸入
        player.set_process_input(false)
        player.set_physics_process(false)
    
    # 禁用所有按鈕
    disable_buttons()

func _unlock_player_control() -> void:
    """解鎖玩家控制"""
    var player = GameManager.get_player()
    if player:
        # 重新啟用玩家輸入
        player.set_process_input(true)
        player.set_physics_process(true)
    
    # 重新啟用按鈕
    enable_buttons()

func restore_action_queue(action_descriptors: Array) -> void:
    """恢復動作佇列（由LevelManager調用）"""
    if action_queue:
        action_queue.restore_action_queue(action_descriptors)
    
    # 恢復動作使用計數
    if card_deck:
        _restore_action_usage_count(action_descriptors)
    
    _update_ui()

func _restore_action_usage_count(action_descriptors: Array) -> void:
    """恢復動作使用計數"""
    if not card_deck:
        return
    
    # 重置計數
    card_deck.reset_action_usage()
    
    # 根據動作描述恢復使用計數
    for desc in action_descriptors:
        var action_type: Action.ActionType = desc.get("action_type", -1)
        if action_type != -1:
            card_deck.use_action(action_type)

func disable_buttons() -> void:
    execute_button.disabled = true
    clear_button.disabled = true

    
func enable_buttons() -> void:
    execute_button.disabled = false
    clear_button.disabled = false
    reset_button.disabled = false

func unlock_buttons_after_execute() -> void:
    execute_button.disabled = true # 執行完動作後，按鈕不能被按
    clear_button.disabled = false
    reset_button.disabled = false
    # 解鎖隊列允許修改
    if action_queue:
        action_queue.unlock_queue()

func _update_ui() -> void:
    var action_count = action_queue.get_action_count() if action_queue else 0
    var current_state = GameManager.current_in_game_state
    
    # 獲取動作使用信息
    var usage_info = {}
    if card_deck:
        usage_info = card_deck.get_action_usage_info()
    
    # 根據當前狀態更新按鈕狀態
    match current_state:
        GameManager.InGameState.PLANNING:
            # 規劃階段：根據動作數量決定按鈕狀態
            if execute_button:
                execute_button.disabled = action_count == 0
            if clear_button:
                clear_button.disabled = action_count == 0
            if reset_button:
                reset_button.disabled = false
                
        GameManager.InGameState.EXECUTING:
            # 執行階段：禁用所有按鈕
            if execute_button:
                execute_button.disabled = true
            if clear_button:
                clear_button.disabled = true
            if reset_button:
                reset_button.disabled = false
                
        GameManager.InGameState.COMPLETED:
            # 完成階段：執行按鈕禁用，其他可用
            if execute_button:
                execute_button.disabled = true
            if clear_button:
                clear_button.disabled = false
            if reset_button:
                reset_button.disabled = false
                
        GameManager.InGameState.FAILED:
            # 失敗階段：執行按鈕禁用，其他可用
            if execute_button:
                execute_button.disabled = true
            if clear_button:
                clear_button.disabled = false
            if reset_button:
                reset_button.disabled = false
                
        GameManager.InGameState.VICTORY:
            # 勝利階段：禁用所有按鈕
            if execute_button:
                execute_button.disabled = true
            if clear_button:
                clear_button.disabled = true
            if reset_button:
                reset_button.disabled = true
    
    # 更新信息標籤
    if info_label:
        match current_state:
            GameManager.InGameState.PLANNING:
                if action_count == 0:
                    var usage_text = _get_usage_text(usage_info)
                    info_label.text = "Drag cards from above to build your action sequence" + usage_text
                else:
                    var usage_text = _get_usage_text(usage_info)
                    info_label.text = "Ready to execute " + str(action_count) + " actions" + usage_text
            GameManager.InGameState.EXECUTING:
                info_label.text = "Executing actions... Queue is locked"
            GameManager.InGameState.COMPLETED:
                info_label.text = "Actions completed! You can reset or plan new actions"
            GameManager.InGameState.FAILED:
                info_label.text = "Execution failed! You can reset or plan new actions"
            GameManager.InGameState.PAUSED:
                info_label.text = "Game is paused"
            GameManager.InGameState.VICTORY:
                info_label.text = "Level completed! Congratulations!"

func _get_usage_text(usage_info: Dictionary) -> String:
    """獲取使用限制文本"""
    if usage_info.is_empty():
        return ""
    
    var total_used = usage_info.get("total_used", 0)
    var total_max = usage_info.get("total_max", 0)
    
    if total_max > 0:
        return " (" + str(total_used) + "/" + str(total_max) + " actions used)"
    
    return ""

func _show_message(text: String) -> void:
    if info_label:
        var original_text = info_label.text
        info_label.text = text
        info_label.modulate = Color.RED
        
        # Reset after 2 seconds
        await get_tree().create_timer(2.0).timeout
        info_label.text = original_text
        info_label.modulate = Color.WHITE
