# TestingRoom.gd
# 測試房間腳本，用於直接測試關卡
extends Node2D

# 測試關卡相關
@export var testing_level: Level = null


@onready var player: Player = %Player

# UI 相關
@onready var phantom_camera: PhantomCamera2D = %PhantomCamera2D
@onready var in_game_ui: CanvasLayer = %InGameUI
@onready var testing_ui: CanvasLayer = %TestingUI
@onready var level_name_label: Label = %LevelName
@onready var reset_button: Button = %ResetButton
@onready var checkpoint_button: Button = %CheckpointButton
@onready var mouse_movement_button: Button = %MouseMovementButton
@onready var camera_visibility_button: Button = %CameraVisibilityButton
@onready var editor_mode_button: Button = %EditorModeButton
@onready var save_changes_button: Button = %SaveChangesButton

# 測試狀態
var is_testing_mode: bool = false

# 編輯器模式
var is_editor_mode: bool = false
var editable_objects: Array[Node2D] = []
var selected_object: Node2D = null
var is_dragging_object: bool = false
var object_drag_start_position: Vector2
var object_start_position: Vector2

# 滑鼠移動相關
var mouse_movement_enabled: bool = false
var is_dragging_player: bool = false
var drag_start_position: Vector2
var player_start_position: Vector2

# 信號
signal level_changed(level: Level)
signal testing_started()
signal testing_stopped()

func _ready() -> void:
    # 連接UI信號
    _connect_ui_signals()
    
    # 連接遊戲狀態變化信號
    _connect_game_manager_signals()
    
    # 設置測試模式
    _setup_testing_mode()
    
    # 更新UI顯示
    _update_ui_display()
    
    # 啟用滑鼠移動模式
    mouse_movement_enabled = true
    _update_mouse_movement_button_text()
    
    # 更新相機可見性按鈕文字
    _update_camera_visibility_button_text()
    
    # 初始化編輯器模式
    _initialize_editor_mode()

func _setup_testing_mode() -> void:
    """設置測試模式"""
    is_testing_mode = true
    
    # 設置LevelManager的關卡場景（用於重置功能）
    _setup_level_manager_for_testing()
    
    # 設置UIManager的UI引用（測試房間專用）
    _setup_ui_manager_for_testing()
    
    # 設置遊戲狀態為遊戲中
    GameManager.set_game_state(GameManager.GameState.GAME_PLAY)
    
    # 設置玩家引用到 GameManager
    if player:
        GameManager.set_player(player)
        # 設置玩家位置到關卡起始點
        if testing_level and testing_level.starting_point:
            player.global_position = testing_level.starting_point.global_position
        # 設置可用動物
        if testing_level:
            player.set_available_animals(testing_level.available_animals)
        
        # 重寫玩家的輸入處理（R鍵觸發從檢查點重新載入）
        _override_player_input()
    
    # 通知 UI Manager 創建卡片
    if testing_level:
        UIManager.create_cards_from_level(testing_level)
    
    testing_started.emit()

func _setup_level_manager_for_testing() -> void:
    """為測試房間設置LevelManager的關卡場景"""
    if testing_level:
        # 獲取關卡場景的PackedScene
        var level_scene = testing_level.scene_file_path
        if level_scene:
            var packed_scene = load(level_scene)
            if packed_scene:
                # 設置LevelManager的當前關卡場景
                LevelManager.current_level_scene = packed_scene
                LevelManager.current_level = testing_level
                print("LevelManager已設置關卡場景: ", level_scene)
            else:
                print("無法載入關卡場景: ", level_scene)
        else:
            print("關卡沒有場景文件路徑")

func _setup_ui_manager_for_testing() -> void:
    """為測試房間設置UIManager的UI引用"""
    if in_game_ui:
        # 設置遊戲內UI引用
        UIManager.set_ui_references(null, null, in_game_ui, null)
        # 初始化UI狀態
        UIManager.initialize_ui()
        # 顯示遊戲UI
        UIManager.show_game_ui()
        
        # 隱藏測試房間中不需要的按鈕
        _hide_testing_ui_buttons()
        
        print("測試房間UI已設置")
    else:
        print("警告：測試房間中找不到InGameUI")

