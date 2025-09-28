# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel

@onready var monitor: DropMonitor = %DropMonitor
@onready var _preview_indicator: Control = %PreviewIndicator

var queue_cards: Array[CardTile] = []
var _is_dragging_over: bool = false
var _current_executing_index: int = -1
var _is_locked: bool = false  # 隊列鎖定狀態

signal action_added(action_type: Action.ActionType, index: int)
signal action_removed(action_type: Action.ActionType, index: int)
signal queue_cleared()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    monitor.card_dropped_outside.connect(_on_card_dropped_outside)

func _on_card_dropped_outside(card: CardTile) -> void:
    # 如果隊列被鎖定，不允許移除卡片
    if _is_locked:
        return
        
    var card_index = queue_cards.find(card)
    if card_index >= 0:
        _remove_action_at(card_index)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    # 如果隊列被鎖定，不允許拖放
    if _is_locked:
        return false
        
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
    var animal_type = -1
    if card and card.animal_type != -1:
        # CardTile 會攜帶 animal_type（僅 SWITCH_ANIMAL 會用到）
        animal_type = card.animal_type
    
    var queue_card = _create_queue_card(action_type, card.get_action_label(), animal_type)
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

func _create_queue_card(action_type: Action.ActionType, label: String, animal_type: int = -1) -> CardTile:
    """創建佇列卡片"""
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action_type(action_type, label)
    if animal_type != -1:
        card.animal_type = animal_type
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

func get_action_descriptors() -> Array:
    """獲取動作描述（包含對 SWITCH_ANIMAL 的 animal_type）"""
    var action_descs: Array = []
    for card in queue_cards:
        if is_instance_valid(card):
            var desc = {
                "action_type": card.get_action_type(),
                "animal_type": (card.animal_type)
            }
            action_descs.append(desc)
    return action_descs

func get_action_count() -> int:
    """獲取動作數量"""
    return queue_cards.size()

func is_empty() -> bool:
    """檢查佇列是否為空"""
    return queue_cards.is_empty()

func restore_action_queue(action_descriptors: Array) -> void:
    """恢復動作佇列"""
    clear_queue()
    
    for desc in action_descriptors:
        var action_type: Action.ActionType = desc.get("action_type", -1)
        var animal_type: int = desc.get("animal_type", -1)
        
        var action_label = _get_action_label(action_type, animal_type)
        var queue_card = _create_queue_card(action_type, action_label, animal_type)
        
        # 設置動物類型
        queue_card.animal_type = animal_type
        queue_cards.append(queue_card)
    
    _reorder_children()
    
    # 發送信號通知UI更新
    for i in range(queue_cards.size()):
        if is_instance_valid(queue_cards[i]):
            action_added.emit(queue_cards[i].get_action_type(), i)

func _get_action_label(action_type: Action.ActionType, animal_type: int = -1) -> String:
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
            return "Switch " +  Animal.get_animal_name(animal_type)
        _:
            return "Unknown Action"

func set_executing_action_index(index: int) -> void:
    """設置當前執行的動作索引"""
    # 停止之前執行的卡片發光
    if _current_executing_index >= 0 and _current_executing_index < queue_cards.size():
        var prev_card = queue_cards[_current_executing_index]
        if is_instance_valid(prev_card):
            prev_card.set_executing(false)
    
    # 開始新的卡片發光
    _current_executing_index = index
    if _current_executing_index >= 0 and _current_executing_index < queue_cards.size():
        var current_card = queue_cards[_current_executing_index]
        if is_instance_valid(current_card):
            current_card.set_executing(true)

func clear_executing_action() -> void:
    """清除執行狀態"""
    set_executing_action_index(-1)

func lock_queue() -> void:
    """鎖定隊列，防止修改"""
    _is_locked = true

func unlock_queue() -> void:
    """解鎖隊列，允許修改"""
    _is_locked = false

func is_locked() -> bool:
    """檢查隊列是否被鎖定"""
    return _is_locked
