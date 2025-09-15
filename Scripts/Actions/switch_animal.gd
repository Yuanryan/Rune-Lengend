# Actions/SwitchAnimalAction.gd
extends TimedAction
class_name SwitchAnimalAction

# Signal 當需要執行動物切換動作時發出
signal animal_switched(target_animal: Animal)

@export var target_animal: Animal

func _init(_target_animal: Animal = null):
    target_animal = _target_animal
    name = "Switch Animal"
    duration = 0.0   # 立即生效

func start(player):
    super.start(player)
    if target_animal:
        # 先切換動物
        player.switch_animal(target_animal)

        animal_switched.emit(target_animal)

func update(player, delta: float) -> bool:
    return super.update(player, delta)