func _hide_testing_ui_buttons() -> void:
    """隱藏測試房間中不需要的UI按鈕"""
    if in_game_ui:
        # 隱藏重置玩家按鈕
        if in_game_ui.has_node("%ResetButton"):
            var reset_btn = in_game_ui.get_node("%ResetButton")
            if reset_btn:
                reset_btn.visible = false
                print("已隱藏遊戲內UI的重置按鈕")
        
        # 隱藏返回主選單按鈕
        if in_game_ui.has_node("%MenuButton"):
            var menu_btn = in_game_ui.get_node("%MenuButton")
            if menu_btn:
                menu_btn.visible = false
                print("已隱藏遊戲內UI的選單按鈕")

func _connect_ui_signals() -> void:
    """連接UI按鈕信號"""
    if reset_button:
        reset_button.pressed.connect(_on_reset_level)
    if checkpoint_button:
        checkpoint_button.pressed.connect(_on_reload_from_checkpoint)
    if mouse_movement_button:
        mouse_movement_button.pressed.connect(_on_toggle_mouse_movement)
    if camera_visibility_button:
        camera_visibility_button.pressed.connect(_on_toggle_camera_visibility)
    if editor_mode_button:
        editor_mode_button.pressed.connect(_on_toggle_editor_mode)
    if save_changes_button:
        save_changes_button.pressed.connect(_on_save_changes)

func _connect_game_manager_signals() -> void:
    """連接GameManager的狀態變化信號"""
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _update_ui_display() -> void:
    """更新UI顯示"""
    if level_name_label and testing_level:
        level_name_label.text = testing_level.level_name
    elif level_name_label:
        level_name_label.text = "無關卡載入"

func _on_in_game_state_changed(new_state: GameManager.InGameState) -> void:
    """處理遊戲內狀態變化"""
   # 在測試關卡中，當狀態不是執行中且不是暫停時，確保解鎖動作佇列
    if new_state != GameManager.InGameState.EXECUTING:
        GameManager.set_in_game_state(GameManager.InGameState.PLANNING)
    
    print("測試關卡狀態變化: ", GameManager._get_state_name(new_state))



func _input(event: InputEvent) -> void:
    """處理輸入事件"""
    # 處理鍵盤快捷鍵（優先處理）
    if event is InputEventKey and event.pressed:
        _handle_keyboard_shortcuts(event)
    
    # 處理編輯器模式輸入
    if is_editor_mode:
        _handle_editor_input(event)
        return
    
    # 處理滑鼠移動相關輸入
    if mouse_movement_enabled and player:
        if event is InputEventMouseButton:
            _handle_mouse_button_input(event)
        elif event is InputEventMouseMotion:
            _handle_mouse_motion_input(event)
    
    # 處理玩家鍵盤輸入（重寫版本）
    if player and player.get_meta("input_overridden", false):
        _handle_player_keyboard_input(event)

func _handle_player_keyboard_input(event: InputEvent) -> void:
    """處理玩家鍵盤輸入（重寫版本，R鍵觸發從檢查點重新載入）"""
    if event is InputEventKey and event.pressed:
        if event.is_action_pressed("ui_accept"):
            # 處理空格鍵（執行動作）
            if GameManager.current_in_game_state == GameManager.InGameState.EXECUTING:
                player.interrupt_current_action()
            elif GameManager.current_in_game_state == GameManager.InGameState.PLANNING:
                UIManager.get_in_game_ui().execute_sequence()
        elif event.is_action_pressed("reset_player"):
            # R鍵觸發從檢查點重新載入功能
            _on_reload_from_checkpoint()
            print("R鍵觸發從檢查點重新載入")

func _handle_keyboard_shortcuts(event: InputEventKey) -> void:
    """處理鍵盤快捷鍵"""
    # Q鍵 - 切換滑鼠移動模式
    if event.keycode == KEY_Q:
        _on_toggle_mouse_movement()
        print("Q鍵觸發滑鼠移動切換")
    
    # W鍵 - 切換相機跟隨
    elif event.keycode == KEY_W:
        _on_toggle_camera_visibility()
        print("W鍵觸發相機跟隨切換")
    
    # E鍵 - 切換編輯器模式
    elif event.keycode == KEY_E:
        _on_toggle_editor_mode()
        print("E鍵觸發編輯器模式切換")

