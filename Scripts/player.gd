# Player/Player.gd
extends CharacterBody2D
class_name Player

const GRAVITY := 1000.0

var action_queue: Array[Action] = []
var _current_action: Action = null
var is_executing_actions: bool = false
var _total_actions_executed: int = 0

# 動物組件
@onready var animal_component: AnimalComponent = %AnimalComponent

# 信號
signal animal_switched(target_animal: Animal)
signal action_started(action: Action)
signal player_died()

func _ready():
    # 連接動物切換信號
    animal_switched.connect(_on_animal_switched)
    animal_component.set_player(self)
    
    # 連接 GameManager 的狀態變化信號
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func set_available_animals(animals: Array[Animal.AnimalType]) -> void:
    """設置可用動物 - 委託給 AnimalComponent 處理"""
    animal_component.set_available_animals(animals)

func switch_animal(target_animal: Animal) -> void:
    """切換到指定的動物"""
    if target_animal:
        # 發出動物切換信號，讓AnimalComponent處理實際的切換
        animal_switched.emit(target_animal)
        print("切換到動物: ", target_animal.animal_data.name)

func is_executing() -> bool:
    """檢查是否正在執行動作"""
    return is_executing_actions

# 根據動作類型創建實際的動作
func create_action_from_type(action_type: Action.ActionType, animal_type: int = -1) -> Action:
    """根據動作類型和當前動物數據創建實際的動作"""

    match action_type:
        Action.ActionType.MOVE_LEFT:
            return MoveAction.new(-1., "Move_Left")
        Action.ActionType.MOVE_RIGHT:
            return MoveAction.new(1., "Move_Right")
        Action.ActionType.JUMP_LEFT:
            return JumpAction.new(Vector2(-1, 1), "Jump_Left")
        Action.ActionType.JUMP_RIGHT:
            return JumpAction.new(Vector2(1, 1), "Jump_Right")
        Action.ActionType.SWITCH_ANIMAL:
            var target_animal: Animal = null
            if animal_type != -1:
                target_animal = Animal.animal_from_type(animal_type)
            return SwitchAnimalAction.new(target_animal)
        _:
            print("未知的動作類型: %d" % action_type)
            return null

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        interrupt_current_action()
    elif event.is_action_pressed("reset_player"):
        # 調用與重置按鈕相同的邏輯
        var in_game_ui = UIManager.get_in_game_ui()
        if in_game_ui:
            in_game_ui.reset_player()

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 若沒有正在執行的 action，就從 queue 取下一個
    if _current_action == null and action_queue.size() > 0:
        _start_next_action()

    # 更新當前 action
    if _current_action != null:
        var finished := _current_action.update(self, delta)
        if finished:
            _finish_current_action()

    # 檢查是否所有動作都完成了
    _check_all_actions_completed()
    move_and_slide()

# 輔助方法
func _start_next_action() -> void:
    """開始執行下一個動作"""
    if action_queue.size() > 0:
        _current_action = action_queue.pop_front()
        # 發出動作開始信號，讓動物組件調整動作參數
        action_started.emit(_current_action)
        _current_action.start(self)
        _notify_ui_action_started(_total_actions_executed)

func _finish_current_action() -> void:
    """完成當前動作並開始下一個"""
    _current_action.interrupt(self)
    _notify_ui_action_finished(_total_actions_executed)
    _total_actions_executed += 1  
    _current_action = null
    
    # 如果還有動作，立即開始下一個
    if action_queue.size() > 0:
        _start_next_action()

func _check_all_actions_completed() -> void:
    """檢查是否所有動作都完成了"""
    if _current_action == null and action_queue.size() == 0 and is_executing_actions:
        is_executing_actions = false
        print("所有動作執行完成")
        velocity = Vector2.ZERO
        # 使用新的狀態系統
        GameManager.complete_execution()
        _notify_ui_all_actions_finished()

func interrupt_current_action() -> void:
    """中斷當前動作並執行下一個"""
    if _current_action != null:
        _finish_current_action()

func load_actions_from_ui(actions: Array) -> void:
    """將 UI 組好的動作轉換為實際的動作並加入 queue"""
    action_queue.clear()
    if actions.is_empty():
        return
    
    # 檢查是否使用描述符格式
    var use_descriptors: bool = actions[0] is Dictionary and actions[0].has("action_type")
    
    for item in actions:
        var action: Action = null
        if use_descriptors:
            var desc = item as Dictionary
            var action_type: int = desc.get("action_type", -1)
            var animal_type: int = desc.get("animal_type", -1)
            action = create_action_from_type(action_type, animal_type)
        else:
            action = create_action_from_type(item)
        
        if action:
            action_queue.append(action)
    
    # 重置執行狀態
    _current_action = null
    _total_actions_executed = 0
    is_executing_actions = true

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
    
    # 使用新的狀態系統重置到規劃階段
    GameManager.reset_to_planning()
    print("玩家已重置到起始點")

func die() -> void:
    """玩家死亡處理"""
    print("玩家死亡")
    # 使用新的狀態系統
    GameManager.fail_execution()
    # 停止所有動作
    action_queue.clear()
    if _current_action != null:
        _current_action.interrupt(self)
        _current_action = null
    is_executing_actions = false
    
    # 發出死亡信號
    player_died.emit()
    
    # 重置速度
    velocity = Vector2.ZERO
    

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

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
    print("Player: 遊戲內狀態變更為 ", new_state)
    
    # 根據狀態執行相應的處理
    match new_state:
        GameManager.InGameState.PLANNING:
            _on_planning_state_entered()
        GameManager.InGameState.EXECUTING:
            _on_executing_state_entered()
        GameManager.InGameState.COMPLETED:
            _on_completed_state_entered()
        GameManager.InGameState.FAILED:
            _on_failed_state_entered()
        GameManager.InGameState.PAUSED:
            _on_paused_state_entered()

# 狀態響應方法
func _on_planning_state_entered() -> void:
    """進入規劃階段時的處理"""
    print("Player: 進入規劃階段")
    is_executing_actions = false
    
    # 停止所有正在執行的動作
    if _current_action != null:
        _current_action.interrupt(self)
        _current_action = null
    
    # 清空動作佇列
    action_queue.clear()
    
    # 重置執行計數
    _total_actions_executed = 0
    

func _on_executing_state_entered() -> void:
    """進入執行階段時的處理"""
    print("Player: 進入執行階段")
    is_executing_actions = true

func _on_completed_state_entered() -> void:
    """進入完成階段時的處理"""
    print("Player: 進入完成階段")
    is_executing_actions = false

func _on_failed_state_entered() -> void:
    """進入失敗階段時的處理"""
    print("Player: 進入失敗階段")
    is_executing_actions = false

func _on_paused_state_entered() -> void:
    """進入暫停階段時的處理"""
    print("Player: 進入暫停階段")
    # 暫停階段不需要額外處理
