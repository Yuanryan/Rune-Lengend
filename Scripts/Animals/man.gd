# Animals/Rabbit.gd
extends Animal
class_name Man


func get_animal_type() -> Animal.AnimalType:
    return Animal.AnimalType.MAN

func get_switch_action() -> Action:
    return null