# Animals/Animal.gd
@abstract
class_name Animal
extends Resource

@export var animal_data: AnimalResource
var switch_action: Action = null

enum AnimalType {
    MAN,
    RABBIT,
    WOLF
}

func _init(_animal_data: AnimalResource = null):
    if _animal_data:
        animal_data = _animal_data

func get_animal_data() -> AnimalResource:
    return animal_data

func get_switch_action() -> Action:
    return switch_action

static func animal_from_type(animal_type: Animal.AnimalType) -> Animal:
    match animal_type:
        Animal.AnimalType.MAN:
            return Man.new()
        Animal.AnimalType.RABBIT:
            return Rabbit.new()
        Animal.AnimalType.WOLF:
            return Wolf.new()
        _:
            return null
static func get_animal_name(animal_type: Animal.AnimalType) -> String:
    return AnimalType.keys()[animal_type]