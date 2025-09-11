extends TextureRect
class_name CardTile

@export var action: Action
@export var draggable: bool = true
@export var show_label: bool = true
@export var label_font_size: int = 14
@export var label_bg_color: Color = Color(0, 0, 0, 0.55)
@export var card_size: Vector2 = Vector2(80, 80)

var _bg: ColorRect
var _label: Label
var _is_dragging: bool = false

signal card_clicked(card: CardTile)
signal card_dragged(card: CardTile)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    custom_minimum_size = card_size
    
    # 半透明底，滑過高亮
    _bg = ColorRect.new()
    _bg.color = Color(1,1,1,0.06)
    _bg.visible = false
    _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(_bg)
    _bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    
    # 創建標籤顯示動作名稱
    if show_label:
        _create_label()
    
    # 更新顯示
    _update_display()

func _create_label() -> void:
    _label = Label.new()
    _label.text = get_action_label()
    _label.add_theme_font_size_override("font_size", label_font_size)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # 添加背景
    var label_bg = ColorRect.new()
    label_bg.color = label_bg_color
    label_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label_bg.add_child(_label)
    label_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(label_bg)

func _update_display() -> void:
    if _label and action:
        _label.text = get_action_label()
    
    # 根據動作類型設置不同的視覺樣式
    if action:
        _update_visual_style()

func _update_visual_style() -> void:
    if not action:
        return
        
    # 根據動作類型設置顏色和圖標
    var base_color = Color.WHITE
    var icon_text = "?"
    
    if action is BasicMove:
        var move_action = action as BasicMove
        if move_action.velocity.x > 0:
            icon_text = "→"
            base_color = Color.CYAN
        elif move_action.velocity.x < 0:
            icon_text = "←"
            base_color = Color.CYAN
        elif move_action.velocity.y < 0:
            icon_text = "↑"
            base_color = Color.YELLOW
    elif action is SwitchAnimalAction:
        icon_text = "🐺"
        base_color = Color.GREEN
    
    # 設置背景顏色
    modulate = base_color
    
    # 如果有標籤，更新圖標
    if _label:
        _label.text = icon_text

func get_action_label() -> String:
    if not action:
        return "Empty"
    return action.name

func get_action() -> Action:
    return action

func set_action(new_action: Action) -> void:
    action = new_action
    _update_display()

func _get_drag_data(at_position: Vector2) -> Variant:
    if not draggable or not action:
        return null
    
    _is_dragging = true
    card_dragged.emit(self)
    
    var data := {
        "type": "card",
        "card": self,
        "action": action
    }
    
    # 拖曳預覽：複製自己
    var preview := duplicate() as CardTile
    preview.modulate.a = 0.8
    preview._is_dragging = true
    set_drag_preview(preview)
    return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    pass

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if not _is_dragging:
            _bg.visible = true
    elif event is InputEventMouseButton:
        var mouse_event = event as InputEventMouseButton
        if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            card_clicked.emit(self)
        elif not mouse_event.pressed:
            _bg.visible = false
            _is_dragging = false
