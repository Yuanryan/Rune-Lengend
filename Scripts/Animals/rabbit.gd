# Animals/Rabbit.gd
extends Animal
class_name Rabbit


func _init():
    var rabbit_data = load("uid://vk62uradafkf") as AnimalResource
    super._init(rabbit_data)
        
    # 創建兔子的彈跳切換動作
    switch_action = RabbitSwitchAction.new()

# 兔子的彈跳切換動作
class RabbitSwitchAction extends TimedAction:
    var bounce_height: float = 50.0
    var original_y: float
    
    func _init():
        duration = 1.0
        name = "Rabbit_Switch"
    
    func start(player: CharacterBody2D):
        super.start(player)
        original_y = player.position.y
    
    func update(player: CharacterBody2D, delta: float) -> bool:
        # 彈跳效果
        var progress = 1.0 - (_time_left / duration)
        var bounce_offset = sin(progress * PI) * bounce_height
        player.position.y = original_y - bounce_offset
        
        return super.update(player, delta)
