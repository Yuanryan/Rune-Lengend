# Animals/Wolf.gd
extends Animal
class_name Wolf

func _init():
    var wolf_data = load("uid://dhl4h4f80cuu3") as AnimalResource
    super._init(wolf_data)
    switch_action = WolfSwitchAction.new()
    
func get_animal_type() -> Animal.AnimalType:
    return Animal.AnimalType.WOLF

# 狼的衝刺切換動作
class WolfSwitchAction extends TimedAction:
    var dash_speed: float = 500.0
    var dash_direction: Vector2 = Vector2.RIGHT
    var dash_velocity: Vector2 = Vector2.ZERO

    func _init():
        duration = 0.3  # 短時間衝刺
        name = "Wolf_Dash"
    
    func start(player: CharacterBody2D):
        super.start(player)
        # 根據玩家面向方向決定衝刺方向
        dash_direction = player.facing_direction
        dash_velocity = dash_direction * dash_speed 
        player.velocity = Vector2(dash_velocity.x, 0.0)

    func update(player: CharacterBody2D, delta: float) -> bool:
        # 衝刺效果
        player.velocity.x = dash_velocity.x
        return super.update(player, delta)

     # 中斷時停止移動
    func interrupt(player: CharacterBody2D) -> void:
        # 只停止 x 軸速度（衝刺），保持 y 軸速度不變，讓重力繼續作用
        player.velocity.x = 0