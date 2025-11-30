# MusicManager.gd
# 音樂管理器單例，負責管理背景音樂的播放

extends Node

# 音樂資源路徑
const THEME_4_PATH: String = "res://Assets/music/theme/theme_4.mp3"
const THEME_3_PATH: String = "res://Assets/music/theme/theme_3.mp3"

# 音效資源路徑
const JUMP_2_PATH: String = "res://Assets/music/jump/jump_2.mp3"
const RUNNING_ON_SNOW_PATH: String = "res://Assets/music/running/running_on_snow.mp3"

# 當前播放的音樂節點
var current_music_player: AudioStreamPlayer = null

# 當前播放的跑步音效節點
var current_running_sound_player: AudioStreamPlayer = null

# 音樂音量（0.0 到 1.0）
var music_volume: float = 0.5

# 音效音量（0.0 到 1.0）
var sound_volume: float = 0.7

func _ready() -> void:
	# 設置為自動載入單例
	pass

# 播放選關卡頁面音樂 (theme_4)
func play_level_select_music() -> void:
	play_music(THEME_4_PATH)

# 播放遊玩關卡音樂 (theme_3)
func play_gameplay_music() -> void:
	play_music(THEME_3_PATH)

# 播放指定路徑的音樂
func play_music(music_path: String) -> void:
	# 如果正在播放相同音樂，則不重複播放
	if current_music_player and current_music_player.stream:
		var current_path = current_music_player.stream.resource_path
		if current_path == music_path:
			# 如果音樂已經在播放，直接返回
			if current_music_player.playing:
				return
			# 如果音樂已加載但未播放，繼續播放
			current_music_player.play()
			return
	
	# 停止當前音樂
	stop_music()
	
	# 載入新的音樂資源
	var music_stream = load(music_path)
	if not music_stream:
		push_error("無法載入音樂: " + music_path)
		return
	
	# 創建新的 AudioStreamPlayer 節點
	current_music_player = AudioStreamPlayer.new()
	current_music_player.stream = music_stream
	current_music_player.volume_db = linear_to_db(music_volume)
	
	# 連接 finished 信號以實現循環播放
	current_music_player.finished.connect(_on_music_finished)
	
	# 將音樂播放器添加到場景樹
	add_child(current_music_player)
	
	# 播放音樂
	current_music_player.play()
	
	print("開始播放音樂: ", music_path)

# 音樂播放完成時的回調（用於循環播放）
func _on_music_finished() -> void:
	if current_music_player:
		current_music_player.play()

# 停止當前音樂
func stop_music() -> void:
	if current_music_player:
		# 斷開信號連接
		if current_music_player.finished.is_connected(_on_music_finished):
			current_music_player.finished.disconnect(_on_music_finished)
		current_music_player.stop()
		current_music_player.queue_free()
		current_music_player = null

# 設置音樂音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if current_music_player:
		current_music_player.volume_db = linear_to_db(music_volume)

# 獲取音樂音量
func get_music_volume() -> float:
	return music_volume

# 暫停音樂
func pause_music() -> void:
	if current_music_player and current_music_player.playing:
		current_music_player.stream_paused = true

# 恢復音樂
func resume_music() -> void:
	if current_music_player:
		current_music_player.stream_paused = false

# ========== 音效播放功能 ==========

# 播放跳躍音效
func play_jump_sound() -> void:
	play_sound(JUMP_2_PATH)

# 播放指定路徑的音效
func play_sound(sound_path: String, volume_override: float = -1.0) -> void:
	# 載入音效資源
	var sound_stream = load(sound_path)
	if not sound_stream:
		push_error("無法載入音效: " + sound_path)
		return
	
	# 創建新的 AudioStreamPlayer 節點
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = sound_stream
	
	# 設置音量
	var vol = sound_volume if volume_override < 0.0 else volume_override
	sound_player.volume_db = linear_to_db(vol)
	
	# 將音效播放器添加到場景樹
	add_child(sound_player)
	
	# 連接 finished 信號以自動清理
	sound_player.finished.connect(func(): sound_player.queue_free())
	
	# 播放音效
	sound_player.play()

# 設置音效音量
func set_sound_volume(volume: float) -> void:
	sound_volume = clamp(volume, 0.0, 1.0)

# 獲取音效音量
func get_sound_volume() -> float:
	return sound_volume

# ========== 跑步音效播放功能 ==========

# 開始播放跑步音效（循環播放）
func start_running_sound() -> void:
	# 如果已經在播放，則不重複播放
	if current_running_sound_player and current_running_sound_player.playing:
		return
	
	# 停止之前的跑步音效（如果有的話）
	stop_running_sound()
	
	# 載入跑步音效資源
	var running_stream = load(RUNNING_ON_SNOW_PATH)
	if not running_stream:
		push_error("無法載入跑步音效: " + RUNNING_ON_SNOW_PATH)
		return
	
	# 創建新的 AudioStreamPlayer 節點
	current_running_sound_player = AudioStreamPlayer.new()
	current_running_sound_player.stream = running_stream
	# 降低音量（使用較小的音量值）
	current_running_sound_player.volume_db = linear_to_db(sound_volume * 0.3)
	# 設置播放速度為1.2倍
	current_running_sound_player.pitch_scale = 1.2
	
	# 連接 finished 信號以實現循環播放
	current_running_sound_player.finished.connect(_on_running_sound_finished)
	
	# 將音效播放器添加到場景樹
	add_child(current_running_sound_player)
	
	# 播放音效
	current_running_sound_player.play()

# 跑步音效播放完成時的回調（用於循環播放）
func _on_running_sound_finished() -> void:
	if current_running_sound_player:
		current_running_sound_player.play()

# 停止播放跑步音效
func stop_running_sound() -> void:
	if current_running_sound_player:
		# 斷開信號連接
		if current_running_sound_player.finished.is_connected(_on_running_sound_finished):
			current_running_sound_player.finished.disconnect(_on_running_sound_finished)
		current_running_sound_player.stop()
		current_running_sound_player.queue_free()
		current_running_sound_player = null

