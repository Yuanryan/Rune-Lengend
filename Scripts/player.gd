# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

@export var action_queue: Array[Action] = []
var _current_action: Action = null

func _ready() -> void:
    GameManager.set_player(self)

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

func load_actions_from_ui(ui_actions: Array[Action]) -> void:
    # 將 UI 組好的動作（Action 陣列）複製到 queue
    action_queue.clear()
    for a in ui_actions:
        action_queue.append(a.duplicate()) # duplicate 以免共享狀態
    _current_action = null  # 重新開始
