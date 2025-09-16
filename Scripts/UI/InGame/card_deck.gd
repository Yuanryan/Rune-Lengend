# UI/CardDeck.gd
extends HBoxContainer
class_name CardDeck

# Card deck that always has four cards: move left/right, jump left/right
# Based on current animal resources

var current_animal: Animal
var card_tiles: Array[CardTile] = []

signal card_selected(card: CardTile)

func _create_four_cards() -> void:    
    # if not current_animal:
    #     print("No current animal set for card deck")
    #     return
    
    # Create move left card
    _create_card(Action.ActionType.MOVE_LEFT, "Move Left")
    _create_card(Action.ActionType.MOVE_RIGHT, "Move Right")
    _create_card(Action.ActionType.JUMP_LEFT, "Jump Left")
    _create_card(Action.ActionType.JUMP_RIGHT, "Jump Right")

func _create_card(action_type: Action.ActionType, label: String) -> void:
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action_type(action_type, label)
    
    # Connect signals
    card.card_clicked.connect(_on_card_clicked)
    card.card_dragged.connect(_on_card_dragged)
    
    add_child(card)
    card_tiles.append(card)

func _on_card_clicked(card: CardTile) -> void:
    card_selected.emit(card)

func _on_card_dragged(card: CardTile) -> void:
    # print("Card dragged: ", card.get_action_label())
    pass
    
# Get all cards for external use
func get_all_cards() -> Array[CardTile]:
    return card_tiles

func clear_cards() -> void:
    for card in card_tiles:
        if is_instance_valid(card):
            card.queue_free()
    card_tiles.clear()

# 從關卡資源創建卡片
func create_cards_from_level_resource(level_resource: LevelResource) -> void:
    """根據關卡資源創建卡片"""
    if not level_resource:
        print("關卡資源不存在，無法創建卡片")
        return
    
    clear_cards()
    _create_four_cards()
    
