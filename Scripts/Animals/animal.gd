# Animals/Animal.gd
@abstract
class_name Animal
extends Resource

@export var animal_data: AnimalResource

enum AnimalType {
    RABBIT,
    WOLF
}

func _init(_animal_data: AnimalResource = null):
    if _animal_data:
        animal_data = _animal_data
