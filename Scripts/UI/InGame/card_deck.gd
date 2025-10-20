# UI/CardDeck.gd
extends HBoxContainer
class_name CardDeck

# Card deck that always has four cards: move left/right, jump left/right
# Based on current animal resources

var current_animal: Animal
var card_tiles: Array[CardTile] = []
var action_usage_count: Dictionary[Action.ActionType, int] = {}
var current_level_resource: LevelResource

signal card_selected(card: CardTile)



func _create_card(action_type: Action.ActionType, label: String) -> CardTile:
    var card_scene = preload("uid://c2nq82l2n1e8q")
    var card = card_scene.instantiate() as CardTile
    card.set_action_type(action_type, label)

    # Connect signals
    card.card_clicked.connect(_on_card_clicked)
    # card.card_dragged.connect(_on_card_dragged)

    add_child(card)
    card_tiles.append(card)
    return card

func _on_card_clicked(card: CardTile) -> void:
    card_selected.emit(card)

func _on_card_dragged(card: CardTile) -> void:
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
func create_cards_from_level_resource(resource: LevelResource) -> void:
    """根據關卡資源創建卡片"""
    if not resource:
        print("關卡資源不存在，無法創建卡片")
        return

    current_level_resource = resource
    _initialize_action_usage_count(resource)
    clear_cards()
    _create_four_cards()
    _create_switch_animal_card(resource.available_animals)
    _update_card_states()

func _create_four_cards() -> void:
    _create_card(Action.ActionType.MOVE_LEFT, "Move Left")
    _create_card(Action.ActionType.MOVE_RIGHT, "Move Right")
    _create_card(Action.ActionType.JUMP_LEFT, "Jump Left")
    _create_card(Action.ActionType.JUMP_RIGHT, "Jump Right")

func _create_switch_animal_card(available_animals: Array[Animal.AnimalType]) -> void:
    for animal in available_animals:
        var animal_name = Animal.get_animal_name(animal)
        var card = _create_card(Action.ActionType.SWITCH_ANIMAL, "Switch " + animal_name)
        if card:
            card.animal_type = animal
            # 確保圖片和外框都正確更新
            card._update_card_image()
            card._update_card_color()
            card._update_card_frame()

# 初始化動作使用計數
func _initialize_action_usage_count(resource: LevelResource) -> void:
    """初始化動作使用計數"""
    action_usage_count.clear()
    if not resource:
        return

    # 初始化所有動作類型的使用計數為 0
    for action_type in resource.individual_action_limits.keys():
        action_usage_count[action_type] = 0

# 檢查動作是否可以使用
func can_use_action(action_type: Action.ActionType) -> bool:
    """檢查指定動作是否還可以使用"""
    if not current_level_resource:
        return true

    # 檢查總動作數量限制
    var total_used = _get_total_actions_used()
    if total_used >= current_level_resource.max_total_actions:
        return false

    # 檢查個別動作限制
    var current_usage = action_usage_count.get(action_type, 0)
    var max_usage = current_level_resource.individual_action_limits.get(action_type, 999)

    return current_usage < max_usage

# 使用動作
func use_action(action_type: Action.ActionType) -> bool:
    """使用一個動作，返回是否成功"""
    if not can_use_action(action_type):
        return false

    action_usage_count[action_type] = action_usage_count.get(action_type, 0) + 1
    _update_card_states()
    return true

# 取消使用動作
func unuse_action(action_type: Action.ActionType) -> void:
    """取消使用一個動作"""
    var current_usage = action_usage_count.get(action_type, 0)
    if current_usage > 0:
        action_usage_count[action_type] = current_usage - 1
        _update_card_states()

# 獲取總動作使用數量
func _get_total_actions_used() -> int:
    """獲取總動作使用數量"""
    var total = 0
    for count in action_usage_count.values():
        total += count
    return total

# 更新卡片狀態
func _update_card_states() -> void:
    """更新所有卡片的可用狀態"""
    for card in card_tiles:
        if is_instance_valid(card):
            var action_type = card.get_action_type()
            var can_use = can_use_action(action_type)
            var current_usage = action_usage_count.get(action_type, 0)
            var max_usage = current_level_resource.individual_action_limits.get(action_type, 999) if current_level_resource else 999

            card.set_usage_info(can_use, current_usage, max_usage)

# 重置動作使用計數
func reset_action_usage() -> void:
    """重置所有動作使用計數"""
    if current_level_resource:
        _initialize_action_usage_count(current_level_resource)
        _update_card_states()

# 獲取動作使用信息
func get_action_usage_info() -> Dictionary:
    """獲取動作使用信息"""
    var info = {}
    if not current_level_resource:
        return info

    for action_type in current_level_resource.individual_action_limits.keys():
        var current = action_usage_count.get(action_type, 0)
        var max_usage = current_level_resource.individual_action_limits.get(action_type, 0)
        info[action_type] = {
            "current": current,
            "max": max_usage,
            "remaining": max_usage - current
        }

    info["total_used"] = _get_total_actions_used()
    info["total_max"] = current_level_resource.max_total_actions
    info["total_remaining"] = current_level_resource.max_total_actions - _get_total_actions_used()

    return info

# 監聽動作佇列變化
func connect_to_action_queue(action_queue: QueuePanel) -> void:
    """連接到動作佇列以監聽變化"""
    if action_queue:
        # 只在未連接時才連接
        if not action_queue.action_added.is_connected(_on_action_added):
            action_queue.action_added.connect(_on_action_added)
        if not action_queue.action_removed.is_connected(_on_action_removed):
            action_queue.action_removed.connect(_on_action_removed)
        if not action_queue.queue_cleared.is_connected(_on_queue_cleared):
            action_queue.queue_cleared.connect(_on_queue_cleared)

func _on_action_added(action_type: Action.ActionType, index: int) -> void:
    """當動作被添加到佇列時"""
    use_action(action_type)

func _on_action_removed(action_type: Action.ActionType, index: int) -> void:
    """當動作從佇列移除時"""
    unuse_action(action_type)

func _on_queue_cleared() -> void:
    """當佇列被清空時"""
    reset_action_usage()