func _handle_mouse_button_input(event: InputEventMouseButton) -> void:
    """處理滑鼠按鈕輸入"""
    if event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # 開始拖拽
            _start_player_drag(event.global_position)
        else:
            # 結束拖拽
            _end_player_drag()
    elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        # 右鍵點擊移動到位置
        _move_player_to_position(get_global_mouse_position())

func _handle_mouse_motion_input(event: InputEventMouseMotion) -> void:
    """處理滑鼠移動輸入"""
    if is_dragging_player:
        _update_player_drag(event.global_position)

func _start_player_drag(mouse_position: Vector2) -> void:
    """開始拖拽玩家（使用相機空間座標）"""
    if not player:
        return
    
    # 直接開始拖拽，不檢查是否點擊在玩家上
    is_dragging_player = true
    
    # 使用相機空間座標
    var mouse_pos = get_viewport().get_mouse_position()
    drag_start_position = mouse_pos
    player_start_position = player.global_position
    
    # 停止玩家速度（包括重力效果）
    player.velocity = Vector2.ZERO
    
    print("開始拖拽玩家 - 起始位置: ", player_start_position, " 滑鼠位置: ", mouse_pos)
    

func _update_player_drag(mouse_position: Vector2) -> void:
    """更新玩家拖拽位置（使用相機空間座標）"""
    if not is_dragging_player or not player:
        return
    
    # 獲取當前滑鼠位置（相機空間）
    var current_mouse_pos = get_viewport().get_mouse_position()
    
    # 計算拖拽偏移量（相機空間）
    var drag_offset = current_mouse_pos - drag_start_position
    
    # 考慮相機縮放
    var camera_zoom = Vector2.ONE
    if phantom_camera:
        camera_zoom = phantom_camera.zoom
    
    # 根據相機縮放調整拖拽靈敏度
    drag_offset = drag_offset / camera_zoom
    

    # 應用相對位置拖拽
    player.global_position = player_start_position + drag_offset
    
    # 持續重置速度以防止重力影響
    player.velocity = Vector2.ZERO
    
func _end_player_drag() -> void:
    """結束玩家拖拽"""
    if is_dragging_player:
        is_dragging_player = false

func _move_player_to_position(target_position: Vector2) -> void:
    """移動玩家到指定位置"""
    if not player:
        return
    
    player.global_position = target_position
    


# ========== 關卡管理 ==========

func _on_reset_level() -> void:
    """重置關卡到初始狀態 - 重新載入關卡場景"""
    if not testing_level:
        print("無法重置關卡：缺少關卡")
        return
    
    print("開始重新載入關卡場景...")
    
    # 重新載入關卡場景
    _reload_level_scene()
    reset_button.release_focus()

func _reload_level_scene() -> void:
    """重新載入關卡場景"""
    if not testing_level:
        print("無法重新載入關卡：缺少關卡引用")
        return
    
    # 獲取關卡場景路徑
    var level_scene_path = testing_level.scene_file_path
    if not level_scene_path:
        print("無法獲取關卡場景路徑")
        return
    
    print("重新載入關卡場景: ", level_scene_path)
    
    # 載入新的關卡場景
    var packed_scene = load(level_scene_path)
    if not packed_scene:
        print("無法載入關卡場景: ", level_scene_path)
        return
    
    # 實例化新的關卡場景
    var new_level_scene = packed_scene.instantiate()
    if not new_level_scene:
        print("無法實例化關卡場景")
        return
    
    # 移除舊的關卡場景
    if testing_level and is_instance_valid(testing_level):
        testing_level.queue_free()
    
    # 添加新的關卡場景到場景樹
    add_child(new_level_scene)
    
    # 移動關卡到索引1的位置
    move_child(new_level_scene, 1)
    
    # 更新關卡引用
    testing_level = new_level_scene
    
    # 重新設置測試房間
    _setup_testing_mode()
    
    print("關卡場景已重新載入")

func _reset_player_state() -> void:
    """重置玩家狀態"""
    if not player:
        return
    
    # 停止所有動作
    player.action_queue.clear()
    if player._current_action != null:
        player._current_action.interrupt(player)
        player._current_action = null
    player.is_executing_actions = false
    
    # 重置速度
    player.velocity = Vector2.ZERO
    
    # 設置玩家位置到關卡起始點
    if testing_level.starting_point:
        player.global_position = testing_level.starting_point.global_position
    
    # 設置可用動物
    if testing_level:
        player.set_available_animals(testing_level.available_animals)
    
    # 重置玩家狀態
    player._set_player_state(player.PlayerState.IDLE)
    player.facing_direction = Vector2.RIGHT
    
    print("玩家狀態已重置")

