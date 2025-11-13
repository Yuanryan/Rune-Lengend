# Animals/Animal.gd
@abstract
class_name Animal
extends Resource

var animal_data: AnimalResource
var switch_action: Action = null

enum AnimalType {
    MAN,
    RABBIT,
    WOLF
}

func _init():
    animal_data = get_animal_data(get_animal_type())

func get_switch_action() -> Action:
    return switch_action

@abstract func get_animal_type() -> Animal.AnimalType

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

static func get_animal_data(animal_type: Animal.AnimalType) -> AnimalResource:
    match animal_type:
        Animal.AnimalType.MAN:
            return load("uid://d5a707f6axs7")
        Animal.AnimalType.RABBIT:
            return load("uid://vk62uradafkf")
        Animal.AnimalType.WOLF:
            return load("uid://dhl4h4f80cuu3")
        _:
            return null
