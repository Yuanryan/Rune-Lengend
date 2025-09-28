# Animals/Rabbit.gd
extends Animal
class_name Rabbit


func _init():
    var rabbit_data = load("uid://vk62uradafkf") as AnimalResource
    super._init(rabbit_data)
    switch_action = RabbitSwitchAction.new()

# 兔子的彈跳切換動作
class RabbitSwitchAction extends JumpAction:

    func _init():
        jump_velocity = Vector2(150, -700)
        name = "Rabbit_Switch"
    
