# Animals/Rabbit.gd
extends Animal
class_name Rabbit


func _init():
    super._init()
    switch_action = RabbitSwitchAction.new()

func get_animal_type() -> Animal.AnimalType:
    return Animal.AnimalType.RABBIT

# 兔子的彈跳切換動作
class RabbitSwitchAction extends JumpAction:
    
    func _init():
        jump_velocity = Vector2(150, -650)
        name = "Jump_Right"  # 使用現有的跳躍動畫
    
    func start(player: CharacterBody2D) -> void:
        # 根據玩家的面向方向調整跳躍方向和動畫
        jump_velocity.x = abs(jump_velocity.x) * player.facing_direction.x
        
        # 根據面向方向選擇正確的動畫
        if player.facing_direction.x > 0:
            name = "Jump_Right"
        else:
            name = "Jump_Left"
        
        super.start(player)
    