func _reset_level_objects() -> void:
    """重置關卡中的所有對象狀態"""
    if not testing_level:
        return
    
    # 重置所有門
    for door in get_tree().get_nodes_in_group("TimedDoor"):
        if door.has_method("reset_door"):
            door.reset_door()
    
    # 重置所有按鈕
    for button in get_tree().get_nodes_in_group("Button"):
        if button.has_method("reset_button"):
            button.reset_button()
    
    # 重置所有箱子
    for box in get_tree().get_nodes_in_group("Box"):
        if box.has_method("reset_box"):
            box.reset_box()
    
    print("關卡對象已重置")

func _reset_checkpoints() -> void:
    """重置檢查點狀態"""
    if not testing_level:
        return
    
    # 重置檢查點索引
    testing_level.current_checkpoint_index = -1
    
    # 重置所有檢查點
    for checkpoint in testing_level.checkpoints:
        if checkpoint.has_method("reset_checkpoint"):
            checkpoint.reset_checkpoint()
    
    print("檢查點已重置")

func _reset_camera_state() -> void:
    """重置相機狀態"""
    if not testing_level:
        return
    
    # 重置到起始相機
    if testing_level.has_method("_activate_starting_camera"):
        testing_level._activate_starting_camera()
    
    print("相機狀態已重置")

func _reset_ui_state() -> void:
    """重置UI狀態"""
    var game_ui = UIManager.get_in_game_ui()
    if game_ui:
        # 清除動作佇列
        if game_ui.action_queue:
            game_ui.action_queue.clear_queue()
            game_ui.action_queue.unlock_queue()
            game_ui.action_queue.clear_executing_action()
        
        # 重置卡片使用次數
        if game_ui.card_deck:
            game_ui.card_deck.reset_action_usage()
    
    print("UI狀態已重置")

func _reset_game_state() -> void:
    """重置遊戲狀態"""
    # 重置到規劃階段
    GameManager.reset_to_planning()
    
    print("遊戲狀態已重置")

func _on_reload_from_checkpoint() -> void:
    """從檢查點重新載入關卡"""
    if testing_level and player:
        # 獲取最後檢查點位置
        var spawn_position = Vector2.ZERO
        if testing_level.current_checkpoint_index >= 0:
            var checkpoint = testing_level.get_checkpoint_by_index(testing_level.current_checkpoint_index)
            if checkpoint:
                spawn_position = checkpoint.global_position
        
        # 設置玩家到檢查點位置
        if spawn_position != Vector2.ZERO:
            player.global_position = spawn_position
            print("玩家已移動到檢查點")
        else:
            print("沒有檢查點，重置到起始點")
            _on_reset_level()
            return  # 如果調用了重置關卡，就不需要執行下面的代碼
    
    # 設置遊戲狀態為規劃階段
    GameManager.reset_to_planning()
    
    # 重新初始化編輯器模式（更新可編輯物件列表）
    _initialize_editor_mode()
    
    # 讓按鈕失去焦點
    if checkpoint_button:
        checkpoint_button.release_focus()

# ========== 玩家管理 ==========

func _on_toggle_mouse_movement() -> void:
    """切換滑鼠移動模式"""
    toggle_mouse_movement()
    _update_mouse_movement_button_text()
    
    # 讓按鈕失去焦點
    if mouse_movement_button:
        mouse_movement_button.release_focus()

func _update_mouse_movement_button_text() -> void:
    """更新滑鼠移動按鈕文字"""
    if mouse_movement_button:
        if mouse_movement_enabled:
            mouse_movement_button.text = "停用滑鼠移動 (Q)"
        else:
            mouse_movement_button.text = "啟用滑鼠移動 (Q)"

func _on_toggle_camera_visibility() -> void:
    """切換相機可見性"""
    toggle_camera_visibility()
    _update_camera_visibility_button_text()
    
    # 讓按鈕失去焦點
    if camera_visibility_button:
        camera_visibility_button.release_focus()

