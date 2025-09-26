# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

var action_queue: Array[Action] = []
var _current_action: Action = null
var current_animal: Animal
var available_animals: Array[Animal] = []
var is_executing_actions: bool = false
var _total_actions_executed: int = 0

# 動物組件
var animal_component: AnimalComponent

# 信號
signal animal_switched(target_animal: Animal)
signal action_started(action: Action)

func _ready():
    # 初始化動物組件
    animal_component = AnimalComponent.new()
    add_child(animal_component)
    
    # 連接動物切換信號
    connect("animal_switched", _on_animal_switched)

# 獲取當前動物的數據
func get_current_animal_data() -> AnimalResource:
    """獲取當前動物的資源數據"""
    if current_animal:
        return current_animal.get_animal_data()
    return null

func set_current_animal(animal: Animal) -> void:
    current_animal = animal
    if animal_component:
        animal_component.set_current_animal(animal)

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
        if animal_component:
            animal_component.set_current_animal(target_animal)
        # 發出動物切換信號
        animal_switched.emit(target_animal)
        print("切換到動物: ", target_animal.animal_data.name)

func is_executing() -> bool:
    """檢查是否正在執行動作"""
    return is_executing_actions

# 根據動作類型創建實際的動作
func create_action_from_type(action_type: Action.ActionType, animal_type: int = -1) -> Action:
    """根據動作類型和當前動物數據創建實際的動作"""
    var animal_data = get_current_animal_data()
    if not animal_data:
        print("無法創建動作：沒有當前動物數據")
        return null
    
    # 使用動物組件獲取動物的移動特性
    var move_speed = animal_component.get_animal_move_speed() if animal_component else animal_data.move_speed
    var jump_velocity = animal_component.get_animal_jump_velocity() if animal_component else animal_data.jump_velocity
    
    match action_type:
        Action.ActionType.MOVE_LEFT:
            return MoveAction.new(-move_speed, "Move_Left")
        Action.ActionType.MOVE_RIGHT:
            return MoveAction.new(move_speed, "Move_Right")
        Action.ActionType.JUMP_LEFT:
            return JumpAction.new(Vector2(-jump_velocity.x, jump_velocity.y), "Jump_Left")
        Action.ActionType.JUMP_RIGHT:
            return JumpAction.new(jump_velocity, "Jump_Right")
        Action.ActionType.SWITCH_ANIMAL:
            var target_animal: Animal = null
            if animal_type != -1:
                target_animal = Animal.animal_from_type(animal_type)
            else:
                # 如果沒有指定動物類型，使用 MAN 作為默認
                target_animal = Animal.animal_from_type(Animal.AnimalType.MAN)
            return SwitchAnimalAction.new(target_animal)
        _:
            print("未知的動作類型: %d" % action_type)
            return null

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        interrupt_current_action()
    elif event.is_action_pressed("reset_player"):
        # 使用關卡重新載入而不是直接重置玩家
        LevelManager.reload_level_from_last_checkpoint()

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 若沒有正在執行的 action，就從 queue 取下一個
    if _current_action == null and action_queue.size() > 0:
        _current_action = action_queue.pop_front()
        # 發出動作開始信號，讓動物組件調整動作參數
        action_started.emit(_current_action)
        _current_action.start(self)
        _notify_ui_action_started(_total_actions_executed)

    # 更新當前 action
    if _current_action != null:
        var finished := _current_action.update(self, delta)
        if finished:
            _current_action.interrupt(self)
            _notify_ui_action_finished(_total_actions_executed)
            _total_actions_executed += 1  
            _current_action = null
            
            if action_queue.size() > 0:
                _current_action = action_queue.pop_front()
                # 發出動作開始信號，讓動物組件調整動作參數
                action_started.emit(_current_action)
                _current_action.start(self)
                _notify_ui_action_started(_total_actions_executed)
    
    # 檢查是否所有動作都完成了
    if _current_action == null and action_queue.size() == 0 and is_executing_actions:
        is_executing_actions = false
        print("所有動作執行完成")
        UIManager.get_in_game_ui().enable_buttons()
        _notify_ui_all_actions_finished()


    move_and_slide()

# 中斷當前動作並執行下一個
func interrupt_current_action() -> void:
    if _current_action != null:
        # 調用動作的中斷方法進行清理
        _current_action.interrupt(self)
        _notify_ui_action_finished(_total_actions_executed)
        _total_actions_executed += 1  
        _current_action = null
        
        # 立即執行下一個動作（如果有的話）
        if action_queue.size() > 0:
            _current_action = action_queue.pop_front()
            # 發出動作開始信號，讓動物組件調整動作參數
            action_started.emit(_current_action)
            _current_action.start(self)
            _notify_ui_action_started(_total_actions_executed)

func load_actions_from_ui(actions: Array) -> void:
    # 將 UI 組好的動作轉換為實際的動作並加入 queue（支援舊格式與新格式）
    action_queue.clear()
    if actions.size() == 0:
        return
    var first_item = actions[0]
    var use_descriptors: bool = typeof(first_item) == TYPE_DICTIONARY and first_item.has("action_type")
    if use_descriptors:
        for desc in actions:
            if typeof(desc) == TYPE_DICTIONARY and desc.has("action_type"):
                var action_type: int = desc.get("action_type", -1)
                var animal_type: int = desc.get("animal_type", -1)
                var action = create_action_from_type(action_type, animal_type)
                if action:
                    action_queue.append(action)
    else:
        for action_type in actions:
            var action2 = create_action_from_type(action_type)
            if action2:
                action_queue.append(action2)
    _current_action = null  # 重新開始
    _total_actions_executed = 0  # 重置已執行的動作計數
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

func _notify_ui_action_started(index: int) -> void:
    """通知UI動作開始執行"""
    var in_game_ui = UIManager.get_in_game_ui()
    if in_game_ui and in_game_ui.action_queue:
        in_game_ui.action_queue.set_executing_action_index(index)

func _notify_ui_action_finished(index: int) -> void:
    """通知UI動作執行完成"""
    var in_game_ui = UIManager.get_in_game_ui()
    if in_game_ui and in_game_ui.action_queue:
        # 動作完成後清除發光效果
        in_game_ui.action_queue.clear_executing_action()

func _notify_ui_all_actions_finished() -> void:
    """通知UI所有動作執行完成"""
    var in_game_ui = UIManager.get_in_game_ui()
    if in_game_ui and in_game_ui.action_queue:
        in_game_ui.action_queue.clear_executing_action()

func _on_animal_switched(target_animal: Animal) -> void:
    """當動物切換時的回調"""
    print("動物切換完成: ", target_animal.animal_data.name if target_animal and target_animal.animal_data else "未知動物")
