# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

@export var action_queue: Array[Action] = []
var _current_action: Action = null

@export var current_animal: Animal

# 獲取當前動物的數據
func get_current_animal_data() -> AnimalResource:
    """獲取當前動物的資源數據"""
    if current_animal:
        return current_animal.get_animal_data()
    return null

# 根據動作類型創建實際的動作
func create_action_from_type(action_type: Action.ActionType) -> Action:
    """根據動作類型和當前動物數據創建實際的動作"""
    var animal_data = get_current_animal_data()
    if not animal_data:
        print("無法創建動作：沒有當前動物數據")
        return null
    
    match action_type:
        Action.ActionType.MOVE_LEFT:
            return MoveAction.new(-animal_data.move_speed, "Move_Left")
        Action.ActionType.MOVE_RIGHT:
            return MoveAction.new(animal_data.move_speed, "Move_Right")
        Action.ActionType.JUMP_LEFT:
            return JumpAction.new(Vector2(-animal_data.jump_velocity.x, animal_data.jump_velocity.y), "Jump_Left")
        Action.ActionType.JUMP_RIGHT:
            return JumpAction.new(animal_data.jump_velocity, "Jump_Right")
        Action.ActionType.SWITCH_ANIMAL:
            return SwitchAnimalAction.new()
        _:
            print("未知的動作類型: %d" % action_type)
            return null

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

func load_actions_from_ui(action_types: Array[Action.ActionType]) -> void:
    # 將 UI 組好的動作類型轉換為實際的動作並加入 queue
    action_queue.clear()
    for action_type in action_types:
        var action = create_action_from_type(action_type)
        if action:
            action_queue.append(action)
    _current_action = null  # 重新開始
