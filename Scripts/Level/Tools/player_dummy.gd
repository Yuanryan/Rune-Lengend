@tool
extends Node2D

enum RabbitJumpType {
    NORMAL_JUMP,
    SUPER_JUMP
}

@export_tool_button("Toggle_Jump_Path", "Line2D") var toggle_jump_path_action = toggle_jump_path
@export var show_sprite: bool = true : set = _set_show_sprite
@export var time_step: float = 0.02
@export var max_draw_duration: float = 1
@export_category("Animal")
@export var animal_type : Animal.AnimalType = Animal.AnimalType.MAN : set = _set_animal_type

@onready var line_2d: Line2D = %Line2D
@onready var sprite_2d: Sprite2D = %Sprite
var animal_data: AnimalResource = null
var rabbit_jump_type: RabbitJumpType = RabbitJumpType.NORMAL_JUMP : 
    set(value): rabbit_jump_type = value; draw_jump_path()

func _ready() -> void:
    if Engine.is_editor_hint():
        draw_jump_path()
    else:
        push_warning("PlayerDummy in scene, remember to remove it.")
        queue_free()

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    
    # 只有當選擇兔子時才顯示 rabbit_jump_type 屬性
    if animal_type == Animal.AnimalType.RABBIT:
        properties.append({
            "name": "rabbit_jump_type",
            "type": TYPE_INT,
            "usage": PROPERTY_USAGE_DEFAULT,
            "hint": PROPERTY_HINT_ENUM,
            "hint_string": "NORMAL_JUMP,SUPER_JUMP"
        })
    
    return properties

func _get(property: StringName):
    if property == "rabbit_jump_type":
        return rabbit_jump_type
    return null

func _set(property: StringName, value) -> bool:
    if property == "rabbit_jump_type":
        rabbit_jump_type = value
        if Engine.is_editor_hint():
            draw_jump_path()
        return true
    return false


func _set_animal_type(value: Animal.AnimalType) -> void:
    if Engine.is_editor_hint():
        animal_type = value
        animal_data = Animal.get_animal_data(animal_type)
        # 通知編輯器更新屬性列表（因為 rabbit_jump_type 的顯示取決於 animal_type）
        notify_property_list_changed()
        draw_jump_path()

func _set_show_sprite(value: bool) -> void:
    if Engine.is_editor_hint(): 
        show_sprite = value
        sprite_2d.visible = value

func toggle_jump_path() -> void:
    line_2d.visible = not line_2d.visible

func draw_jump_path() -> void:
    if not animal_data:
        return
    
    # 根據動物類型和跳躍類型選擇跳躍速度
    var jump_velocity: Vector2 = animal_data.jump_velocity
    
    # 如果是兔子且選擇超級跳躍，使用超級跳躍速度
    if animal_type == Animal.AnimalType.RABBIT and rabbit_jump_type == RabbitJumpType.SUPER_JUMP:
        jump_velocity = Vector2(150, -650)
    
    
    var array_points: PackedVector2Array = PackedVector2Array()
    array_points.clear()
    
    # 初始化速度和重力
    var velocity: Vector2 = jump_velocity
    var gravity_force: float = ProjectSettings.get_setting("physics/2d/default_gravity")
    var gravity_vec: Vector2 = Vector2(0, gravity_force)
    
    # 從原點開始計算軌跡
    var traj_position: Vector2 = Vector2.ZERO
    
    array_points.append(traj_position)
    
    var elapsed_time: float = 0.0
    # 模擬軌跡直到落地或超過最大時間
    while traj_position.y <= 0 and elapsed_time < max_draw_duration:
        elapsed_time += time_step
        velocity += gravity_vec * time_step
        traj_position += velocity * time_step
        array_points.append(traj_position)
    
    line_2d.set_points(array_points)
    line_2d.visible = true
