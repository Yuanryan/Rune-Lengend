# AnimalResource - 存儲動物的基本屬性
extends Resource
class_name AnimalResource

@export var name: String = "Unnamed"
@export var move_speed: float = 100.0
@export var jump_velocity: Vector2 = Vector2(0, -300)
@export var texture: Texture2D
