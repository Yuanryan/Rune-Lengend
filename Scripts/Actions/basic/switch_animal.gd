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
    duration = 0.0   # 給動畫足夠的時間完成

func start(player):
    super.start(player)
    if target_animal:
        # 播放切換動畫

        # 切換動物
        player.switch_animal(target_animal)
        animal_switched.emit(target_animal)
        
        # 開始切換動作
        _switch_action = target_animal.get_switch_action()
        if _switch_action and _switch_action.can_perform(player):
            _switch_action.start(player)
        else:
            # 如果切換動作無法執行，設置為null
            _switch_action = null

func update(player, delta: float) -> bool:
    # 如果有切換動作，更新它
    if _switch_action:
        var finished = _switch_action.update(player, delta)
        if finished:
            _switch_action.interrupt(player)
            _switch_action = null
            return true
        return false
    
    # 沒有切換動作時，使用父類的時間檢查
    return super.update(player, delta)

func interrupt(player: CharacterBody2D) -> void:
    # 如果切換動作還在執行，中斷它
    if _switch_action:
        _switch_action.interrupt(player)
        _switch_action = null
    super.interrupt(player)

