# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

@export var action_queue: Array[Action] = []
var _current_action: Action = null

# 動物系統
@export var current_animal: Animal

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        interrupt_current_action()

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 若沒有正在執行的 action，就從 queue 取下一個
    if _current_action == null and action_queue.size() > 0:
        _current_action = action_queue.pop_front()
        _current_action.start(self)

    # 更新當前 action
    if _current_action != null:
        var finished := _current_action.update(self, delta)
        if finished:
            _current_action = null

    move_and_slide()

# 中斷當前動作並執行下一個
func interrupt_current_action() -> void:
    if _current_action != null:
        # 調用動作的中斷方法進行清理
        _current_action.interrupt(self)
        _current_action = null
        # 立即執行下一個動作（如果有的話）
        if action_queue.size() > 0:
            _current_action = action_queue.pop_front()
            _current_action.start(self)

func load_actions_from_ui(ui_actions: Array[Action]) -> void:
    # 將 UI 組好的動作（Action 陣列）複製到 queue
    action_queue.clear()
    for a in ui_actions:
        action_queue.append(a.duplicate()) # duplicate 以免共享狀態
    _current_action = null  # 重新開始
