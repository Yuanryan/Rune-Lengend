# Actions/SwitchAnimalAction.gd
extends TimedAction
class_name SwitchAnimalAction

# Signal 當需要執行動物切換動作時發出
signal animal_switched(target_animal: Animal)

@export var target_animal: Animal
var _switch_action: Action = null

func _init(_target_animal: Animal = null):
    target_animal = _target_animal
    name = "Switch Animal"
    duration = 1.0   # 給動畫足夠的時間完成

func start(player):
    print("[DEBUG] SwitchAnimalAction.start called")
    super.start(player)
    if target_animal:
        print("[DEBUG] SwitchAnimalAction target_animal: ", target_animal.animal_data.name)
        
        # 切換動物
        print("[DEBUG] Calling player.switch_animal")
        player.switch_animal(target_animal)
        print("[DEBUG] Emitting animal_switched signal from SwitchAnimalAction")
        animal_switched.emit(target_animal)
        
        # 輸出切換信息
        var animal_data = target_animal.animal_data
        print("動物切換完成: %s" % animal_data.name)
        print("新移動速度: %.1f" % animal_data.move_speed)
        print("新跳躍速度: %s" % animal_data.jump_velocity)
        
        # 開始切換動作
        _switch_action = target_animal.get_switch_action()
        if _switch_action:
            _switch_action.start(player)
    else:
        print("[DEBUG] 警告：SwitchAnimalAction 沒有目標動物")

func update(player, delta: float) -> bool:
    # 如果有切換動作，更新它
    if _switch_action:
        var finished = _switch_action.update(player, delta)
        if finished:
            _switch_action.interrupt(player)
            _switch_action = null
            return true
        return false
    
    # 沒有切換動作時立即完成
    return true

func interrupt(player: CharacterBody2D) -> void:
    # 如果切換動作還在執行，中斷它
    if _switch_action:
        _switch_action.interrupt(player)
        _switch_action = null
    super.interrupt(player)

