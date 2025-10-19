# TestingRoom.gd
# 測試房間腳本，用於直接測試關卡
extends Node2D

# 測試關卡相關
@export var testing_level: Level = null
@export var player: Player = null

# UI 相關
@onready var phantom_camera: PhantomCamera2D = %PhantomCamera2D
@onready var in_game_ui: CanvasLayer = %InGameUI
@onready var testing_ui: CanvasLayer = %TestingUI
@onready var level_name_label: Label = %LevelName
@onready var reset_button: Button = %ResetButton
@onready var checkpoint_button: Button = %CheckpointButton
@onready var mouse_movement_button: Button = %MouseMovementButton
@onready var camera_visibility_button: Button = %CameraVisibilityButton

# 測試狀態
var is_testing_mode: bool = false

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
        if testing_level and testing_level.level_resource:
            player.set_available_animals(testing_level.level_resource.available_animals)
        
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

func _connect_game_manager_signals() -> void:
    """連接GameManager的狀態變化信號"""
    if GameManager:
        GameManager.in_game_state_changed.connect(_on_in_game_state_changed)

func _update_ui_display() -> void:
    """更新UI顯示"""
    if level_name_label and testing_level and testing_level.level_resource:
        level_name_label.text = testing_level.level_resource.level_name
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
    """開始拖拽玩家"""
    if not player:
        return
    
    # 直接開始拖拽，不檢查是否點擊在玩家上
    is_dragging_player = true
    drag_start_position = mouse_position
    player_start_position = player.global_position
    
    # 停止玩家速度（包括重力效果）
    player.velocity = Vector2.ZERO
    

func _update_player_drag(mouse_position: Vector2) -> void:
    """更新玩家拖拽位置"""
    if not is_dragging_player or not player:
        return
    
    var drag_offset = mouse_position - drag_start_position
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
    """重置關卡到初始狀態 - 完全重新載入關卡"""
    if not testing_level:
        print("無法重置關卡：缺少關卡")
        return
    
    print("開始完全重置關卡...")
    
    # 使用LevelManager完全重新載入關卡
    _perform_level_reload()

func _perform_level_reload() -> void:
    """執行關卡重新載入（協程）"""
    var reloaded_level = await LevelManager.reload_current_level()
    
    if reloaded_level:
        # 更新測試房間的關卡引用
        testing_level = reloaded_level
        
        # 更新玩家引用
        player = GameManager.get_player()
        
        # 重寫玩家的輸入處理（R鍵觸發從檢查點重新載入）
        if player:
            _override_player_input()
        
        # 重新設置UIManager的UI引用
        _setup_ui_manager_for_testing()
        
        # 更新PhantomCamera的跟隨目標
        _update_phantom_camera_target()
        
        # 更新調試按鈕狀態
        _update_debug_button_states()
        
        print("關卡已完全重新載入")
    else:
        print("關卡重新載入失敗")
    
    # 讓按鈕失去焦點
    if reset_button:
        reset_button.release_focus()

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
    if testing_level.level_resource:
        player.set_available_animals(testing_level.level_resource.available_animals)
    
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
            mouse_movement_button.text = "停用滑鼠移動"
        else:
            mouse_movement_button.text = "啟用滑鼠移動"

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
            camera_visibility_button.text = "停用相機跟隨"
        else:
            camera_visibility_button.text = "啟用相機跟隨"

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
