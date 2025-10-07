# Animals/Rabbit.gd
extends Animal
class_name Rabbit


func _init():
    var rabbit_data = load("uid://vk62uradafkf") as AnimalResource
    super._init(rabbit_data)
    switch_action = RabbitSwitchAction.new()

func get_animal_type() -> Animal.AnimalType:
    return Animal.AnimalType.RABBIT

# 兔子的彈跳切換動作
class RabbitSwitchAction extends JumpAction:

    func _init():
        jump_velocity = Vector2(150, -650)
        name = "Rabbit_SuperJump"
    
    func start(player: CharacterBody2D) -> void:
        # 根據玩家的面向方向調整跳躍方向
        jump_velocity.x = abs(jump_velocity.x) * player.facing_direction.x
        
        super.start(player)
    
