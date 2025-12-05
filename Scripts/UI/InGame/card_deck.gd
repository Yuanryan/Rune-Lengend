# UI/CardDeck.gd
extends HBoxContainer
class_name CardDeck

# Card deck that always has four cards: move left/right, jump left/right
# Based on current animal resources

@export var card_scale: float = 1.0  # 卡片縮放倍率 (預設1.0, 卡片固定不動scale)
@export var background_padding: Vector2 = Vector2(8, 8)  # 整體padding
@export var desired_natural_padding: float = 20.0  # 每張卡片自然padding (左右總和, 可調, 影響scale_factor)
@export var label_height: float = 34.0  # 卡片下方數字標籤高度
@export var vertical_offset: float = -5.0  # 卡片垂直偏移（負值往上，正值往下）

var current_animal: Animal
var card_tiles: Array[CardTile] = []
var action_usage_count: Dictionary[Action.ActionType, int] = {}
var current_level: Level
var _container: Control  # CardDeckContainer 引用

signal card_selected(card: CardTile)

func _ready() -> void:
	_container = get_parent()  # CardDeck -> CardDeckContainer
	call_deferred("_initialize_container_size")  # 初始化 (N=1)

func _initialize_container_size() -> void:
	if not _container:
		return
	call_deferred("_do_update_container_size")

func _get_base_card_size() -> Vector2:
	return Vector2(100, 100)  # 卡片基礎大小

func _any_card_has_usage_limit() -> bool:
	"""檢查是否有任何卡片有使用次數限制"""
	if not current_level:
		return false
	for action_type in current_level.individual_action_limits.keys():
		var max_usage = current_level.individual_action_limits.get(action_type, 999)
		if max_usage < 999:
			return true
	return false



func _create_card(action_type: Action.ActionType, label: String) -> CardTile:
	# 檢查 individual_action_limits 中是否包含該動作類型
	if not current_level:
		return null

	# 如果 individual_action_limits 中沒有該動作類型，不創建卡片
	if not current_level.individual_action_limits.has(action_type):
		return null

	# 如果 individual_action_limits 中該動作類型的值為 0，不創建卡片
	var max_usage = current_level.individual_action_limits.get(action_type, 0)
	if max_usage <= 0:
		return null

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

func _do_update_container_size() -> void:
	"""動態調整背景和容器大小"""
	if not _container:
		return

	await get_tree().process_frame

	# 取得卡片數量 (至少為1)
	var card_count = max(1, card_tiles.size())
	var scaled_card_size = _get_base_card_size() * card_scale

	# 檢查是否有任何卡片需要顯示使用次數
	var needs_label = _any_card_has_usage_limit()
	var actual_label_height = label_height if needs_label else 0.0

	# 計算卡片區域總寬度（先算出來用於計算背景）
	var cards_total_width = card_count * scaled_card_size.x + max(0, card_count - 1) * desired_natural_padding

	# 計算 scale_factor
	# 垂直方向: 48px 背景高度對應卡片高度 + label高度
	var content_height = scaled_card_size.y + actual_label_height
	var scale_factor_y = content_height / 36.0  # 中間 36px 對應卡片+label
	# 水平方向: 使用相同的 scale 保持邊框比例
	var scale_factor_x = scale_factor_y

	# 背景邏輯尺寸 (根據卡牌實際寬度計算)
	# 邏輯寬度 = 左邊框(6) + 卡牌區域/scale + 右邊框(6)
	var background_logical_width = 12.0 + cards_total_width / scale_factor_x
	var background_logical_height = 48.0

	# 背景實際尺寸 (考慮 scale)
	var background_actual_width = background_logical_width * scale_factor_x
	var background_actual_height = background_logical_height * scale_factor_y

	# 更新容器大小
	_container.custom_minimum_size = Vector2(background_actual_width, background_actual_height)
	_container.size = Vector2(background_actual_width, background_actual_height)

	# 更新背景 (DeckBackground)
	var background_node = _container.get_node_or_null("DeckBackground")
	if background_node and background_node is NinePatchRect:
		# 設定背景 scale (整個背景包含邊框都 scale)
		background_node.scale = Vector2(scale_factor_x, scale_factor_y)
		# 設定背景邏輯尺寸
		background_node.custom_minimum_size = Vector2(background_logical_width, background_logical_height)
		background_node.size = Vector2(background_logical_width, background_logical_height)
		# 置中背景
		var bg_offset_x = (background_actual_width - background_logical_width * scale_factor_x) / 2.0
		var bg_offset_y = (background_actual_height - background_logical_height * scale_factor_y) / 2.0
		background_node.position = Vector2(bg_offset_x, bg_offset_y)

	# 設定卡片間距
	self.set("theme_override_constants/separation", int(desired_natural_padding))

	# 計算邊框寬度（scale 後）
	var border_width_scaled = 6.0 * scale_factor_x

	# 設定 CardDeck (self) 大小和位置（只設定卡片高度，不拉伸）
	var deck_content_height = scaled_card_size.y + actual_label_height
	self.custom_minimum_size = Vector2(cards_total_width, scaled_card_size.y)
	self.size = Vector2(cards_total_width, scaled_card_size.y)

	# 對齊到邊框內側（卡牌直接貼著邊框）
	var deck_offset_x = border_width_scaled
	var deck_offset_y = (background_actual_height - deck_content_height) / 2.0 + vertical_offset
	self.position = Vector2(deck_offset_x, deck_offset_y)

	# 觸發重繪
	_container.queue_redraw()
	var parent = _container.get_parent()
	if parent and parent is Container:
		parent.queue_sort()

