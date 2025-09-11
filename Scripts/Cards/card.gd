# Cards/Card.gd
extends Resource
class_name Card

@export var action: Action

func play(player: CharacterBody2D) -> void:
    action.execute(player)
