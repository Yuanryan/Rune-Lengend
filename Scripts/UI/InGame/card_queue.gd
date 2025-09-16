# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel

@onready var monitor: DropMonitor = %DropMonitor
@onready var _preview_indicator: Control = %PreviewIndicator

var queue_cards: Array[CardTile] = []
var _is_dragging_over: bool = false

signal action_added(action_type: Action.ActionType, index: int)
signal action_removed(action_type: Action.ActionType, index: int)
signal queue_cleared()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    monitor.card_dropped_outside.connect(_on_card_dropped_outside)

func _on_card_dropped_outside(card: CardTile) -> void:
    var card_index = queue_cards.find(card)
    if card_index >= 0:
        _remove_action_at(card_index)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    var can_drop = typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "card"
    
    if can_drop:
        _is_dragging_over = true
        _update_preview_indicator(at_position)
    else:
        _hide_preview_indicator()
    
    return can_drop

func _update_preview_indicator(at_position: Vector2) -> void:
    """簡化的預覽指示器更新"""
    if not _preview_indicator:
        return
    
    var insert_index = _get_insert_index(at_position)
    _show_preview_at_index(insert_index)

func _get_insert_index(at_position: Vector2) -> int:
    """獲取插入位置索引"""
    var global_pos = get_global_mouse_position()
    
    # 簡單檢查：找到第一個位置在滑鼠位置右邊的卡片
    for i in range(queue_cards.size()):
        var card = queue_cards[i]
        if is_instance_valid(card):
            var card_rect = card.get_global_rect()
            if global_pos.x < card_rect.position.x + card_rect.size.x / 2:
                return i
    
    # 如果沒有找到，插入到末尾
    return queue_cards.size()

func _show_preview_at_index(index: int) -> void:
    """顯示預覽指示器"""
    if not _preview_indicator:
        return
    
    _preview_indicator.visible = true
    
    var preview_x = 0.0
    if index < queue_cards.size() and queue_cards.size() > 0:
        var target_card = queue_cards[index]
        preview_x = target_card.position.x - 2
    elif queue_cards.size() > 0:
        var last_card = queue_cards[-1]
        preview_x = last_card.position.x + last_card.size.x + 2
    
    _preview_indicator.position.x = preview_x
    _preview_indicator.position.y = 0

func _hide_preview_indicator() -> void:
    """隱藏預覽指示器"""
    if _preview_indicator:
        _preview_indicator.visible = false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    _hide_preview_indicator()
    _is_dragging_over = false
    
    var card: CardTile = data["card"]
    if not card:
        return
    
    var card_index = queue_cards.find(card)
    
    if card_index < 0:
        # 新卡片從外部拖入
        _add_new_card(card, at_position)
    else:
        # 卡片重新排序
        _reorder_card(card, card_index, at_position)

func _add_new_card(card: CardTile, at_position: Vector2) -> void:
    """添加新卡片到佇列"""
    var action_type = card.get_action_type()
    var insert_index = _get_insert_index(at_position)
    
    var queue_card = _create_queue_card(action_type, card.get_action_label())
    queue_cards.insert(insert_index, queue_card)
    _reorder_children()
    
    action_added.emit(action_type, insert_index)

func _reorder_card(card: CardTile, card_index: int, at_position: Vector2) -> void:
    """重新排序卡片"""
    var target_index = _get_insert_index(at_position)
    
    if target_index != card_index and target_index >= 0:
        _move_card(card_index, target_index)

func _move_card(from_index: int, to_index: int) -> void:
    """移動卡片位置"""
    if from_index < 0 or to_index < 0 or from_index >= queue_cards.size():
        return
    
    var moved_card = queue_cards[from_index]
    queue_cards.remove_at(from_index)
    
    # 調整目標索引
    if from_index < to_index:
        to_index -= 1
    
    queue_cards.insert(to_index, moved_card)
    _reorder_children()

func _create_queue_card(action_type: Action.ActionType, label: String) -> CardTile:
    """創建佇列卡片"""
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action_type(action_type, label)
    add_child(card)
    return card

func _reorder_children() -> void:
    """重新排列子節點"""
    for i in range(queue_cards.size()):
        var card = queue_cards[i]
        if is_instance_valid(card):
            move_child(card, i)

func _remove_action_at(index: int) -> void:
    """移除指定位置的動作"""
    if index >= 0 and index < queue_cards.size():
        var card = queue_cards[index]
        var action_type = card.get_action_type()
        queue_cards.remove_at(index)
        card.queue_free()
        action_removed.emit(action_type, index)

# ========== 公共API ==========

func clear_queue() -> void:
    """清空佇列"""
    for card in queue_cards:
        if is_instance_valid(card):
            card.queue_free()
    queue_cards.clear()
    queue_cleared.emit()

func get_action_types() -> Array[Action.ActionType]:
    """獲取動作類型數組"""
    var action_types: Array[Action.ActionType] = []
    for card in queue_cards:
        if is_instance_valid(card):
            action_types.append(card.get_action_type())
    return action_types

func get_action_count() -> int:
    """獲取動作數量"""
    return queue_cards.size()

func is_empty() -> bool:
    """檢查佇列是否為空"""
    return queue_cards.is_empty()

func restore_action_queue(action_types: Array[Action.ActionType]) -> void:
    """恢復動作佇列"""
    clear_queue()
    
    for action_type in action_types:
        var action_label = _get_action_label(action_type)
        var queue_card = _create_queue_card(action_type, action_label)
        queue_cards.append(queue_card)
    
    _reorder_children()
    
    # 發送信號通知UI更新
    for i in range(action_types.size()):
        action_added.emit(action_types[i], i)

func _get_action_label(action_type: Action.ActionType) -> String:
    """獲取動作標籤"""
    match action_type:
        Action.ActionType.MOVE_LEFT:
            return "Move Left"
        Action.ActionType.MOVE_RIGHT:
            return "Move Right"
        Action.ActionType.JUMP_LEFT:
            return "Jump Left"
        Action.ActionType.JUMP_RIGHT:
            return "Jump Right"
        Action.ActionType.SWITCH_ANIMAL:
            return "Switch Animal"
        _:
            return "Unknown Action"