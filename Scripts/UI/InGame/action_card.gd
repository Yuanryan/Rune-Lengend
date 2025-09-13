# UI/ActionCard.gd
extends CardTile
class_name ActionCard

# Specialized card for displaying and managing actions
# This extends CardTile with action-specific functionality

@export var action_type: String = ""
@export var cooldown_duration: float = 0.0
@export var max_uses: int = -1  # -1 means unlimited

var _current_uses: int = 0
var _is_on_cooldown: bool = false
var _cooldown_timer: float = 0.0

signal action_executed(card: ActionCard)
signal cooldown_finished(card: ActionCard)
signal uses_changed(card: ActionCard, current_uses: int, max_uses: int)

func _ready() -> void:
    super._ready()
    _current_uses = max_uses if max_uses > 0 else 0

func _process(delta: float) -> void:
    if _is_on_cooldown:
        _cooldown_timer -= delta
        if _cooldown_timer <= 0.0:
            _is_on_cooldown = false
            cooldown_finished.emit(self)
            _update_display()

func can_execute() -> bool:
    if not action:
        return false
    if _is_on_cooldown:
        return false
    if max_uses > 0 and _current_uses >= max_uses:
        return false
    return true

func execute_action() -> bool:
    if not can_execute():
        return false
    
    # 增加使用次數
    if max_uses > 0:
        _current_uses += 1
        uses_changed.emit(self, _current_uses, max_uses)
    
    # 開始冷卻
    if cooldown_duration > 0.0:
        _is_on_cooldown = true
        _cooldown_timer = cooldown_duration
    
    action_executed.emit(self)
    _update_display()
    return true

func reset_uses() -> void:
    _current_uses = 0
    uses_changed.emit(self, _current_uses, max_uses)
    _update_display()

func get_remaining_uses() -> int:
    if max_uses <= 0:
        return -1  # Unlimited
    return max(0, max_uses - _current_uses)

func get_cooldown_progress() -> float:
    if not _is_on_cooldown or cooldown_duration <= 0.0:
        return 1.0
    return 1.0 - (_cooldown_timer / cooldown_duration)

func _update_display() -> void:
    # 更新視覺狀態
    if _is_on_cooldown:
        modulate = Color(0.5, 0.5, 0.5, 0.7)
    elif not can_execute():
        modulate = Color(0.8, 0.8, 0.8, 0.8)
    else:
        modulate = Color.WHITE
    
    # 更新標籤顯示使用次數
    if has_node("Label") and max_uses > 0:
        var label_node = get_node("Label")
        var uses_text = str(_current_uses) + "/" + str(max_uses)
        if _is_on_cooldown:
            uses_text += " (CD)"
        label_node.text = get_action_label() + "\n" + uses_text

func set_action_type(type: String) -> void:
    action_type = type
    _update_display()

func get_action_type() -> String:
    return action_type

# 從資源文件創建動作卡片
static func create_from_resource(resource: Resource) -> ActionCard:
    var card = ActionCard.new()
    if resource is BasicMove:
        card.set_action(resource)
        card.action_type = "move"
    elif resource is SwitchAnimalAction:
        card.set_action(resource)
        card.action_type = "switch"
    return card

# 從預設的動作資源創建卡片
static func create_from_action_resource(action_resource: Action) -> ActionCard:
    var card = ActionCard.new()
    card.set_action(action_resource)
    
    # 自動檢測動作類型
    if action_resource is BasicMove:
        var move_action = action_resource as BasicMove
        if move_action.velocity.y < 0:
            card.action_type = "jump"
        else:
            card.action_type = "move"
    elif action_resource is SwitchAnimalAction:
        card.action_type = "switch"
    
    return card
