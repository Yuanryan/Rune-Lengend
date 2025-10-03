# UI/DropMonitor.gd
extends Panel
class_name DropMonitor

signal card_dropped_outside(card: CardTile)
var is_painting: bool = false

func _ready() -> void:
    # 設置為完全透明
    modulate = Color.TRANSPARENT
    mouse_filter = Control.MOUSE_FILTER_PASS
    
    # 設置為全屏
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    
    # 設置 z-index 確保在最上層
    z_index = 1000

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    # 檢查是否為卡片數據
    if typeof(data) != TYPE_DICTIONARY or not data.has("type") or data["type"] != "card":
        return false
    
    var card: CardTile = data["card"]
    if not card:
        return false
    
    # 接受所有卡片拖放
    return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
    """處理拖動到隊列外的卡片"""
    var card: CardTile = data["card"]
    if not card:
        return
    
    # 直接發送信號，表示卡片被拖動到隊列外
    card_dropped_outside.emit(card)
    print("Card dropped outside queue: ", card.get_action_label())

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("paint"):
        is_painting = true
