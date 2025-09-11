# Actions/SwitchAnimalAction.gd
extends Action
class_name SwitchAnimalAction

@export var target_animal: Animal

func _init():
    name = "Switch Animal"
    duration = 0.0   # 立即生效

func start(player):
    super.start(player)
    if target_animal:
        player.switch_animal(target_animal)