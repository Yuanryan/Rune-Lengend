extends PhantomCamera2D
class_name PlayerCamera

func set_border(border: CollisionShape2D) -> void:
    """設置玩家相機的邊界"""
    set_limit_target(border.get_path())
