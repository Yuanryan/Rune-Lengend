# Animals/Rabbit.gd
extends Animal
class_name Rabbit


func _init():
    var rabbit_data = load("uid://vk62uradafkf") as AnimalResource
    super._init(rabbit_data)

# 兔子的彈跳切換動作
class RabbitSwitchAction extends ConditionalAction:
    var bounce_height: float = 50.0
    var original_y: float
    var _has_left_ground: bool = false

    func _init():
        name = "Rabbit_Switch"
    
    func start(player: CharacterBody2D):
        original_y = player.position.y
    
    func update(player: CharacterBody2D, delta: float) -> bool:
        # 彈跳效果
        var progress = 1.0 - (delta / 1.0)
        var bounce_offset = sin(progress * PI) * bounce_height
        player.position.y = original_y - bounce_offset
        
        return super.update(player, delta)

    func should_stop(player: CharacterBody2D, delta: float) -> bool:
        # 檢查是否已經離開地面
        if not _has_left_ground and not player.is_on_floor():
            _has_left_ground = true
        
        # 只有在離開地面後再次觸地才結束動作
        return _has_left_ground and player.is_on_floor()

    func interrupt(player: CharacterBody2D) -> void:
        player.velocity = Vector2.ZERO