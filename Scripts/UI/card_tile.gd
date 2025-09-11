extends TextureRect
class_name CardTile

@export var card: Card
@export var draggable: bool = true
@export var show_label: bool = true
@export var label_font_size: int = 14
@export var label_bg_color: Color = Color(0, 0, 0, 0.55)

var _label: Label
var _bg: ColorRect


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    # 半透明底，滑過高亮
    _bg = ColorRect.new()
    _bg.color = Color(1,1,1,0.06)
    _bg.visible = false
    _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(_bg)
    _bg.set_anchors_preset(Control.PRESET_FULL_RECT)


    if show_label:
        _label = Label.new()
        _label.text = card.label if card else ""
        _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _label.add_theme_font_size_override("font_size", label_font_size)
        var p := Panel.new()
        p.add_child(_label)
        add_child(p)
        p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 0)
        p.mouse_filter = Control.MOUSE_FILTER_IGNORE
        p.modulate = Color(1,1,1,1)
        p.self_modulate = Color(1,1,1,1)
        p.add_theme_stylebox_override("panel", StyleBoxFlat.new())
        (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = label_bg_color
        (p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 8
        (p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_right = 8
        (p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 4
        (p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 4


    if card and texture == null and card.action and card.label:
        # 若無縮圖可用，保留文字條作為識別
        pass

func _get_drag_data(at_position: Vector2) -> Variant:
    if not draggable:
        return null
    var data := {
        "type": "card",
        "card": card
    }
    # 拖曳預覽：複製自己
    var preview := duplicate() as TextureRect
    preview.modulate.a = 0.8
    set_drag_preview(preview)
    return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    return false
func _drop_data(at_position: Vector2, data: Variant) -> void:
    pass
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _bg.visible = true
    elif event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
        _bg.visible = false
