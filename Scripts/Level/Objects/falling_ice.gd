extends CharacterBody2D
class_name FallingIce

@onready var damage_area: DamageArea = %DamageArea
@onready var shape_cast: ShapeCast2D = %ShapeCast2D
@onready var particles: GPUParticles2D = %GPUParticles2D

var is_falling: bool = false


func _physics_process(delta: float) -> void:
    if shape_cast.is_colliding():
        for i in range(shape_cast.get_collision_count()):
            var body = shape_cast.get_collider(i)
            if body is Player or body.is_in_group("Player"):
                is_falling = true
                shape_cast.set_enabled(false)
                damage_area.monitoring = true
                particles.emitting = false
                break
    if is_falling:
        velocity.y += get_gravity().y * delta
        move_and_slide()
    if is_on_floor() and damage_area.monitoring:
        damage_area.monitoring = false
    elif not is_on_floor() and not damage_area.monitoring:
        damage_area.monitoring = true
