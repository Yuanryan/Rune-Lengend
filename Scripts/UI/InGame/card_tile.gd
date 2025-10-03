extends TextureRect
class_name CardTile

@export var action_type: Action.ActionType
@export var action_label: String = ""
@export var draggable: bool = true
@export var show_label: bool = true
@export var label_font_size: int = 14
@export var label_bg_color: Color = Color(0, 0, 0, 0.55)
@export var card_size: Vector2 = Vector2(60, 60)


@onready var bg: ColorRect = %ColorRect
@onready var label: RichTextLabel = %Label
@onready var outline: ColorRect = %OutlineColorRect
@onready var usage_label: Label = %UsageLabel

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

func get_action_type() -> Action.ActionType:
    return action_type

func set_action_type(new_action_type: Action.ActionType, new_label: String = "") -> void:
    action_type = new_action_type
    action_label = new_label
    # 確保 label 已經初始化
    if label:
        label.text = get_action_label()
    else:
        # 如果 label 還沒初始化，延遲設置
        _update_label.call_deferred()

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
