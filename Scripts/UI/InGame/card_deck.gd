# UI/CardDeck.gd
extends HBoxContainer
class_name CardDeck

# Card deck that always has four cards: move left/right, jump left/right
# Based on current animal resources

var current_animal: Animal
var card_tiles: Array[CardTile] = []

signal card_selected(card: CardTile)

func _ready() -> void:
    _create_four_cards()

func set_current_animal(animal: Animal) -> void:
    current_animal = animal
    _create_four_cards()

func _create_four_cards() -> void:
    # Clear existing cards
    for card in card_tiles:
        if is_instance_valid(card):
            card.queue_free()
    card_tiles.clear()
    
    if not current_animal:
        print("No current animal set for card deck")
        return
    
    # Create four cards based on current animal
    var move_action = current_animal.get_move_action()
    var jump_action = current_animal.get_jump_action()
    
    if not move_action or not jump_action:
        print("Animal missing move or jump action")
        return
    
    # Create move left card
    var move_left_action = MoveAction.new(-move_action.velocity.x, current_animal.animal_data.name + "_Move_Left")
    _create_card(move_left_action, "Move Left")
    
    # Create move right card
    var move_right_action = MoveAction.new(move_action.velocity.x, current_animal.animal_data.name + "_Move_Right")
    _create_card(move_right_action, "Move Right")
    
    # Create jump left card
    var jump_left_action = JumpAction.new(Vector2(-jump_action.jump_velocity.x, jump_action.jump_velocity.y), current_animal.animal_data.name + "_Jump_Left")
    _create_card(jump_left_action, "Jump Left")
    
    # Create jump right card
    var jump_right_action = JumpAction.new(Vector2(jump_action.jump_velocity.x, jump_action.jump_velocity.y), current_animal.animal_data.name + "_Jump_Right")
    _create_card(jump_right_action, "Jump Right")

func _create_card(action: Action, label: String) -> void:
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action(action)
    card.set_label(label)
    
    # Connect signals
    card.card_clicked.connect(_on_card_clicked)
    card.card_dragged.connect(_on_card_dragged)
    
    add_child(card)
    card_tiles.append(card)

func _on_card_clicked(card: CardTile) -> void:
    card_selected.emit(card)

func _on_card_dragged(card: CardTile) -> void:
    print("Card dragged: ", card.get_action_label())

# Get all cards for external use
func get_all_cards() -> Array[CardTile]:
    return card_tiles

# Get specific card by type
func get_move_left_card() -> CardTile:
    return card_tiles[0] if card_tiles.size() > 0 else null

func get_move_right_card() -> CardTile:
    return card_tiles[1] if card_tiles.size() > 1 else null

func get_jump_left_card() -> CardTile:
    return card_tiles[2] if card_tiles.size() > 2 else null

func get_jump_right_card() -> CardTile:
    return card_tiles[3] if card_tiles.size() > 3 else null
