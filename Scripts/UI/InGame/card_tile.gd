extends TextureRect
class_name CardTile


@export var action_type: Action.ActionType
@export var action_label: String = ""
@export var draggable: bool = true
@export var show_label: bool = true
@export var label_font_size: int = 14
@export var label_bg_color: Color = Color(0, 0, 0, 0.55)
@export var card_size: Vector2 = Vector2(60, 60)


@export_group("Assets")
@export_subgroup("Images")
@export var run_left_image: Texture2D = null
@export var run_right_image: Texture2D = null
@export var jump_left_image: Texture2D = null
@export var jump_right_image: Texture2D = null
@export var switch_man_image: Texture2D = null
@export var switch_rabbit_image: Texture2D = null
@export var switch_wolf_image: Texture2D = null
@export var template_image: Texture2D = null
@export_subgroup("Frames")
@export var frame_switch_man: Texture2D = null
@export var frame_switch_rabbit: Texture2D = null 
@export var frame_switch_wolf: Texture2D = null
@export var frame_default: Texture2D = null



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
var _interactable: bool = true

@export var click_sound: AudioStream = null
var _click_player: AudioStreamPlayer = null

signal card_clicked(card: CardTile)
signal card_dragged(card: CardTile)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

    if click_sound:
        _click_player = AudioStreamPlayer.new()
        _click_player.stream = click_sound
        add_child(_click_player)

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

    var selected_texture: Texture2D = null

    match action_type:
        Action.ActionType.MOVE_LEFT:
            if self.run_left_image:
                selected_texture = self.run_left_image
        Action.ActionType.MOVE_RIGHT:
            if self.run_right_image:
                selected_texture = self.run_right_image
        Action.ActionType.JUMP_LEFT:
            if self.jump_left_image:
                selected_texture = self.jump_left_image
        Action.ActionType.JUMP_RIGHT:
            if self.jump_right_image:
                selected_texture = self.jump_right_image
        Action.ActionType.SWITCH_ANIMAL:
            match animal_type:
                Animal.AnimalType.MAN:
                    if self.switch_man_image:
                        selected_texture = self.switch_man_image
                Animal.AnimalType.RABBIT:
                    if self.switch_rabbit_image:
                        selected_texture = self.switch_rabbit_image
                Animal.AnimalType.WOLF:
                    if self.switch_wolf_image:
                        selected_texture = self.switch_wolf_image
                _:
                    if self.template_image:
                        selected_texture = self.template_image
        _:
            if self.template_image:
                selected_texture = self.template_image

    # 設置圖片（僅使用變數，不做後援載入）
    image.texture = selected_texture

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

    var selected_frame: Texture2D = null

    # 只有切換動物的卡片才使用不同的外框
    if action_type == Action.ActionType.SWITCH_ANIMAL:
        match animal_type:
            Animal.AnimalType.MAN:
                if self.frame_switch_man:
                    selected_frame = self.frame_switch_man
            Animal.AnimalType.RABBIT:
                if self.frame_switch_rabbit:
                    selected_frame = self.frame_switch_rabbit
            Animal.AnimalType.WOLF:
                if self.frame_switch_wolf:
                    selected_frame = self.frame_switch_wolf
            _:
                if self.frame_default:
                    selected_frame = self.frame_default
    else:
        # 其他動作使用預設外框
        if self.frame_default:
            selected_frame = self.frame_default

    # 設置外框圖片（僅使用變數，不做後援載入）
    bg.texture = selected_frame

func _update_label() -> void:
    # 在 _ready 完成後更新 label
    if label:
        label.text = get_action_label()

func get_action_label() -> String:
    if action_label != "":
        return action_label
    return "Empty"

func _get_drag_data(at_position: Vector2) -> Variant:
    if not draggable or not _can_use or not _interactable:
        return null

    _is_dragging = true
    card_dragged.emit(self)
    
    # 開始拖曳時整個卡片變暗
    modulate = Color(0.6, 0.6, 0.6, 0.6)

    var data := {
        "type": "card",
        "card": self,
        "action_type": action_type,
        "animal_type": animal_type
    }

    var preview := duplicate() as CardTile
    preview.modulate.a = 0.8
    preview._is_dragging = true
    
    # 手動重新初始化子節點引用（duplicate 後 @onready 不會重新執行）
    preview.image = preview.get_node_or_null("%TextureRect")
    preview.bg = preview.get_node_or_null("%NinePatchRect")
    preview.color_rect = preview.get_node_or_null("%ColorRect")
    preview.usage_label = preview.get_node_or_null("%UsageLabel")
    
    # 確保 animal_type 被複製並更新視覺
    preview.animal_type = animal_type
    preview._update_card_image()
    preview._update_card_color()
    preview._update_card_frame()
    
    # 將預覽置中於滑鼠點擊位置
    var preview_container := Control.new()
    preview.position = -at_position
    preview_container.add_child(preview)
    
    set_drag_preview(preview_container)
    return data

func _notification(what: int) -> void:
    if what == NOTIFICATION_DRAG_END:
        # 拖曳結束時恢復正常
        _is_dragging = false
        modulate = Color(1.0, 1.0, 1.0, 1.0)

func _gui_input(event: InputEvent) -> void:
    if not _can_use or not _interactable:
        return

    if event is InputEventMouseMotion:
        if not _is_dragging:
            bg.visible = true
    elif event is InputEventMouseButton:
        var mouse_event = event as InputEventMouseButton
        if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            # 按下時整個卡片變暗
            modulate = Color(0.7, 0.7, 0.7, 1.0)
        elif not mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            # 釋放時恢復正常並觸發點擊事件
            modulate = Color(1.0, 1.0, 1.0, 1.0)
            if _click_player and click_sound:
                _click_player.play()
            card_clicked.emit(self)
            _is_dragging = false

func set_executing(is_executing: bool) -> void:
    """設置卡片執行狀態，顯示閃爍效果"""
    # 停止現有的動畫
    if _glow_tween:
        _glow_tween.kill()
        _glow_tween = null

    if is_executing:
        # 開始閃爍動畫（整張卡片的 modulate 閃爍）
        _glow_tween = create_tween().set_trans(Tween.TRANS_SINE)
        _glow_tween.set_loops()
        # 從正常亮度閃到更亮
        _glow_tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.3)
        _glow_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
    else:
        # 停止閃爍，恢復正常
        modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_dimmed(is_dimmed: bool) -> void:
    """設置卡片變暗狀態"""
    if is_dimmed:
        modulate = Color(0.5, 0.5, 0.5, 0.7)
    else:
        # 只有在沒有執行中的閃爍動畫時才恢復
        if not _glow_tween or not _glow_tween.is_running():
            modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_interactable(enabled: bool) -> void:
    """控制卡片是否可被點擊/拖曳"""
    _interactable = enabled
    draggable = enabled
    mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE


func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    if new_state != GameManager.InGameState.EXECUTING:
        set_executing(false)
        set_dimmed(false)

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

    if _max_usage < 999:
        # 有限制：顯示 剩餘/最大
        usage_label.text = str(_max_usage - _current_usage) + "/" + str(_max_usage)
        usage_label.visible = true
    else:
        # 無限制：不顯示
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
