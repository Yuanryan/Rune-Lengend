# Animals/Animal.gd
# TODO: add abstract keyword after Godot 4.5
extends Resource
class_name Animal

@export var name: String = "Unnamed"

func get_actions() -> Array[Action]:
    return []