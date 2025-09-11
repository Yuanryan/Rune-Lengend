# UI/CardPalette.gd
extends HBoxContainer
class_name CardPalette

# Simple card palette that works with your existing action resources
# This replaces the factory approach with direct resource usage

@export var action_resources: Array[Action] = []
var card_tiles: Array[CardTile] = []

signal card_selected(card: CardTile)

func _ready() -> void:
    _create_cards_from_resources()

func _create_cards_from_resources() -> void:
    # Clear existing cards
    for card in card_tiles:
        if is_instance_valid(card):
            card.queue_free()
    card_tiles.clear()
    
    # Create cards from resources
    for action_resource in action_resources:
        var card = CardTile.new()
        card.set_action(action_resource)
        card.draggable = true
        card.show_label = true
        card.card_size = Vector2(80, 80)
        
        # Connect signals
        card.card_clicked.connect(_on_card_clicked)
        card.card_dragged.connect(_on_card_dragged)
        
        add_child(card)
        card_tiles.append(card)

func add_action_resource(action: Action) -> void:
    action_resources.append(action)
    _create_cards_from_resources()

func remove_action_resource(action: Action) -> void:
    action_resources.erase(action)
    _create_cards_from_resources()

func clear_palette() -> void:
    action_resources.clear()
    _create_cards_from_resources()

func _on_card_clicked(card: CardTile) -> void:
    card_selected.emit(card)

func _on_card_dragged(card: CardTile) -> void:
    # Optional: Handle drag start
    pass

# Example of how to set up with your existing resources
func setup_with_existing_resources() -> void:
    # Load your existing action resources
    var move_right = load("res://Resources/Actions/move_right.tres")
    var move_left = load("res://Resources/Actions/move_left.tres")
    var jump = load("res://Resources/Actions/jump.tres")
    var jump_right = load("res://Resources/Actions/jump_right.tres")
    var jump_left = load("res://Resources/Actions/jump_left.tres")
    
    # Add them to the palette
    if move_right:
        add_action_resource(move_right)
    if move_left:
        add_action_resource(move_left)
    if jump:
        add_action_resource(jump)
    if jump_right:
        add_action_resource(jump_right)
    if jump_left:
        add_action_resource(jump_left)
