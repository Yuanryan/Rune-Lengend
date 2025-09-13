@tool
extends StaticBody2D
class_name LandTool

@export_tool_button("Generate Collision", "CollisionPolygon2D") var generate_collision_action = generate_collision_shape
var polygon_2d: Polygon2D = null
var collision_polygon_2d: CollisionPolygon2D = null

func _ready():
    if Engine.is_editor_hint():
        get_parent().set_editable_instance(self, true) 

func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    
    # 檢查是否有 Polygon2D 子節點
    if not _find_polygon2d():
        warnings.append("LandTool 需要一個 Polygon2D 子節點來生成碰撞形狀")
    
    return warnings

func _find_polygon2d() -> Polygon2D:
    # 尋找第一個 Polygon2D 子節點
    for child in get_children():
        if child is Polygon2D:
            set_editable_instance(child, true)
            return child
    return null

func _setup_collision() -> void:
    # 清除現有的 CollisionPolygon2D 節點
    if collision_polygon_2d and is_instance_valid(collision_polygon_2d):
        collision_polygon_2d.queue_free()
    
    # 創建 CollisionPolygon2D
    collision_polygon_2d = CollisionPolygon2D.new()
    collision_polygon_2d.name = "CollisionPolygon2D"
    add_child(collision_polygon_2d)
    collision_polygon_2d.owner = get_tree().edited_scene_root


func generate_collision_shape() -> void:
    if not Engine.is_editor_hint():
        return
    
    polygon_2d = _find_polygon2d()
    if not polygon_2d:
        push_error("找不到 Polygon2D 子節點")
        return
    
    _setup_collision()
    
    var points = polygon_2d.polygon
    if points.size() < 3:
        push_error("Polygon2D 需要至少 3 個點來生成碰撞形狀")
        return
    
    # 設置 CollisionPolygon2D 的位置和點
    collision_polygon_2d.position = polygon_2d.position
    collision_polygon_2d.polygon = points
    
    print("已為 ", polygon_2d.name, " 生成碰撞形狀，包含 ", points.size(), " 個點")



