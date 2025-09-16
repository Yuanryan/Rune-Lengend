# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel


@onready var monitor: DropMonitor = %DropMonitor
@onready var _preview_indicator: Control = %PreviewIndicator

var planned_action_types: Array[Action.ActionType] = []
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
        _update_preview_indicator(at_position, data)
    else:
        _hide_preview_indicator()
    
    return can_drop

func _update_preview_indicator(at_position: Vector2, data: Variant) -> void:
    """更新預覽指示器位置"""
    var card: CardTile = data["card"]
    if not card or not _preview_indicator:
        return
    
    # 檢查卡片是否來自隊列
    var card_index = queue_cards.find(card)
    if card_index < 0:
        # 來自外部的卡片，檢查是否拖動到特定位置
        var external_target = _get_card_at_position(at_position)
        if external_target:
            var target_index = queue_cards.find(external_target)
            if target_index >= 0:
                _show_preview_at_index(target_index)
            else:
                _show_preview_at_end()
        else:
            _show_preview_at_end()
        return
    
    # 隊列內的卡片重新排序
    var internal_target = _get_card_at_position(at_position)
    if internal_target and internal_target != card:
        var target_index = queue_cards.find(internal_target)
        if target_index >= 0:
            _show_preview_at_index(target_index)
    else:
        _hide_preview_indicator()

func _show_preview_at_index(index: int) -> void:
    """在指定索引位置顯示預覽"""
    if not _preview_indicator or index < 0 or index > queue_cards.size():
        return
    
    _preview_indicator.visible = true
    
    # 計算預覽指示器的位置，而不是移動子節點
    var preview_x = 0.0
    if index < queue_cards.size():
        # 在目標卡片前顯示
        var target_card = queue_cards[index]
        preview_x = target_card.position.x - 2  # 在卡片前2像素
    else:
        # 在隊列末尾顯示
        if queue_cards.size() > 0:
            var last_card = queue_cards[-1]
            preview_x = last_card.position.x + last_card.size.x + 2  # 在最後一張卡片後2像素
        else:
            preview_x = 0
    
    _preview_indicator.position.x = preview_x
    _preview_indicator.position.y = 0

func _show_preview_at_end() -> void:
    """在隊列末尾顯示預覽"""
    if not _preview_indicator:
        return
    
    _preview_indicator.visible = true
    
    # 計算末尾位置
    var preview_x = 0.0
    if queue_cards.size() > 0:
        var last_card = queue_cards[-1]
        preview_x = last_card.position.x + last_card.size.x + 2  # 在最後一張卡片後2像素
    else:
        preview_x = 0
    
    _preview_indicator.position.x = preview_x
    _preview_indicator.position.y = 0

func _hide_preview_indicator() -> void:
    """隱藏預覽指示器"""
    if _preview_indicator:
        _preview_indicator.visible = false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    # 隱藏預覽指示器
    _hide_preview_indicator()
    _is_dragging_over = false
    
    var card: CardTile = data["card"]
    if card:
        # 檢查這個卡片是否已經在隊列中
        var card_index = queue_cards.find(card)
        
        if card_index < 0:
            # 新卡片從外部拖入隊列
            var action_type = card.get_action_type()
            
            # 檢查是否拖動到特定位置
            var target_card = _get_card_at_position(at_position)
            var insert_index = planned_action_types.size()  # 默認插入到末尾
            
            if target_card:
                var target_index = queue_cards.find(target_card)
                if target_index >= 0:
                    insert_index = target_index
            
            # 在指定位置插入
            planned_action_types.insert(insert_index, action_type)
            
            # 創建隊列中的卡片顯示
            var queue_card = _create_queue_card(action_type, card.get_action_label())
            queue_cards.insert(insert_index, queue_card)
            
            # 重新排列子節點
            _reorder_children()
            
            action_added.emit(action_type, insert_index)
        else:
            # 卡片已在隊列中，檢查是否拖動到其他卡片上進行交換
            _handle_card_reorder(card, card_index, at_position)

func _create_queue_card(action_type: Action.ActionType, label: String) -> CardTile:
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action_type(action_type, label)
    
    add_child(card)
    return card

func _handle_card_reorder(dragged_card: CardTile, dragged_index: int, drop_position: Vector2) -> void:
    """處理隊列中卡片的重新排序"""
    # 找到拖動位置下的目標卡片
    var target_card = _get_card_at_position(drop_position)
    
    if target_card and target_card != dragged_card:
        var target_index = queue_cards.find(target_card)
        if target_index >= 0 and target_index != dragged_index:
            # 插入式重新排序
            _insert_card_at_position(dragged_index, target_index)
            print("Moved card from position ", dragged_index, " to ", target_index)
            
            # 添加視覺反饋
            _show_insert_feedback(target_card)

func _get_card_at_position(drop_pos: Vector2) -> CardTile:
    """獲取指定位置下的卡片，改善兩個卡片之間的檢測"""
    var global_pos = get_global_mouse_position()
    
    # 首先檢查是否直接在某個卡片上
    for card in queue_cards:
        if is_instance_valid(card):
            var card_rect = card.get_global_rect()
            if card_rect.has_point(global_pos):
                return card
    
    # 如果不在任何卡片上，檢查是否在兩個卡片之間
    return _get_card_between_position(global_pos)

