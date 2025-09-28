# Animals/Rabbit.gd
extends Animal
class_name Man


func _init():
    var man_data = load("uid://d5a707f6axs7") as AnimalResource
    super._init(man_data)

func get_switch_action() -> Action:
    return null