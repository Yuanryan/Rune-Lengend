# LevelManager.gd
# 關卡管理器單例，負責載入和管理關卡場景
extends Node

# 當前關卡場景
var current_level_scene: PackedScene = null
var current_level: Level = null

# 關卡場景字典
var level_scenes: Dictionary = {}


# 信號
signal level_loaded(level_scene: Level)
signal level_unloaded()
signal player_spawned(player: Player)

func _ready() -> void:
	_initialize_level_scenes()

# 初始化關卡場景
func _initialize_level_scenes() -> void:
	_load_levels_from_list()

# 從 LevelList 載入所有關卡
func _load_levels_from_list() -> void:
	# 從 LevelList 資源獲取所有關卡類別
	var level_lists = LevelList.get_level_lists()
	for category_name in level_lists.keys():
		var scenes = level_lists[category_name] as Array
		for scene in scenes:
			if scene is PackedScene:
				# 從場景中提取關卡名稱
				var level_name = _extract_level_name_from_scene(scene)
				if level_name.is_empty():
					# 如果無法從場景中提取名稱，使用場景資源路徑
					var scene_path = scene.resource_path
					var file_name = scene_path.get_file().get_basename()
					level_name = file_name.replace("_", " ").capitalize()

				if not level_scenes.has(category_name):
					level_scenes[category_name] = []
				# 儲存到關卡場景字典，使用關卡名稱作為鍵
				level_scenes[category_name].append({
					"name": level_name,
					"scene": scene
				})

# 從場景中提取關卡名稱
func _extract_level_name_from_scene(scene: PackedScene) -> String:
	"""從場景的 Level 中提取關卡名稱"""
	if not scene:
		return ""

	# 實例化場景以檢查其內容
	var scene_state = scene.get_state()
	if scene_state:
		return scene_state.get_node_property_value(0, 1)
	return ""

# ========== 核心功能 ==========

# 清除所有子彈
func _clear_all_bullets() -> void:
	"""清除場景中的所有子彈"""
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()

# 載入關卡場景
func load_level_scene(level_scene: PackedScene, spawn_position: Vector2 = Vector2.ZERO) -> Level:
	# 清除所有子彈
	_clear_all_bullets()

	# 清除當前關卡（先從場景樹移除再釋放，避免同幀並存）
	if current_level:
		current_level.get_parent().remove_child(current_level)
		current_level.queue_free()
		current_level = null
		GameManager.remove_player()

	# 設定當前關卡場景
	current_level_scene = level_scene

	# 實例化關卡場景
	current_level = level_scene.instantiate()
	if not current_level:
		push_error("無法載入關卡場景")
		return null

	get_tree().current_scene.add_child(current_level)

	# 如果指定了生成位置，設置起始點並生成玩家
	if spawn_position != Vector2.ZERO:
		current_level.starting_point.global_position = spawn_position

	current_level.spawn_player()

	# 通知 UI Manager 創建卡片
	UIManager.create_cards_from_level(current_level)
	GameManager.set_game_state(GameManager.GameState.GAME_PLAY)

	level_loaded.emit(current_level)
	return current_level

# 卸載關卡
func unload_level() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null
		GameManager.remove_player()
		current_level_scene = null
		level_unloaded.emit()
		print("關卡已卸載")

# 獲取當前關卡
func get_current_level() -> Level:
	return current_level

# 獲取所有關卡場景
func get_all_level_scenes() -> Dictionary:
	return level_scenes

# 重新載入當前關卡
func reload_current_level() -> Level:
	"""重新載入當前關卡，保持動作佇列狀態"""
	if not current_level_scene:
		push_error("沒有當前關卡場景可以重新載入")
		return null

	# 保存動作佇列狀態
	var saved_action_queue = _save_action_queue()

	# 重新載入關卡
	var reloaded_level = load_level_scene(current_level_scene)

	# 恢復動作佇列
	if reloaded_level:
		await _restore_action_queue(saved_action_queue)
		# 確保遊戲狀態設置為規劃階段
		GameManager.reset_to_planning()

	return reloaded_level

# 保存和恢復動作佇列的通用方法
func _save_action_queue() -> Array:
	"""保存當前動作佇列狀態"""
	var saved_action_queue = []
	var in_game_ui = UIManager.get_in_game_ui()
	if in_game_ui and in_game_ui.action_queue:
		saved_action_queue = in_game_ui.action_queue.get_action_descriptors()
	return saved_action_queue

func _restore_action_queue(saved_action_queue: Array) -> void:
	"""恢復動作佇列狀態"""
	if saved_action_queue.size() > 0:
		await get_tree().process_frame
		var in_game_ui = UIManager.get_in_game_ui()
		if in_game_ui:
			in_game_ui.restore_action_queue(saved_action_queue)