func _update_camera_visibility_button_text() -> void:
    """更新相機可見性按鈕文字"""
    if camera_visibility_button:
        var cameras_visible = _are_cameras_visible()
        if cameras_visible:
            camera_visibility_button.text = "停用相機跟隨 (W)"
        else:
            camera_visibility_button.text = "啟用相機跟隨 (W)"

# ========== 公共方法 ==========

func get_current_level() -> Level:
    """獲取當前測試關卡"""
    return testing_level

func get_current_player() -> Player:
    """獲取當前測試玩家"""
    return player

func is_in_testing_mode() -> bool:
    """檢查是否在測試模式"""
    return is_testing_mode

func stop_testing() -> void:
    """停止測試模式"""
    is_testing_mode = false
    
    # 清除 GameManager 中的玩家引用
    GameManager.remove_player()
    
    # 設置遊戲狀態回到主選單
    GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
    
    testing_stopped.emit()
    print("測試模式已停止")

# ========== 滑鼠移動控制 ==========

func enable_mouse_movement() -> void:
    """啟用滑鼠移動功能"""
    mouse_movement_enabled = true
    print("滑鼠移動已啟用")

func disable_mouse_movement() -> void:
    """停用滑鼠移動功能"""
    mouse_movement_enabled = false
    is_dragging_player = false
    print("滑鼠移動已停用")

func toggle_mouse_movement() -> void:
    """切換滑鼠移動功能"""
    if mouse_movement_enabled:
        disable_mouse_movement()
    else:
        enable_mouse_movement()

func is_mouse_movement_enabled() -> bool:
    """檢查滑鼠移動是否啟用"""
    return mouse_movement_enabled

# ========== 相機可見性控制 ==========

func toggle_camera_visibility() -> void:
    """切換所有PhantomCamera的可見性"""
    
    var current_visibility = phantom_camera.visible
    phantom_camera.priority = 1000
    var new_visibility = not current_visibility
    
    phantom_camera.visible = new_visibility
    

func _are_cameras_visible() -> bool:
    """檢查相機是否可見"""
    return phantom_camera.visible

func _update_phantom_camera_target() -> void:
    """更新PhantomCamera的跟隨目標"""
    if not player:
        print("無法更新相機目標：沒有玩家")
        return
    
    # 找到測試房間中的PhantomCamera2D
    var camera = get_node("PhantomCamera2D")
    if camera and camera.has_method("set_follow_target"):
        camera.set_follow_target(player)
        print("PhantomCamera跟隨目標已更新為新玩家")
    else:
        print("找不到PhantomCamera2D或沒有set_follow_target方法")

func _update_debug_button_states() -> void:
    """更新所有調試按鈕的狀態"""
    # 更新滑鼠移動按鈕文字
    _update_mouse_movement_button_text()
    
    # 更新相機可見性按鈕文字
    _update_camera_visibility_button_text()
    
    print("調試按鈕狀態已更新")

func _override_player_input() -> void:
    """重寫玩家輸入處理，R鍵觸發從檢查點重新載入"""
    if not player:
        return
    
    # 禁用玩家的原始輸入處理
    player.set_process_input(false)
    
    # 設置meta標記表示輸入已被重寫
    player.set_meta("input_overridden", true)
    
    print("玩家輸入已重寫（R鍵觸發從檢查點重新載入）")

# ========== 編輯器模式 ==========

func _initialize_editor_mode() -> void:
    """初始化編輯器模式"""
    _find_editable_objects()
    _update_editor_mode_button_text()
    print("編輯器模式已初始化")

