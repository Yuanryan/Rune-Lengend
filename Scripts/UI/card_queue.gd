# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel

var planned_actions: Array[Action] = []
var queue_cards: Array[CardTile] = []

signal action_added(action: Action, index: int)
signal action_removed(action: Action, index: int)
signal queue_cleared()

func can_drop_data(at_position, data):
    return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "card"

func drop_data(at_position, data):
    var card: CardTile = data["card"]
    if card and card.action:
        var action_copy = card.action.duplicate()
        planned_actions.append(action_copy)
        
        # 創建隊列中的卡片顯示
        var queue_card = _create_queue_card(action_copy)
        queue_cards.append(queue_card)
        add_child(queue_card)
        
        action_added.emit(action_copy, planned_actions.size() - 1)

func _create_queue_card(action: Action) -> CardTile:
    var card = CardTile.new()
    card.set_action(action)
    card.draggable = false
    card.show_label = true
    card.card_size = Vector2(60, 60)
    
    # 添加刪除按鈕
    var container = HBoxContainer.new()
    container.add_child(card)
    
    var del_btn = Button.new()
    del_btn.text = "×"
    del_btn.custom_minimum_size = Vector2(20, 20)
    del_btn.pressed.connect(func():
        _remove_action_at(queue_cards.find(card))
    )
    container.add_child(del_btn)
    
    # 直接添加到隊列
    add_child(container)
    return card

func _remove_action_at(index: int):
    if index >= 0 and index < planned_actions.size():
        var action = planned_actions[index]
        planned_actions.remove_at(index)
        
        if index < queue_cards.size():
            var card = queue_cards[index]
            queue_cards.remove_at(index)
            card.get_parent().queue_free()
        
        action_removed.emit(action, index)

func remove_action(action: Action):
    var index = planned_actions.find(action)
    if index >= 0:
        _remove_action_at(index)

func clear_queue():
    planned_actions.clear()
    
    for card in queue_cards:
        if is_instance_valid(card) and is_instance_valid(card.get_parent()):
            card.get_parent().queue_free()
    queue_cards.clear()
    
    queue_cleared.emit()

func get_actions() -> Array[Action]:
    return planned_actions.duplicate()

func get_action_count() -> int:
    return planned_actions.size()

func is_empty() -> bool:
    return planned_actions.is_empty()
