# AnimalComponent - 動物組件，控制玩家的動物相關行為
extends Node2D
class_name AnimalComponent

@onready var sprite: Sprite2D = %Sprite2D
@onready var anim_player: AnimationPlayer = %AnimationPlayer
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
    _update_animal_behavior()

func get_current_animal() -> Animal:
    """獲取當前動物"""
    return current_animal


func _update_animal_behavior() -> void:
    """根據當前動物更新行為特性"""
    if not current_animal:
        return

func play_animation(animation_name: String) -> void:
    """播放指定的動畫"""
    if not current_animal or not current_animal.animal_data:
        return
        
    var animal_data = current_animal.animal_data
    var full_animation_name = animal_data.name + "/" + animation_name
    
    if anim_player and anim_player.has_animation(full_animation_name):
        anim_player.play(full_animation_name)


func stop_animation() -> void:
    """停止當前動畫"""
    if anim_player:
        anim_player.stop()

func get_current_animation() -> String:
    """獲取當前播放的動畫名稱"""
    if anim_player:
        return anim_player.current_animation
    return ""

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
    
func _on_animal_switched(target_animal: Animal) -> void:
    """當動物切換時的回調"""
    set_current_animal(target_animal)

func _on_action_started(action: Action) -> void:
    """當動作開始時，根據當前動物調整動作參數並播放動畫"""
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
 
