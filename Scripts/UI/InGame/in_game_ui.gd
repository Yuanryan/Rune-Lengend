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

func _connect_signals() -> void:
    # Connect palette signals
    # if card_deck:
    #     card_deck.card_selected.connect(_on_card_selected)
    
    # Connect queue signals
    if action_queue:
        action_queue.action_added.connect(_on_action_added)
        action_queue.action_removed.connect(_on_action_removed)
        action_queue.queue_cleared.connect(_on_queue_cleared)
    
    # Connect button signals
    if execute_button:
        execute_button.pressed.connect(_on_execute_pressed)
    if clear_button:
        clear_button.pressed.connect(_on_clear_pressed)
    if reset_button:
        reset_button.pressed.connect(_on_reset_pressed)

func _on_card_selected(card: CardTile) -> void:
    pass

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

func _on_clear_pressed() -> void:
    clear_button.release_focus()
    clear_sequence()

func _on_reset_pressed() -> void:
    reset_button.release_focus()
    reset_player()

func execute_sequence() -> void:
    if action_queue and GameManager.get_player():
        var actions = action_queue.get_action_types()
        print("Actions: ", actions)
        if actions.size() > 0:
            print("Executing sequence with ", actions.size(), " actions")
            GameManager.get_player().load_actions_from_ui(actions)
            _update_ui()
            disable_buttons()
        else:
            print("No actions in queue to execute")
            _show_message("No actions in queue!")

func clear_sequence() -> void:
    if action_queue:
        action_queue.clear_queue()

func reset_player() -> void:
    """重新載入關卡並保持動作佇列"""
    # 重新載入關卡（LevelManager會自動保存和恢復動作佇列）
    LevelManager.reload_current_level()

func restore_action_queue(action_types: Array[Action.ActionType]) -> void:
    """恢復動作佇列（由LevelManager調用）"""
    if action_queue:
        action_queue.restore_action_queue(action_types)
    _update_ui()

func disable_buttons() -> void:
    execute_button.disabled = true
    clear_button.disabled = true
    reset_button.disabled = true

func enable_buttons() -> void:
    execute_button.disabled = false
    clear_button.disabled = false
    reset_button.disabled = false

func _update_ui() -> void:
    # Get action count from action_queue
    var action_count = action_queue.get_action_count() if action_queue else 0
    
    # Update button states
    if execute_button:
        execute_button.disabled = action_count == 0
    
    if clear_button:
        clear_button.disabled = action_count == 0
    
    # Reset button is always enabled (unless player is executing actions)
    if reset_button:
        reset_button.disabled = GameManager.get_player() and GameManager.get_player().is_executing()
    
    # Update info label
    if info_label:
        if action_count == 0:
            info_label.text = "Drag cards from above to build your action sequence"
        else:
            info_label.text = "Ready to execute " + str(action_count) + " actions"

func _show_message(text: String) -> void:
    if info_label:
        var original_text = info_label.text
        info_label.text = text
        info_label.modulate = Color.RED
        
        # Reset after 2 seconds
        await get_tree().create_timer(2.0).timeout
        info_label.text = original_text
        info_label.modulate = Color.WHITE