func _find_editable_objects() -> void:
    """尋找所有可編輯的物件"""
    editable_objects.clear()
    
    if not testing_level:
        print("警告：沒有測試關卡，無法尋找可編輯物件")
        return
    
    # 首先尋找最重要的 Land 物件
    var land_objects = get_tree().get_nodes_in_group("Land")
    print("找到 Land 群組中的物件數量: ", land_objects.size())
    for obj in land_objects:
        if obj is Node2D:
            editable_objects.append(obj)
            print("  - 添加 Land 物件: ", obj.name, " 位置: ", obj.global_position)
    
    # 然後尋找其他可編輯的物件類型
    var other_object_types = [
        "Box", "Button", "Checkpoint", "EndingPoint", 
        "TimedDoor", "Spike", "Turret", "DamageArea",
        "Interactive"
    ]
    
    for object_type in other_object_types:
        var objects = get_tree().get_nodes_in_group(object_type)
        print("找到 ", object_type, " 群組中的物件數量: ", objects.size())
        for obj in objects:
            if obj is Node2D and obj not in editable_objects:  # 避免重複添加
                editable_objects.append(obj)
                print("  - 添加可編輯物件: ", obj.name, " 位置: ", obj.global_position)
    
    # 如果沒有找到群組物件，嘗試直接從關卡中尋找
    if editable_objects.is_empty():
        print("沒有找到群組物件，嘗試直接搜尋...")
        _find_objects_directly()
    
    print("總共找到 ", editable_objects.size(), " 個可編輯物件")

func _find_objects_directly() -> void:
    """直接從關卡中尋找物件"""
    if not testing_level:
        return
    
    # 遞歸搜尋所有子節點
    _search_node_recursive(testing_level)

func _search_node_recursive(node: Node) -> void:
    """遞歸搜尋節點"""
    # 檢查節點是否為可編輯類型
    var node_name = node.name.to_lower()
    
    # 優先檢查 Land 物件
    if node_name.contains("land"):
        if node is Node2D and node not in editable_objects:
            editable_objects.append(node)
            print("  - 直接找到 Land 物件: ", node.name, " 位置: ", node.global_position)
    
    # 檢查其他可編輯類型
    elif (node_name.contains("box") or node_name.contains("button") or 
          node_name.contains("checkpoint") or node_name.contains("ending") or
          node_name.contains("door") or node_name.contains("spike") or
          node_name.contains("turret") or node_name.contains("damage")):
        
        if node is Node2D and node not in editable_objects:
            editable_objects.append(node)
            print("  - 直接找到可編輯物件: ", node.name, " 位置: ", node.global_position)
    
    # 遞歸搜尋子節點
    for child in node.get_children():
        _search_node_recursive(child)

func _handle_editor_input(event: InputEvent) -> void:
    """處理編輯器模式輸入"""
    if event is InputEventMouseButton:
        _handle_editor_mouse_button_input(event)
    elif event is InputEventMouseMotion:
        _handle_editor_mouse_motion_input(event)
    elif event is InputEventKey and event.pressed:
        _handle_editor_keyboard_input(event)

func _handle_editor_mouse_button_input(event: InputEventMouseButton) -> void:
    """處理編輯器模式滑鼠按鈕輸入"""
    if event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # 選擇物件並開始拖拽
            _select_object_at_position(get_global_mouse_position())
            if selected_object:
                _start_object_drag()
        else:
            # 結束拖拽
            _end_object_drag()
    elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        # 取消選擇
        _deselect_object()

func _handle_editor_mouse_motion_input(event: InputEventMouseMotion) -> void:
    """處理編輯器模式滑鼠移動輸入"""
    if is_dragging_object:
        _update_object_drag(event.global_position)

func _handle_editor_keyboard_input(event: InputEventKey) -> void:
    """處理編輯器模式鍵盤輸入"""
    if event.is_action_pressed("ui_cancel"):
        # ESC鍵取消選擇
        _deselect_object()
    elif event.is_action_pressed("ui_accept"):
        # 空格鍵切換編輯器模式
        _on_toggle_editor_mode()

func _select_object_at_position(pos: Vector2) -> void:
    """在指定位置選擇物件"""
    # 首先嘗試使用物理查詢
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsPointQueryParameters2D.new()
    query.position = pos
    query.collision_mask = 0xFFFFFFFF  # 檢查所有碰撞層
    
    var result = space_state.intersect_point(query)
    
    if result.size() > 0:
        var collider = result[0]["collider"]
        if collider in editable_objects:
            _select_object(collider)
            return
    
    # 如果物理查詢失敗，使用距離檢測
    _select_object_by_distance(pos)

