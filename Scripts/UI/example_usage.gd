# UI/ExampleUsage.gd
extends CanvasLayer

# Complete UI manager that coordinates all card components
# This script should be attached to the root CanvasLayer in your UI scene

@export var card_palette: CardPalette
@export var action_queue: QueuePanel
@export var player: CharacterBody2D
@export var execute_button: Button
@export var clear_button: Button
@export var info_label: Label

var _action_count: int = 0

func _ready() -> void:
    # Find UI components if not assigned
    _find_ui_components()
    
    # Connect signals
    _connect_signals()
    
    # Set up the palette with your existing resources
    if card_palette:
        card_palette.setup_with_existing_resources()
    
    # Update UI
    _update_ui()

func _find_ui_components() -> void:
    # Auto-find components if not assigned in editor
    if not card_palette:
        card_palette = get_node_or_null("MainContainer/TopPanel/TopMargin/TopContent/CardPalette")
    if not action_queue:
        action_queue = get_node_or_null("MainContainer/BottomPanel/BottomMargin/BottomContent/ActionQueue")
    if not execute_button:
        execute_button = get_node_or_null("MainContainer/BottomPanel/BottomMargin/BottomContent/ControlButtons/ExecuteButton")
    if not clear_button:
        clear_button = get_node_or_null("MainContainer/BottomPanel/BottomMargin/BottomContent/ControlButtons/ClearButton")
    if not info_label:
        info_label = get_node_or_null("MainContainer/BottomPanel/BottomMargin/BottomContent/InfoLabel")

func _connect_signals() -> void:
    # Connect palette signals
    if card_palette:
        card_palette.card_selected.connect(_on_card_selected)
    
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

func _on_card_selected(card: CardTile) -> void:
    print("Card selected: ", card.get_action_label())
    # Optional: Add visual feedback for selected card

func _on_action_added(action: Action, index: int) -> void:
    _action_count += 1
    print("Action added to queue: ", action.name, " at index ", index)
    _update_ui()

func _on_action_removed(action: Action, index: int) -> void:
    _action_count -= 1
    print("Action removed from queue: ", action.name, " at index ", index)
    _update_ui()

func _on_queue_cleared() -> void:
    _action_count = 0
    print("Action queue cleared")
    _update_ui()

func _on_execute_pressed() -> void:
    execute_sequence()

func _on_clear_pressed() -> void:
    clear_sequence()

func execute_sequence() -> void:
    if action_queue and player:
        var actions = action_queue.get_actions()
        if actions.size() > 0:
            print("Executing sequence with ", actions.size(), " actions")
            player.load_actions_from_ui(actions)
            _update_ui()
        else:
            print("No actions in queue to execute")
            _show_message("No actions in queue!")

func clear_sequence() -> void:
    if action_queue:
        action_queue.clear_queue()
        print("Action queue cleared")
        _update_ui()

func _update_ui() -> void:
    # Update button states
    if execute_button:
        execute_button.disabled = _action_count == 0
    
    if clear_button:
        clear_button.disabled = _action_count == 0
    
    # Update info label
    if info_label:
        if _action_count == 0:
            info_label.text = "Drag cards from above to build your action sequence"
        else:
            info_label.text = "Ready to execute " + str(_action_count) + " actions"

func _show_message(text: String) -> void:
    if info_label:
        var original_text = info_label.text
        info_label.text = text
        info_label.modulate = Color.RED
        
        # Reset after 2 seconds
        await get_tree().create_timer(2.0).timeout
        info_label.text = original_text
        info_label.modulate = Color.WHITE

# Public API for external systems
func set_player(player_node: CharacterBody2D) -> void:
    player = player_node

func get_action_count() -> int:
    return _action_count

func is_queue_empty() -> bool:
    return _action_count == 0

# Example of creating cards programmatically from resources
func create_custom_card() -> void:
    # Load one of your existing action resources
    var jump_resource = load("res://Resources/Actions/jump.tres")
    if jump_resource:
        # Add it to the palette
        if card_palette:
            card_palette.add_action_resource(jump_resource)
