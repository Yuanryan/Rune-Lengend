extends CanvasLayer


@onready var card_deck: CardDeck = %CardDeck
@onready var action_queue: QueuePanel = %ActionQueue
@onready var execute_button: Button = %ExecuteButton
@onready var clear_button: Button = %ClearButton
@onready var reset_button: Button = %ResetButton
@onready var info_label: Label = %InfoLabel


func _ready() -> void:
    _connect_signals.call_deferred()
    _update_ui.call_deferred()
    _connect_game_manager_signals()

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

func _connect_game_manager_signals() -> void:
    """連接 GameManager 的狀態變化信號"""
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _on_card_selected(card: CardTile) -> void:
    """當卡片被點擊時，將其添加到動作佇列末尾"""
    if not action_queue or not card:
        return
    
    # 使用 QueuePanel 的 add_card_at_tail 方法將卡片添加到佇列末尾
    action_queue.add_card_at_tail(card)

func _on_action_added(action_type: Action.ActionType, index: int) -> void:
    print("Action added to queue: ", action_type, " at index ", index)
    _update_ui()

func _on_action_removed(action_type: Action.ActionType, index: int) -> void:
    print("Action removed from queue: ", action_type, " at index ", index)
    _update_ui()

func _on_queue_cleared() -> void:
    _update_ui()

func _on_execute_pressed() -> void:
    execute_button.release_focus()
    execute_sequence()

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    print("InGameUI: 遊戲內狀態變更為 ", new_state)
    
    # 根據狀態執行相應的處理
    # 當狀態不是執行中且不是暫停時，解鎖佇列允許修改
    if new_state != GameManager.InGameState.EXECUTING and new_state != GameManager.InGameState.PAUSED:
        if action_queue:
            action_queue.unlock_queue() 
    _update_ui()

func _on_clear_pressed() -> void:
    clear_button.release_focus()
    clear_sequence()

func _on_reset_pressed() -> void:
    reset_button.release_focus()
    reset_player()

func execute_sequence() -> void:
    if action_queue:
        var actions = action_queue.get_action_descriptors()
        print("Actions: ", actions)
        if actions.size() > 0:
            print("Executing sequence with ", actions.size(), " actions")
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
    """重新載入關卡並保持動作佇列"""
    # 停止玩家正在執行的動作
    var player = GameManager.get_player()
    if player:
        player.interrupt_current_action()
        player.is_executing_actions = false
    
    # 解鎖隊列（如果被鎖定的話）
    if action_queue:
        action_queue.unlock_queue()
        action_queue.clear_executing_action()
    
    # 重置到規劃階段
    GameManager.reset_to_planning()
    
    # 重新載入關卡（LevelManager會自動保存和恢復動作佇列）
    LevelManager.reload_level_from_last_checkpoint()

func restore_action_queue(action_descriptors: Array) -> void:
    """恢復動作佇列（由LevelManager調用）"""
    if action_queue:
        action_queue.restore_action_queue(action_descriptors)
    _update_ui()

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
    
    # 更新信息標籤
    if info_label:
        match current_state:
            GameManager.InGameState.PLANNING:
                if action_count == 0:
                    info_label.text = "Drag cards from above to build your action sequence"
                else:
                    info_label.text = "Ready to execute " + str(action_count) + " actions"
            GameManager.InGameState.EXECUTING:
                info_label.text = "Executing actions... Queue is locked"
            GameManager.InGameState.COMPLETED:
                info_label.text = "Actions completed! You can reset or plan new actions"
            GameManager.InGameState.FAILED:
                info_label.text = "Execution failed! You can reset or plan new actions"
            GameManager.InGameState.PAUSED:
                info_label.text = "Game is paused"

func _show_message(text: String) -> void:
    if info_label:
        var original_text = info_label.text
        info_label.text = text
        info_label.modulate = Color.RED
        
        # Reset after 2 seconds
        await get_tree().create_timer(2.0).timeout
        info_label.text = original_text
        info_label.modulate = Color.WHITE
