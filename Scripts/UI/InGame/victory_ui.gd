extends CanvasLayer

# 勝利UI組件
@onready var victory_label: Label = %VictoryLabel
@onready var particles: CPUParticles2D = %Particles
@onready var return_button: Button = %ReturnButton

# 勝利信號
signal victory_animation_finished
signal return_to_level_select_requested

func _ready() -> void:
	# 初始隱藏
	visible = false
	
	# 設置勝利文字
	if victory_label:
		victory_label.modulate = Color.GOLD
	
	# 設置返回按鈕
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)

func show_victory() -> void:
	"""顯示勝利UI"""
	visible = true
	
	# 播放粒子效果
	if particles:
		particles.emitting = true
	

func hide_victory() -> void:
	"""隱藏勝利UI"""
	visible = false
	
	# 停止粒子效果
	if particles:
		particles.emitting = false


func _on_animation_finished() -> void:
	"""當慶祝動畫完成時觸發"""
	victory_animation_finished.emit()

func _on_return_button_pressed() -> void:
	"""當返回按鈕被按下時觸發"""
	return_to_level_select_requested.emit()
