@tool
extends StaticBody2D
class_name LandTool

@export_tool_button("Generate Collision", "CollisionPolygon2D") var generate_collision_action = generate_collision_shape
@export_tool_button("Remove Collision", "CollisionPolygon2D") var remove_collision_action = remove_collision_shape
@export var show_polygon_in_game: bool = false
var polygon_2d: Polygon2D = null
var collision_polygon_2d: CollisionPolygon2D = null

func _ready():
	# 加入 land 群組
	add_to_group("land")
	
	if Engine.is_editor_hint():
		get_parent().set_editable_instance(self, true) 
		collision_polygon_2d = _find_collision()
	if not show_polygon_in_game and not Engine.is_editor_hint():
		hide_polygon()

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

func _find_collision() -> CollisionPolygon2D:
	# 尋找第一個 Polygon2D 子節點
	for child in get_children():
		if child is CollisionPolygon2D:
			return child
	return null

func _setup_collision() -> void:
	# 清除現有的 CollisionPolygon2D 節點
	if not collision_polygon_2d:
		collision_polygon_2d = _find_collision()
	
	if collision_polygon_2d and is_instance_valid(collision_polygon_2d):
		collision_polygon_2d.queue_free()

	# 創建 CollisionPolygon2D
	collision_polygon_2d = CollisionPolygon2D.new()
	collision_polygon_2d.name = "CollisionPolygon2D"
	add_child(collision_polygon_2d)
	collision_polygon_2d.owner = get_tree().edited_scene_root


func hide_polygon() -> void:
	polygon_2d = _find_polygon2d()
	if polygon_2d:
		polygon_2d.visible = false

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
	
	# 設置 CollisionPolygon2D 的位置、旋轉、縮放和點
	collision_polygon_2d.position = polygon_2d.position
	collision_polygon_2d.rotation = polygon_2d.rotation
	collision_polygon_2d.scale = polygon_2d.scale
	collision_polygon_2d.polygon = points
	
func remove_collision_shape() -> void:
	if not Engine.is_editor_hint():
		return
	
	if collision_polygon_2d and is_instance_valid(collision_polygon_2d):
		collision_polygon_2d.queue_free()
		collision_polygon_2d = null
	else:
		print("沒有找到可移除的碰撞形狀")
