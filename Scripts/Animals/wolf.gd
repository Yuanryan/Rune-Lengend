# Animals/Wolf.gd
extends Animal
class_name Wolf

func _init():
    var wolf_data = load("uid://dhl4h4f80cuu3") as AnimalResource
    super._init(wolf_data)

# 狼的旋轉切換動作
class WolfSwitchAction extends TimedAction:
    var rotation_speed: float = 360.0
    
    func _init():
        duration = 0.8
        name = "Wolf_Switch"
    
    func start(player: CharacterBody2D):
        super.start(player)
        player.modulate.a = 0.0
    
    func update(player: CharacterBody2D, delta: float) -> bool:
        # 旋轉效果
        player.rotation_degrees += rotation_speed * delta
        
        # 淡入效果
        var progress = 1.0 - (_time_left / duration)
        player.modulate.a = progress
        
        return super.update(player, delta)