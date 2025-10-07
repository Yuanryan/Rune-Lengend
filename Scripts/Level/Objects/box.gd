@tool
extends RigidBody2D
class_name Box


@export_custom(PROPERTY_HINT_LINK, "") var size_scale : Vector2 = Vector2(1.0, 1.0) : set = set_size_scale
@onready var standing_area = %StandingArea
@onready var push_area = %PushArea
@onready var polygon = %Polygon2D
@onready var collision_polygon = %CollisionPolygon2D

var player_ref : Player = null
var is_pushing: bool = false

func _ready():
    set_size_scale(size_scale)
    disable_push()
    # 加入 Interactive 群組，讓按鈕能偵測到
    add_to_group("Interactive")
    # 連接 Area2D 的信號
    standing_area.body_entered.connect(_on_standing_area_body_entered)
    standing_area.body_exited.connect(_on_standing_area_body_exited)
    push_area.body_entered.connect(_on_push_area_body_entered)
    push_area.body_exited.connect(_on_push_area_body_exited)

func _on_standing_area_body_entered(body: Player):
    disable_push() 

func _on_standing_area_body_exited(body: Player):
    enable_push()

func _on_push_area_body_entered(body: Player):
    if body == GameManager.player and (body.animal_component.current_animal.get_animal_type() == Animal.AnimalType.MAN or body.velocity.length() >= 500):
        enable_push()
    else:
        disable_push()

func _on_push_area_body_exited(body):
    enable_push()


func enable_push() -> void:
    set_collision_layer_value(1, false)
    set_collision_layer_value(8, true)


func disable_push() -> void:
    set_collision_layer_value(8, false) 
    set_collision_layer_value(1, true) 

func _physics_process(delta):
    pass


func _on_box_pushed():
    # 在這裡可以添加推動箱子時的效果
    # 例如：音效、粒子效果等
    pass

func set_size_scale(value: Vector2) -> void:
    if not is_node_ready():
        await ready
    size_scale = value
    standing_area.scale = value
    polygon.scale = value
    collision_polygon.scale = value
    push_area.scale = value