func _get_card_between_position(global_pos: Vector2) -> CardTile:
    """檢測滑鼠是否在兩個卡片之間，返回應該插入位置的目標卡片"""
    if queue_cards.size() < 2:
        return null
    
    # 將卡片按 x 位置排序
    var sorted_cards = queue_cards.duplicate()
    sorted_cards.sort_custom(func(a, b): return a.position.x < b.position.x)
    
    # 檢查滑鼠是否在兩個相鄰卡片之間
    for i in range(sorted_cards.size() - 1):
        var left_card = sorted_cards[i]
        var right_card = sorted_cards[i + 1]
        
        if not is_instance_valid(left_card) or not is_instance_valid(right_card):
            continue
        
        var left_rect = left_card.get_global_rect()
        var right_rect = right_card.get_global_rect()
        
        # 檢查滑鼠是否在左卡片右邊緣和右卡片左邊緣之間
        var between_x_start = left_rect.position.x + left_rect.size.x
        var between_x_end = right_rect.position.x
        
        if global_pos.x >= between_x_start and global_pos.x <= between_x_end:
            # 檢查滑鼠是否在垂直範圍內
            var min_y = min(left_rect.position.y, right_rect.position.y)
            var max_y = max(left_rect.position.y + left_rect.size.y, right_rect.position.y + right_rect.size.y)
            
            if global_pos.y >= min_y and global_pos.y <= max_y:
                # 根據滑鼠位置決定插入到左邊還是右邊
                var mid_point = (between_x_start + between_x_end) / 2
                return right_card if global_pos.x > mid_point else left_card
    
    # 檢查是否在隊列開始或結束位置
    if queue_cards.size() > 0:
        var first_card = sorted_cards[0]
        var last_card = sorted_cards[-1]
        
        if is_instance_valid(first_card) and is_instance_valid(last_card):
            var first_rect = first_card.get_global_rect()
            var last_rect = last_card.get_global_rect()
            
            # 檢查是否在第一個卡片之前
            if global_pos.x < first_rect.position.x:
                return first_card
            
            # 檢查是否在最後一個卡片之後
            if global_pos.x > last_rect.position.x + last_rect.size.x:
                return null  # 插入到末尾
    
    return null

func _insert_card_at_position(from_index: int, to_index: int) -> void:
    """將卡片從一個位置插入到另一個位置"""
    if from_index < 0 or to_index < 0 or from_index >= queue_cards.size() or to_index >= queue_cards.size():
        return
    
    # 從原位置移除卡片和動作類型
    var moved_action_type = planned_action_types[from_index]
    var moved_card = queue_cards[from_index]
    
    planned_action_types.remove_at(from_index)
    queue_cards.remove_at(from_index)
    
    # 調整目標索引（如果移除的位置在目標位置之前）
    var adjusted_to_index = to_index
    if from_index < to_index:
        adjusted_to_index = to_index - 1
    
    # 在目標位置插入
    planned_action_types.insert(adjusted_to_index, moved_action_type)
    queue_cards.insert(adjusted_to_index, moved_card)
    
    # 重新排列所有子節點
    _reorder_children()
    
    print("Card moved: ", moved_action_type, " from ", from_index, " to ", adjusted_to_index)

func _reorder_children() -> void:
    """重新排列所有子節點以匹配數組順序"""
    for i in range(queue_cards.size()):
        var card = queue_cards[i]
        if is_instance_valid(card):
            move_child(card, i)

func _show_insert_feedback(card: CardTile) -> void:
    """顯示插入成功的視覺反饋"""
    if not card:
        return
    
    # 創建一個短暫的高亮效果，表示這個位置被插入
    var original_modulate = card.modulate
    card.modulate = Color.CYAN
    
    # 0.3秒後恢復原色
    await get_tree().create_timer(0.3).timeout
    if is_instance_valid(card):
        card.modulate = original_modulate

func _remove_action_at(index: int):
    if index >= 0 and index < planned_action_types.size():
        var action_type = planned_action_types[index]
        planned_action_types.remove_at(index)
        
        if index < queue_cards.size():
            var card = queue_cards[index]
            queue_cards.remove_at(index)
            card.queue_free()  # 直接釋放卡片，不再有容器
        
        action_removed.emit(action_type, index)

func remove_action_type(action_type: Action.ActionType):
    var index = planned_action_types.find(action_type)
    if index >= 0:
        _remove_action_at(index)

func clear_queue():
    planned_action_types.clear()
    
    for card in queue_cards:
        if is_instance_valid(card):
            card.queue_free()
    queue_cards.clear()
    
    queue_cleared.emit()

func get_action_types() -> Array[Action.ActionType]:
    return planned_action_types.duplicate()

func get_action_count() -> int:
    return planned_action_types.size()

func is_empty() -> bool:
    return planned_action_types.is_empty()
