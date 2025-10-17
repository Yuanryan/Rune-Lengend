@icon("res://Assets/icons/flag-checkered-solid-full.svg")
extends Area2D
class_name EndingPoint

# 終點信號
signal ending_point_reached(ending_point: EndingPoint)

func _ready() -> void:

    add_to_group("ending_points")
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is Player:
        print("到達終點！")
        ending_point_reached.emit(self)
        # 設置遊戲狀態為勝利
        GameManager.achieve_victory()
