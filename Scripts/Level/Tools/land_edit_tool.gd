# LandEditTool.gd
# 地圖編輯工具，自動檢查所有 LandTool 並批量生成碰撞

@tool
extends Node
class_name LandEditTool

var land_tools: Array[LandTool] = []

# 工具按鈕 - 生成所有碰撞
@export_tool_button("Generate All Collisions", "CollisionPolygon2D") var generate_all_action = generate_all_collisions
@export_tool_button("Clear All Collisions", "CollisionPolygon2D") var clear_all_action = clear_all_collisions
@export var hide_all_polygons_in_game: bool = false

func _ready() -> void:
    if not Engine.is_editor_hint():
        land_tools = _find_all_land_tools()
        if hide_all_polygons_in_game:
            for land_tool in land_tools:
                land_tool.hide_polygon_in_game = true

func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    
    # 檢查場景中是否有 LandTool
    land_tools = _find_all_land_tools()
    if land_tools.is_empty():
        warnings.append("場景中沒有找到 LandTool 節點")    
    return warnings

func clear_all_collisions() -> void:
    if not Engine.is_editor_hint():
        return
    
    for land_tool in land_tools:
        if land_tool.collision_polygon_2d:
            land_tool.collision_polygon_2d.queue_free()

func _find_all_land_tools() -> Array[LandTool]:
    # 使用群組尋找場景中所有的 LandTool 節點
    land_tools.clear()
    var land_nodes = get_tree().get_nodes_in_group("Land")
    for node in land_nodes:
        if node is LandTool:
            land_tools.append(node)
    return land_tools

func generate_all_collisions() -> void:
    if not Engine.is_editor_hint():
        return
    
    land_tools = _find_all_land_tools()
    if land_tools.is_empty():
        push_error("沒有找到 LandTool 節點")
        return
    
    var success_count = 0
    var error_count = 0
    
    clear_all_collisions()
    for land_tool in land_tools:
        if is_instance_valid(land_tool):
            # 調用每個 LandTool 的生成方法
            land_tool.generate_collision_shape()
            success_count += 1
        else:
            error_count += 1
    
    print("批量生成完成：成功 ", success_count, " 個，失敗 ", error_count, " 個")

