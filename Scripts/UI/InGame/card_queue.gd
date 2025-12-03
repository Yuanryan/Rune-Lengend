# UI/QueuePanel.gd
extends HBoxContainer
class_name QueuePanel

@onready var monitor: DropMonitor = %DropMonitor
@onready var _preview_indicator: Control = %PreviewIndicator
@onready var _clear_button: TextureButton = %ClearQueueButton

var queue_cards: Array[CardTile] = []
var _is_dragging_over: bool = false
var _current_executing_index: int = -1
var _is_locked: bool = false  # 隊列鎖定狀態
var _container: Control  # ActionQueueContainer 引用

@export var card_scale: float = 1.0  # 卡片縮放倍率 (預設1.0, 卡片固定不動scale)
@export var background_padding: Vector2 = Vector2(8, 8)  # 整體padding
@export var desired_natural_padding: float = 12.5  # 每張卡片自然padding (左右總和, 可調, 影響scale_factor)

signal action_added(action_type: Action.ActionType, index: int)
signal action_removed(action_type: Action.ActionType, index: int)
signal queue_cleared()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    monitor.card_dropped_outside.connect(_on_card_dropped_outside)
    _container = get_parent()  # ActionQueue -> ActionQueueContainer
    call_deferred("_initialize_container_size")  # 初始化 (N=1)
    _setup_clear_button()  # 設定清除按鈕

func _initialize_container_size() -> void:
    if not _container:
        return
    call_deferred("_do_update_container_size")

func _setup_clear_button() -> void:
    """設定清除按鈕的信號和效果"""
    if not _clear_button:
        return

    # 連接按鈕信號
    _clear_button.pressed.connect(_on_clear_button_pressed)
    _clear_button.mouse_entered.connect(_on_clear_button_hover)
    _clear_button.mouse_exited.connect(_on_clear_button_normal)
    _clear_button.button_down.connect(_on_clear_button_down)
    _clear_button.button_up.connect(_on_clear_button_hover)  # 放開時回到 hover 狀態

func _on_clear_button_pressed() -> void:
    """清除按鈕被按下"""
    if not _is_locked:
        clear_queue()
    _clear_button.release_focus()

func _on_clear_button_hover() -> void:
    """滑鼠進入按鈕 - 變亮"""
    if _clear_button:
        _clear_button.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_clear_button_normal() -> void:
    """滑鼠離開按鈕 - 恢復正常"""
    if _clear_button:
        _clear_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_clear_button_down() -> void:
    """按鈕被按下 - 變暗"""
    if _clear_button:
        _clear_button.modulate = Color(0.8, 0.8, 0.8, 1.0)

func _update_clear_button_position(bg_offset_x: float, bg_offset_y: float, bg_width: float, bg_height: float, scale_factor: float) -> void:
    """更新清除按鈕的位置和縮放"""
    if not _clear_button:
        return

    # 按鈕原始大小是 40x40px，跟背景一樣需要縮放
    _clear_button.scale = Vector2(scale_factor, scale_factor)

    # 按鈕位置：背景右邊界，垂直置中
    var btn_scaled_size = 40.0 * scale_factor
    var btn_x = bg_offset_x + bg_width  # 緊貼背景右邊
    var btn_y = bg_offset_y + (bg_height - btn_scaled_size) / 2.0  # 垂直置中
    _clear_button.position = Vector2(btn_x, btn_y)

func _get_base_card_size() -> Vector2:
    """獲取卡片基底大小 (固定100x100，不考慮scale)"""
    return Vector2(100, 100)  # 卡片實際大小

