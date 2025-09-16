# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

var action_queue: Array[Action] = []
var _current_action: Action = null
var current_animal: Animal
var available_animals: Array[Animal] = []
var is_executing_actions: bool = false

# 獲取當前動物的數據
func get_current_animal_data() -> AnimalResource:
    """獲取當前動物的資源數據"""
    if current_animal:
        return current_animal.get_animal_data()
    return null

func set_current_animal(animal: Animal) -> void:
    current_animal = animal

func set_available_animals(animals: Array[Animal.AnimalType]) -> void:
    for animal_type in animals:
        match animal_type:
            Animal.AnimalType.WOLF:
                available_animals.append(Wolf.new())
            Animal.AnimalType.RABBIT:
                available_animals.append(Rabbit.new())
    set_current_animal(available_animals[0])

func switch_animal(target_animal: Animal) -> void:
    """切換到指定的動物"""
    if target_animal:
        current_animal = target_animal
        # 可以在這裡添加切換動物的視覺效果
        print("切換到動物: ", target_animal.animal_data.name)

func is_executing() -> bool:
    """檢查是否正在執行動作"""
    return is_executing_actions

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

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        interrupt_current_action()
    elif event.is_action_pressed("reset_player"):
        # 使用關卡重新載入而不是直接重置玩家
        LevelManager.reload_current_level()

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
            _current_action.interrupt(self)
            _current_action = null
            if action_queue.size() > 0:
                _current_action = action_queue.pop_front()
                _current_action.start(self)
    
    # 檢查是否所有動作都完成了
    if _current_action == null and action_queue.size() == 0 and is_executing_actions:
        is_executing_actions = false
        print("所有動作執行完成")
        UIManager.get_in_game_ui().enable_buttons()


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
    is_executing_actions = true  # 開始執行動作

func reset_to_starting_point() -> void:
    """重置玩家到起始點"""
    # 停止所有動作
    action_queue.clear()
    if _current_action != null:
        _current_action.interrupt(self)
        _current_action = null
    is_executing_actions = false
    
    # 重置速度
    velocity = Vector2.ZERO
    
    # 獲取當前關卡的起始點位置
    var level = get_parent()
    if level and level.has_method("get_starting_point_position"):
        global_position = level.get_starting_point_position()
    elif level and level.has_node("StartingPoint"):
        global_position = level.get_node("StartingPoint").global_position
    else:
        print("無法找到起始點位置")
    
    # 重新啟用UI按鈕
    UIManager.get_in_game_ui().enable_buttons()
    print("玩家已重置到起始點")
