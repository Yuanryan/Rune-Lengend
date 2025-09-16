# Animals/Animal.gd
@abstract
class_name Animal
extends Resource

@export var animal_data: AnimalResource
var move_action: MoveAction
var jump_action: JumpAction
var switch_action: Action

func _init(_animal_data: AnimalResource = null):
    if _animal_data:
        animal_data = _animal_data
        _create_actions()

func _create_actions():
    if animal_data:
        # 創建移動動作
        move_action = MoveAction.new(animal_data.move_speed, animal_data.name + "_Move")
        jump_action = JumpAction.new(animal_data.jump_velocity, animal_data.name + "_Jump")

func get_actions() -> Array[Action]:
    var actions: Array[Action] = []
    if move_action:
        actions.append(move_action)
    if jump_action:
        actions.append(jump_action)
    if switch_action:
        actions.append(switch_action)
    return actions

func get_move_action() -> MoveAction:
    return move_action

func get_jump_action() -> JumpAction:
    return jump_action

func get_switch_action() -> Action:
    return switch_action