func _do_update_container_size() -> void:
    """更新容器和背景大小"""
    if not _container:
        return
    await get_tree().process_frame

    var base_card_size = _get_base_card_size()  # Vector2(100, 100)
    var scaled_card_size = base_card_size * card_scale  # 預設100x100
    var card_count = max(queue_cards.size(), 1)  # 至少1張空間

    # 逆推scale_factor：讓32px邏輯區域scale後 = 100 + desired_natural_padding (可調)
    var effective_region_width = scaled_card_size.x + desired_natural_padding  # 112.5px
    var scale_factor = effective_region_width / 32.0  # ≈3.516

    # 背景邏輯寬度 = N * 32px + 8px (左右邊框各4px)
    var background_logical_width = card_count * 32.0 + 8.0
    # 背景邏輯高度 = 40px (原始圖片高度，包含上下邊框)
    var background_logical_height = 40.0

    # 背景實際大小 = 邏輯大小 * scale_factor
    var background_actual_width = background_logical_width * scale_factor
    var background_actual_height = background_logical_height * scale_factor

    # 容器寬度 = 背景實際寬度 + padding
    var container_width = background_actual_width + background_padding.x
    var container_height = background_actual_height + background_padding.y
    var container_size = Vector2(container_width, container_height)

    # 設定容器大小
    _container.custom_minimum_size = container_size
    _container.size = container_size

    # 置中背景：計算 offset 讓背景在容器中央
    var bg_offset_x = (container_width - background_actual_width) / 2.0
    var bg_offset_y = (container_height - background_actual_height) / 2.0

    var background_node = _container.get_node("QueueBackground")
    if background_node:
        # patch_margin 保持原始圖片的 4px，不要改！
        background_node.patch_margin_left = 4
        background_node.patch_margin_top = 4
        background_node.patch_margin_right = 4
        background_node.patch_margin_bottom = 4

        # 用 scale 來放大整個 NinePatchRect（邊框會等比例放大）
        background_node.scale = Vector2(scale_factor, scale_factor)

        # 設定邏輯大小（scale 前的大小）
        background_node.custom_minimum_size = Vector2(background_logical_width, background_logical_height)
        background_node.size = Vector2(background_logical_width, background_logical_height)

        background_node.position = Vector2(bg_offset_x, bg_offset_y)

    # 計算卡片之間的間距（desired_natural_padding 是每張卡片的總 padding）
    set("theme_override_constants/separation", int(desired_natural_padding))

    # ActionQueue 的寬度 = 卡片總寬度 + 間距
    var cards_total_width = card_count * scaled_card_size.x + (card_count - 1) * desired_natural_padding
    # ActionQueue 的高度 = 卡片高度（不要拉伸！）
    var queue_height = scaled_card_size.y

    # 設定 ActionQueue (self) 的大小
    self.custom_minimum_size = Vector2(cards_total_width, queue_height)
    self.size = Vector2(cards_total_width, queue_height)

    # ActionQueue 置中於背景
    var queue_offset_x = (container_width - cards_total_width) / 2.0
    var queue_offset_y = (container_height - queue_height) / 2.0
    self.position = Vector2(queue_offset_x, queue_offset_y)

    # 更新清除按鈕位置和縮放
    _update_clear_button_position(bg_offset_x, bg_offset_y, background_actual_width, background_actual_height, scale_factor)

    # 重新布局
    _container.queue_redraw()
    var parent = _container.get_parent()
    if parent and parent is Container:
        parent.queue_sort()

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

    # 檢查動作限制 - 現在由 CardTile 的 can_use() 方法處理
    if can_drop:
        var card: CardTile = data.get("card")
        if card and not card.can_use():
            can_drop = false

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

    # 如果隊列被鎖定，不允許拖放
    if _is_locked:
        return

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
    var insert_index = _get_insert_index(at_position)
    _add_card_at_index(card, insert_index)

func _add_card_at_index(card: CardTile, insert_index: int) -> void:
    """通用的卡片添加方法，在指定索引處添加卡片"""
    var action_type = card.get_action_type()
    var animal_type = -1
    if card and card.animal_type != -1:
        # CardTile 會攜帶 animal_type（僅 SWITCH_ANIMAL 會用到）
        animal_type = card.animal_type

    # 動作使用計數由 CardDeck 在卡片狀態更新時處理

    var queue_card = _create_queue_card(action_type, card.get_action_label(), animal_type)
    queue_cards.insert(insert_index, queue_card)
    _reorder_children()
    _do_update_container_size()

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

    # 連接卡片點擊信號以處理從佇列中移除
    card.card_clicked.connect(_on_queue_card_clicked)

    add_child(card)
    return card

func _reorder_children() -> void:
    """重新排列子節點"""
    for i in range(queue_cards.size()):
        var card = queue_cards[i]
        if is_instance_valid(card):
            move_child(card, i)
    _do_update_container_size()

func _remove_action_at(index: int) -> void:
    """移除指定位置的動作"""
    if index >= 0 and index < queue_cards.size():
        var card = queue_cards[index]
        var action_type = card.get_action_type()

        # 動作使用計數由 CardDeck 在卡片狀態更新時處理

        queue_cards.remove_at(index)
        card.queue_free()
        _do_update_container_size()
        action_removed.emit(action_type, index)

func _on_queue_card_clicked(card: CardTile) -> void:
    """當佇列中的卡片被點擊時，從佇列中移除它"""
    # 如果隊列被鎖定，不允許移除卡片
    if _is_locked:
        return

    var card_index = queue_cards.find(card)
    if card_index >= 0:
        _remove_action_at(card_index)

# ========== 公共API ==========

func add_card_at_tail(card: CardTile) -> void:
    """將卡片添加到佇列末尾的公共方法"""
    if not card:
        return

    # 檢查佇列是否被鎖定
    if _is_locked:
        print("佇列被鎖定，無法添加卡片")
        return

    # 檢查卡片是否可以使用 - 現在由 CardTile 的 can_use() 方法處理
    if not card.can_use():
        print("卡片已達到使用限制，無法添加")
        return

    var insert_index = queue_cards.size()
    _add_card_at_index(card, insert_index)

func clear_queue() -> void:
    """清空佇列"""
    # 動作使用計數由 CardDeck 在卡片狀態更新時處理
    for card in queue_cards:
        if is_instance_valid(card):
            card.queue_free()

    queue_cards.clear()
    _do_update_container_size()
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
    _do_update_container_size()

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
    _current_executing_index = index

    # 更新所有卡片的視覺狀態
    for i in range(queue_cards.size()):
        var card = queue_cards[i]
        if not is_instance_valid(card):
            continue

        if i == index:
            # 當前執行的卡片：閃爍
            card.set_executing(true)
            card.set_dimmed(false)
        elif index >= 0:
            # 有卡片在執行，其他卡片變暗
            card.set_executing(false)
            card.set_dimmed(true)
        else:
            # 沒有卡片在執行，恢復正常
            card.set_executing(false)
            card.set_dimmed(false)

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

# 不再需要設置卡片組引用，動作計數由 CardDeck 直接管理
