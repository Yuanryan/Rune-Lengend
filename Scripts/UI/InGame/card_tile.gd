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
var _is_dragging: bool = false
var _glow_tween: Tween
# 專供 SWITCH_ANIMAL 使用：記錄目標動物類型（Animal.AnimalType 的整數值）。-1 代表未設定
var animal_type: int = -1

signal card_clicked(card: CardTile)
signal card_dragged(card: CardTile)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    
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
            card_clicked.emit(self)
        elif not mouse_event.pressed:
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
        _glow_tween.kill()
        # 停止發光，恢復原狀
        outline.self_modulate.a = 0
