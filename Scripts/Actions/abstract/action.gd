# abstract class for actions 
@abstract 
class_name Action
extends Resource

@export var name: String = "Action"
@abstract func start(_player: CharacterBody2D) -> void
@abstract func update(_player: CharacterBody2D, delta: float) -> bool
@abstract func interrupt(_player: CharacterBody2D) -> void

