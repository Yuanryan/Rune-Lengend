# AnimalComponent - 動物組件，控制玩家的動物相關行為
extends Node2D
class_name AnimalComponent

@onready var sprite: Sprite2D = %Sprite2D
var player: Player = null

var current_animal: Animal = null
var available_animals: Array[Animal] = []
var switch_action: Action = null

func _ready():
    # 確保玩家存在
    player = get_parent()
    
    # 監聽動物切換信號
    player.animal_switched.connect(_on_animal_switched)
    player.action_started.connect(_on_action_started)

func set_player(player_ref: Player) -> void:
    self.player = player_ref

func set_available_animals(animals: Array[Animal.AnimalType]) -> void:
    """設置可用動物並初始化第一個動物"""
    available_animals.clear()
    for animal_type in animals:
        available_animals.append(Animal.animal_from_type(animal_type))
    
    # 設置第一個動物為當前動物，並通過Player發出信號
    if available_animals.size() > 0:
        if player:
            player.switch_animal(available_animals[0])
        else:
            set_current_animal(available_animals[0])

func set_current_animal(animal: Animal) -> void:
    """設置當前動物並更新相關屬性"""
    if not animal:
        return
    
    current_animal = animal
    _update_animal_appearance()
    _update_animal_behavior()

func _update_animal_appearance() -> void:
    """根據當前動物更新玩家外觀"""
    if not current_animal or not current_animal.animal_data:
        return
    
    var animal_data = current_animal.animal_data
    if animal_data.texture and sprite:
        sprite.texture = animal_data.texture
        print("更新玩家外觀為: ", animal_data.name)

func _update_animal_behavior() -> void:
    """根據當前動物更新行為特性"""
    if not current_animal:
        return
    
    # 這裡可以添加動物特定的行為邏輯
    # 例如：狼可能有夜視能力，兔子可能有更好的跳躍等
    print("更新動物行為: ", current_animal.animal_data.name)

func get_animal_move_speed() -> float:
    """獲取當前動物的移動速度"""
    if current_animal and current_animal.animal_data:
        return current_animal.animal_data.move_speed
    return 100.0  # 默認速度

func get_animal_jump_velocity() -> Vector2:
    """獲取當前動物的跳躍速度"""
    if current_animal and current_animal.animal_data:
        return current_animal.animal_data.jump_velocity
    return Vector2(0, -300)  # 默認跳躍

func start_switch_animation(target_animal: Animal) -> void:
    """開始動物切換動畫"""
    if not target_animal:
        return
    
    # 根據目標動物類型選擇不同的切換動畫
    match target_animal.animal_data.name:
        "Wolf":
            switch_action = Wolf.WolfSwitchAction.new()
        "Rabbit":
            switch_action = Rabbit.RabbitSwitchAction.new()
        _:
            # 默認切換動畫
            switch_action = DefaultSwitchAction.new()
    
    if switch_action:
        switch_action.start(player)

func update_switch_animation(delta: float) -> bool:
    """更新切換動畫，返回是否完成"""
    if switch_action:
        var finished = switch_action.update(player, delta)
        if finished:
            switch_action = null
            return true
    return false

func _on_animal_switched(target_animal: Animal) -> void:
    """當動物切換時的回調"""
    set_current_animal(target_animal)

func _on_action_started(action: Action) -> void:
    """當動作開始時，根據當前動物調整動作參數"""
    if not current_animal or not current_animal.animal_data:
        return
    
    var animal_data = current_animal.animal_data
    
    # 處理移動動作
    if action is MoveAction:
        var new_velocity = animal_data.move_speed * action.direction
        action.set_velocity_x(new_velocity)
    
    # 處理跳躍動作
    elif action is JumpAction:
        var new_jump_velocity = animal_data.jump_velocity * action.direction
        action.set_jump_velocity(new_jump_velocity)

# 默認切換動畫
class DefaultSwitchAction extends TimedAction:
    func _init():
        duration = 0.5
        name = "Default_Switch"
    
    func start(player: CharacterBody2D):
        super.start(player)
        player.modulate.a = 0.5
    
    func update(player: CharacterBody2D, delta: float) -> bool:
        # 簡單的淡入淡出效果
        var progress = 1.0 - (_time_left / duration)
        player.modulate.a = lerp(0.5, 1.0, progress)
        return super.update(player, delta)