# 從最後檢查點重新載入關卡
func reload_level_from_last_checkpoint() -> Level:
	"""從最後到達的檢查點重新載入關卡"""
	if not current_level_scene:
		push_error("沒有當前關卡場景可以重新載入")
		return null

	# 保存當前檢查點索引、檢查點狀態和動作佇列狀態
	var saved_checkpoint_index = -1
	var saved_checkpoint_states: Dictionary = {}
	var spawn_position = Vector2.ZERO

	if current_level:
		saved_checkpoint_index = current_level.get_current_checkpoint_index()
		# 保存所有檢查點的 active 狀態
		for i in range(current_level.get_checkpoint_count()):
			var checkpoint = current_level.get_checkpoint_by_index(i)
			if checkpoint:
				saved_checkpoint_states[i] = checkpoint.active

		# 獲取檢查點位置
		if saved_checkpoint_index >= 0:
			var checkpoint = current_level.get_checkpoint_by_index(saved_checkpoint_index)
			if checkpoint:
				spawn_position = checkpoint.global_position

	var saved_action_queue = _save_action_queue()

	# 重新載入關卡並在檢查點位置生成玩家
	# 相機位置由 PhantomCamera2D 系統自動處理
	var reloaded_level = load_level_scene(current_level_scene, spawn_position)

	# 恢復動作佇列和檢查點狀態
	if reloaded_level:
		await _restore_action_queue(saved_action_queue)
		_restore_checkpoint_states(reloaded_level, saved_checkpoint_states, saved_checkpoint_index)
		# 確保遊戲狀態設置為規劃階段
		GameManager.reset_to_planning()

	return reloaded_level

# 從指定檢查點重新載入關卡
func reload_level_from_specific_checkpoint(checkpoint_index: int) -> Level:
	"""從指定檢查點重新載入關卡"""
	if not current_level_scene:
		push_error("沒有當前關卡場景可以重新載入")
		return null

	# 獲取指定檢查點位置
	var spawn_position = Vector2.ZERO
	if current_level:
		var checkpoint = current_level.get_checkpoint_by_index(checkpoint_index)
		if checkpoint:
			spawn_position = checkpoint.global_position
		else:
			print("找不到檢查點索引: ", checkpoint_index)

	var saved_action_queue = _save_action_queue()

	# 重新載入關卡並在指定檢查點位置生成玩家
	# 相機位置由 PhantomCamera2D 系統自動處理
	var reloaded_level = load_level_scene(current_level_scene, spawn_position)

	# 恢復動作佇列
	if reloaded_level:
		await _restore_action_queue(saved_action_queue)
		# 確保遊戲狀態設置為規劃階段
		GameManager.reset_to_planning()

	return reloaded_level

# 恢復檢查點狀態
func _restore_checkpoint_states(level: Level, checkpoint_states: Dictionary, current_index: int = -1) -> void:
	"""恢復檢查點的 active 狀態和當前檢查點索引，並切換到對應的攝影機"""
	if not level:
		return

	# 恢復所有檢查點的 active 狀態
	if not checkpoint_states.is_empty():
		for i in range(level.get_checkpoint_count()):
			if i in checkpoint_states:
				var checkpoint = level.get_checkpoint_by_index(i)
				if checkpoint:
					checkpoint.active = checkpoint_states[i]

	# # 恢復當前檢查點索引
	if current_index >= 0:
		level.current_checkpoint_index = current_index
		level._switch_to_checkpoint_camera(level.get_checkpoint_by_index(current_index), false)

# 重置關卡（從檢查點）
func reset_level_from_checkpoint() -> void:
	"""重置關卡從最後檢查點，通過 UIManager 啟動過渡動畫"""
	# 通過 UIManager 啟動過渡動畫，過渡動畫會自動調用實際的重置邏輯
	UIManager.start_level_reset_transition()

# 執行實際的關卡重置邏輯（由 InGameUI 在過渡動畫覆蓋螢幕時調用）
func _execute_level_reset() -> void:
	"""執行實際的關卡重置邏輯，包含所有必要的狀態重置"""
	# 停止玩家正在執行的動作
	var player = GameManager.get_player()
	if player:
		player.interrupt_current_action()
		player.is_executing_actions = false

	# 重置 UI 狀態
	var in_game_ui = UIManager.get_in_game_ui()
	if in_game_ui:
		# 解鎖隊列（如果被鎖定的話）
		if in_game_ui.action_queue:
			in_game_ui.action_queue.unlock_queue()
			in_game_ui.action_queue.clear_executing_action()

		# 重置動作使用計數
		if in_game_ui.card_deck:
			in_game_ui.card_deck.reset_action_usage()

	# 重置到規劃階段
	GameManager.reset_to_planning()

	# 重新載入關卡（會自動保存和恢復動作佇列）
	reload_level_from_last_checkpoint()