func _select_object_by_distance(pos: Vector2) -> void:
    """通過距離檢測選擇最近的物件"""
    var closest_object: Node2D = null
    var closest_distance: float = 100.0  # 增加最大選擇距離，特別是對 Land 物件
    
    # 優先選擇 Land 物件
    var land_objects: Array[Node2D] = []
    var other_objects: Array[Node2D] = []
    
    for obj in editable_objects:
        if not obj or not is_instance_valid(obj):
            continue
        
        if obj.is_in_group("Land"):
            land_objects.append(obj)
        else:
            other_objects.append(obj)
    
    # 首先檢查 Land 物件
    for obj in land_objects:
        var distance = pos.distance_to(obj.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_object = obj
    
    # 如果沒有找到 Land 物件，檢查其他物件
    if not closest_object:
        closest_distance = 50.0  # 對其他物件使用較小的選擇距離
        for obj in other_objects:
            var distance = pos.distance_to(obj.global_position)
            if distance < closest_distance:
                closest_distance = distance
                closest_object = obj
    
    if closest_object:
        print("通過距離檢測選擇物件: ", closest_object.name, " 距離: ", closest_distance)
        _select_object(closest_object)
    else:
        print("沒有找到附近的物件")
        _deselect_object()

func _select_object(obj: Node2D) -> void:
    """選擇物件（不記錄拖拽位置）"""
    selected_object = obj
    is_dragging_object = false  # 先不開始拖拽
    
    # 停止物件速度（類似玩家拖拽）
    if obj.has_method("set_velocity"):
        obj.set_velocity(Vector2.ZERO)
    elif obj.has_method("velocity"):
        obj.velocity = Vector2.ZERO
    
    # 添加視覺高亮效果
    _highlight_object(obj, true)
    
    print("已選擇物件: ", obj.name, " 位置: ", obj.global_position)

func _start_object_drag() -> void:
    """開始物件拖拽（記錄拖拽起始位置）"""
    if not selected_object:
        return
    
    is_dragging_object = true
    
    # 記錄拖拽起始位置 - 使用相機空間座標
    var mouse_pos = get_viewport().get_mouse_position()
    object_drag_start_position = mouse_pos
    object_start_position = selected_object.global_position
    

func _deselect_object() -> void:
    """取消選擇物件"""
    if selected_object:
        print("取消選擇物件: ", selected_object.name)
        _highlight_object(selected_object, false)
        selected_object = null
    else:
        print("沒有選中的物件需要取消選擇")
    is_dragging_object = false

func _highlight_object(obj: Node2D, highlight: bool) -> void:
    """高亮顯示物件"""
    if not obj:
        return
    
    # 使用modulate來高亮物件
    if highlight:
        obj.modulate = Color(1.5, 1.5, 1.0, 0.8)  # 其他物件使用普通黃色高亮
        print("高亮物件: ", obj.name)
    else:
        obj.modulate = Color.WHITE
        print("取消高亮物件: ", obj.name)

func _update_object_drag(mouse_position: Vector2) -> void:
    """更新物件拖拽位置（使用相機空間座標）"""
    if not is_dragging_object or not selected_object:
        return
    
    # 獲取當前滑鼠位置（相機空間）
    var current_mouse_pos = get_viewport().get_mouse_position()
    
    # 計算拖拽偏移量（相機空間）
    var drag_offset = current_mouse_pos - object_drag_start_position
    
    # 考慮相機縮放
    var camera_zoom = Vector2.ONE
    if phantom_camera:
        camera_zoom = phantom_camera.zoom
    
    # 根據相機縮放調整拖拽靈敏度
    # 當相機縮放較大時，需要更大的滑鼠移動來產生相同的世界位置變化
    drag_offset = drag_offset / camera_zoom
    
    # 調試信息（可選）
    if camera_zoom != Vector2.ONE:
        print("物件拖拽 - 相機縮放: ", camera_zoom, " 原始偏移: ", current_mouse_pos - object_drag_start_position, " 調整後偏移: ", drag_offset)
    
    # 應用相對位置拖拽
    selected_object.global_position = object_start_position + drag_offset
    
    # 持續重置速度以防止重力影響（類似玩家拖拽）
    if selected_object.has_method("set_velocity"):
        selected_object.set_velocity(Vector2.ZERO)
    elif selected_object.has_method("velocity"):
        selected_object.velocity = Vector2.ZERO

func _end_object_drag() -> void:
    """結束物件拖拽"""
    if is_dragging_object:
        is_dragging_object = false
        print("物件拖拽已結束")

func _on_toggle_editor_mode() -> void:
    """切換編輯器模式"""
    is_editor_mode = not is_editor_mode
    
    if is_editor_mode:
        _enter_editor_mode()
    else:
        _exit_editor_mode()
    
    _update_editor_mode_button_text()
    
    # 讓按鈕失去焦點
    if editor_mode_button:
        editor_mode_button.release_focus()

func _enter_editor_mode() -> void:
    """進入編輯器模式"""
    print("進入編輯器模式")
    
    # 禁用遊戲UI
    if in_game_ui:
        in_game_ui.visible = false
    
    # 隱藏測試控制按鈕
    _hide_testing_buttons(true)
    
    # 顯示所有可編輯物件的邊框
    _show_object_outlines(true)
    
    # 停止玩家移動並禁用物理處理
    if player:
        player.velocity = Vector2.ZERO
        # 禁用玩家物理處理（這會停止重力和其他物理效果）
        player.set_physics_process(false)

func _exit_editor_mode() -> void:
    """退出編輯器模式"""
    print("退出編輯器模式")
    
    # 啟用遊戲UI
    if in_game_ui:
        in_game_ui.visible = true
    
    # 重新顯示測試控制按鈕
    _hide_testing_buttons(false)
    
    # 隱藏所有可編輯物件的邊框
    _show_object_outlines(false)
    
    # 重新啟用玩家物理處理
    if player:
        # 重新啟用玩家物理處理（這會恢復重力和其他物理效果）
        player.set_physics_process(true)
    
    # 取消選擇
    _deselect_object()

func _hide_testing_buttons(should_hide: bool) -> void:
    """隱藏/顯示測試控制按鈕"""
    if reset_button:
        reset_button.visible = not should_hide
    
    if checkpoint_button:
        checkpoint_button.visible = not should_hide

func _show_object_outlines(display: bool) -> void:
    """顯示/隱藏物件邊框"""
    for obj in editable_objects:
        if obj and is_instance_valid(obj):
            if display:
                if obj.is_in_group("Land"):
                    obj.modulate = Color(1.3, 1.3, 1.0, 1.0)  # Land 物件使用更明顯的高亮
                    print("顯示 Land 物件邊框: ", obj.name)
                else:
                    obj.modulate = Color(1.2, 1.2, 1.0, 1.0)  # 其他物件使用輕微高亮
            else:
                obj.modulate = Color.WHITE

func _update_editor_mode_button_text() -> void:
    """更新編輯器模式按鈕文字"""
    if editor_mode_button:
        if is_editor_mode:
            editor_mode_button.text = "退出編輯模式 (E)"
        else:
            editor_mode_button.text = "進入編輯模式 (E)"

# ========== 編輯器模式公共方法 ==========

func is_in_editor_mode() -> bool:
    """檢查是否在編輯器模式"""
    return is_editor_mode

func get_selected_object() -> Node2D:
    """獲取當前選擇的物件"""
    return selected_object

func get_editable_objects() -> Array[Node2D]:
    """獲取所有可編輯物件"""
    return editable_objects

# ========== 保存功能 ==========

func _on_save_changes() -> void:
    """保存編輯變更"""
    if not testing_level:
        print("無法保存：沒有關卡")
        return
    
    print("開始保存關卡變更...")
    
    # 獲取關卡場景的PackedScene
    var level_scene = testing_level.scene_file_path
    if not level_scene:
        print("無法保存：關卡沒有場景文件路徑")
        return
    
    # 保存場景
    var packed_scene = PackedScene.new()
    packed_scene.pack(testing_level)
    
    var save_result = ResourceSaver.save(packed_scene, level_scene)
    if save_result == OK:
        print("關卡已成功保存到: ", level_scene)
        _show_save_success_message()
    else:
        print("保存失敗，錯誤代碼: ", save_result)
        _show_save_error_message()
    
    # 讓按鈕失去焦點
    if save_changes_button:
        save_changes_button.release_focus()

func _show_save_success_message() -> void:
    """顯示保存成功訊息"""
    # 這裡可以添加UI提示，暫時用print
    print("✓ 關卡變更已保存")

func _show_save_error_message() -> void:
    """顯示保存錯誤訊息"""
    # 這裡可以添加UI提示，暫時用print
    print("✗ 保存失敗，請檢查文件權限")
