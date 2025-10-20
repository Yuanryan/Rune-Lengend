extends TextureRect
class_name CardTile


@export var action_type: Action.ActionType
@export var action_label: String = ""
@export var draggable: bool = true
@export var show_label: bool = true
@export var label_font_size: int = 14
@export var label_bg_color: Color = Color(0, 0, 0, 0.55)
@export var card_size: Vector2 = Vector2(60, 60)


@onready var bg: NinePatchRect = %NinePatchRect
@onready var image: TextureRect = %TextureRect
@onready var label: RichTextLabel = %Label
@onready var outline: ColorRect = %OutlineColorRect
@onready var usage_label: Label = %UsageLabel
@onready var color_rect: ColorRect = %ColorRect



var _is_dragging: bool = false
var _glow_tween: Tween
# 專供 SWITCH_ANIMAL 使用：記錄目標動物類型（Animal.AnimalType 的整數值）。-1 代表未設定
var animal_type: int = -1

# 動作使用限制相關
var _can_use: bool = true
var _current_usage: int = 0
var _max_usage: int = 999

signal card_clicked(card: CardTile)
signal card_dragged(card: CardTile)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

	# 隱藏標籤，使用圖片顯示
	if label:
		label.visible = false

	# 確保圖片正確設置
	_update_card_image()

	# 設置卡片顏色
	_update_card_color()

	# 設置外框圖片
	_update_card_frame()

func get_action_type() -> Action.ActionType:
	return action_type

func set_action_type(new_action_type: Action.ActionType, new_label: String = "") -> void:
	action_type = new_action_type
	action_label = new_label
	# 設置對應的圖片
	_update_card_image()
	# 設置對應的顏色
	_update_card_color()
	# 設置對應的外框
	_update_card_frame()

func _update_card_image() -> void:
	"""根據動作類型和動物類型設置對應的圖片"""
	if not image:
		return

	var texture_path: String = ""

	match action_type:
		Action.ActionType.MOVE_LEFT:
			texture_path = "res://Assets/cards/run_left.png"
		Action.ActionType.MOVE_RIGHT:
			texture_path = "res://Assets/cards/run_right.png"
		Action.ActionType.JUMP_LEFT:
			texture_path = "res://Assets/cards/jump_left.png"
		Action.ActionType.JUMP_RIGHT:
			texture_path = "res://Assets/cards/jump_right.png"
		Action.ActionType.SWITCH_ANIMAL:
			# 根據動物類型選擇對應的切換圖片
			match animal_type:
				Animal.AnimalType.MAN:
					texture_path = "res://Assets/RUNE/RUNE_SwitchMan_mini.png"
				Animal.AnimalType.RABBIT:
					texture_path = "res://Assets/RUNE/RUNE_SwitchRabbit_mini.png"
				Animal.AnimalType.WOLF:
					texture_path = "res://Assets/RUNE/RUNE_SwitchWolf_mini.png"
				_:
					texture_path = "res://Assets/RUNE/RUNE_template.png"
		_:
			texture_path = "res://Assets/RUNE/RUNE_template.png"

	# 載入並設置圖片
	if ResourceLoader.exists(texture_path):
		var card_texture = load(texture_path) as Texture2D
		if card_texture:
			image.texture = card_texture
	else:
		print("找不到圖片資源: ", texture_path)

func _update_card_color() -> void:
	"""根據動作類型設置卡片背景顏色"""
	if not color_rect:
		return

	color_rect.color = _get_action_color()

func _get_action_color() -> Color:
	"""根據動作類型返回對應的顏色"""
	match action_type:
		Action.ActionType.MOVE_LEFT, Action.ActionType.MOVE_RIGHT, Action.ActionType.JUMP_LEFT, Action.ActionType.JUMP_RIGHT:
			# 移動動作 - 藍綠色
			return Color(0.11372549, 0.4745098, 0.45882353, 0.6862745)

		Action.ActionType.SWITCH_ANIMAL:
			match animal_type:
				Animal.AnimalType.MAN:
					return Color8(43, 39, 13, 255)
				Animal.AnimalType.RABBIT:
					return Color8(106, 68, 106, 255)
				Animal.AnimalType.WOLF:
					return Color8(35, 69, 83, 255)
				_:
					return Color8(68, 68, 68, 175)
		_:
			return Color(0, 0, 0, 0)

