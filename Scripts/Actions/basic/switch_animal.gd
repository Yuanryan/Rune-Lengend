# Actions/SwitchAnimalAction.gd
extends TimedAction
class_name SwitchAnimalAction

# Signal 當需要執行動物切換動作時發出
signal animal_switched(target_animal: Animal)

@export var target_animal: Animal
var switch_animation: TimedAction = null

func _init(_target_animal: Animal = null):
    target_animal = _target_animal
    name = "Switch Animal"
    duration = 1.0   # 給動畫足夠的時間完成

func start(player):
    super.start(player)
    if target_animal:
        # 開始切換動畫
        if player.animal_component:
            player.animal_component.start_switch_animation(target_animal)
        
        # 切換動物
        player.switch_animal(target_animal)
        animal_switched.emit(target_animal)
        
        # 輸出切換信息
        var animal_data = target_animal.animal_data
        print("動物切換完成: %s" % animal_data.name)
        print("新移動速度: %.1f" % animal_data.move_speed)
        print("新跳躍速度: %s" % animal_data.jump_velocity)
    else:
        print("警告：SwitchAnimalAction 沒有目標動物")

func update(player, delta: float) -> bool:
    # 如果有切換動畫，更新動畫
    if player.animal_component and player.animal_component.switch_action:
        var animation_finished = player.animal_component.update_switch_animation(delta)
        if animation_finished:
            return true
    
    return super.update(player, delta)