# Get all cards for external use
func get_all_cards() -> Array[CardTile]:
	return card_tiles

func clear_cards() -> void:
	for card in card_tiles:
		if is_instance_valid(card):
			card.queue_free()
	card_tiles.clear()

# 從關卡創建卡片
func create_cards_from_level(level: Level) -> void:
	"""根據關卡創建卡片"""
	if not level:
		print("關卡不存在，無法創建卡片")
		return

	current_level = level
	_initialize_action_usage_count(level)
	clear_cards()
	_create_four_cards()
	_create_switch_animal_card(level.available_animals)
	_update_card_states()
	call_deferred("_do_update_container_size")  # 更新背景大小

func _create_four_cards() -> void:
	_create_card(Action.ActionType.MOVE_LEFT, "Move Left")
	_create_card(Action.ActionType.MOVE_RIGHT, "Move Right")
	_create_card(Action.ActionType.JUMP_LEFT, "Jump Left")
	_create_card(Action.ActionType.JUMP_RIGHT, "Jump Right")

func _create_switch_animal_card(available_animals: Array[Animal.AnimalType]) -> void:
	# 如果只有一個或沒有可用動物，不創建 switch animal 卡片
	if available_animals.size() <= 1:
		return

	# 檢查 individual_action_limits 中是否包含 SWITCH_ANIMAL 且值大於 0
	if not current_level:
		return

	if not current_level.individual_action_limits.has(Action.ActionType.SWITCH_ANIMAL):
		return

	var max_usage = current_level.individual_action_limits.get(Action.ActionType.SWITCH_ANIMAL, 0)
	if max_usage <= 0:
		return

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
func _initialize_action_usage_count(level: Level) -> void:
	"""初始化動作使用計數"""
	action_usage_count.clear()
	if not level:
		return
	# 初始化所有動作類型的當前使用計數為 0（不是最大值）
	for action_type in level.individual_action_limits.keys():
		action_usage_count[action_type] = 0

# 檢查動作是否可以使用
func can_use_action(action_type: Action.ActionType) -> bool:
	"""檢查指定動作是否還可以使用"""
	if not current_level:
		return true

	# 檢查總動作數量限制
	var total_used = _get_total_actions_used()
	if total_used >= current_level.max_total_actions:
		return false

	# 檢查個別動作限制
	var current_usage = action_usage_count.get(action_type, 0)
	var max_usage = current_level.individual_action_limits.get(action_type, 999)

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
			var max_usage = current_level.individual_action_limits.get(action_type, 999) if current_level else 999

			card.set_usage_info(can_use, current_usage, max_usage)
			card.set_interactable(can_use)

# 重置動作使用計數
func reset_action_usage() -> void:
	"""重置所有動作使用計數"""
	if current_level:
		_initialize_action_usage_count(current_level)
		_update_card_states()

# 獲取動作使用信息
func get_action_usage_info() -> Dictionary:
	"""獲取動作使用信息"""
	var info = {}
	if not current_level:
		return info

	for action_type in current_level.individual_action_limits.keys():
		var current = action_usage_count.get(action_type, 0)
		var max_usage = current_level.individual_action_limits.get(action_type, 0)
		info[action_type] = {
			"current": current,
			"max": max_usage,
			"remaining": max_usage - current
		}

	info["total_used"] = _get_total_actions_used()
	info["total_max"] = current_level.max_total_actions
	info["total_remaining"] = current_level.max_total_actions - _get_total_actions_used()

	return info

# 監聽動作佇列變化
func connect_to_action_queue(action_queue: QueuePanel) -> void:
	"""連接到動作佇列以監聯變化"""
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