func _update_card_frame() -> void:
	"""根據動作類型和動物類型設置外框圖片"""
	if not bg:
		return

	var frame_path: String = ""

	# 只有切換動物的卡片才使用不同的外框
	if action_type == Action.ActionType.SWITCH_ANIMAL:
		match animal_type:
			Animal.AnimalType.MAN:
				frame_path = "res://Assets/RUNE/frame_SwitchMan.png"
			Animal.AnimalType.RABBIT:
				frame_path = "res://Assets/RUNE/frame_SwitchRabbit.png"
			Animal.AnimalType.WOLF:
				frame_path = "res://Assets/RUNE/frame_SwitchWolf.png"
			_:
				frame_path = "res://Assets/RUNE/RUNE_template.png"
	else:
		# 其他動作使用預設外框
		frame_path = "res://Assets/RUNE/RUNE_template.png"

	# 載入並設置外框圖片
	if ResourceLoader.exists(frame_path):
		var frame_texture = load(frame_path) as Texture2D
		if frame_texture:
			bg.texture = frame_texture
	else:
		print("找不到外框圖片: ", frame_path)

func _update_label() -> void:
	# 在 _ready 完成後更新 label
	if label:
		label.text = get_action_label()

func get_action_label() -> String:
	if action_label != "":
		return action_label
	return "Empty"

func _get_drag_data(at_position: Vector2) -> Variant:
	if not draggable:
		return null

	_is_dragging = true
	card_dragged.emit(self)

	var data := {
		"type": "card",
		"card": self,
		"action_type": action_type,
		"animal_type": animal_type
	}

	var preview := duplicate() as CardTile
	preview.modulate.a = 0.8
	preview._is_dragging = true
	set_drag_preview(preview)
	return data

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _is_dragging:
			bg.visible = true
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# 按下時不觸發點擊事件，只處理拖拽
			pass
		elif not mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# 釋放時觸發點擊事件
			card_clicked.emit(self)
			bg.visible = false
			_is_dragging = false

func set_executing(is_executing: bool) -> void:
	"""設置卡片執行狀態，顯示發光效果"""
	if not outline:
		return

	# 停止現有的動畫
	if _glow_tween:
		_glow_tween.kill()

	if is_executing:
		# 開始發光動畫
		_glow_tween = create_tween().set_trans(Tween.TRANS_SINE)
		_glow_tween.set_loops()
		_glow_tween.tween_property(outline, "self_modulate:a", 0.8, 0.8)
		_glow_tween.tween_property(outline, "self_modulate:a", 0, 0.8)
	else:
		if _glow_tween:
			_glow_tween.kill()
		# 停止發光，恢復原狀
		outline.self_modulate.a = 0


func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
	"""處理遊戲內狀態變化"""
	if new_state != GameManager.InGameState.EXECUTING:
		set_executing(false)

# 設置使用信息
func set_usage_info(usable: bool, current_usage: int, max_usage: int) -> void:
	"""設置動作使用信息"""
	_can_use = usable
	_current_usage = current_usage
	_max_usage = max_usage

	_update_usage_display()
	_update_visual_state()

# 更新使用次數顯示
func _update_usage_display() -> void:
	"""更新使用次數顯示"""
	if not usage_label:
		return

	if _max_usage < 999:  # 只有有限制的動作才顯示
		usage_label.text = str(_max_usage - _current_usage) + "/" + str(_max_usage)
		usage_label.visible = true
	else:
		usage_label.visible = false

# 更新視覺狀態
func _update_visual_state() -> void:
	"""根據可用狀態更新視覺效果"""
	if not _can_use:
		# 禁用狀態：變暗並降低透明度
		modulate = Color(0.5, 0.5, 0.5, 0.6)
		draggable = false
	else:
		# 可用狀態：恢復正常
		modulate = Color.WHITE
		draggable = true

# 檢查是否可以使用
func can_use() -> bool:
	"""檢查卡片是否可以使用"""
	return _can_use
