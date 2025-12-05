extends Control
class_name TutorialTextManager

## 管理Tutorial关卡中的RichTextLabel，提供美化样式和动画效果

@export_group("Style Settings")
@export var background_color: Color = Color(0.95, 0.95, 0.95, 0.9)
@export var border_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var border_width: int = 2
@export var corner_radius: int = 8
@export var padding: Vector2 = Vector2(12, 8)
@export var shadow_offset: Vector2 = Vector2(2, 2)
@export var shadow_color: Color = Color(0, 0, 0, 0.3)

@export_group("Animation Settings")
@export var fade_in_duration: float = 0.5
@export var fade_in_delay_per_label: float = 0.1
@export var enable_typewriter: bool = false
@export var typewriter_speed: float = 0.05  # 每个字符的延迟时间
@export var enable_pulse: bool = false
@export var pulse_duration: float = 2.0
@export var pulse_scale: float = 1.05

@export_group("Text Settings")
@export var text_color: Color = Color(0.06469653, 0.06469653, 0.06469653, 1)
@export var font_size: int = 16

var _rich_text_labels: Array[RichTextLabel] = []
var _label_containers: Array[Control] = []

func _ready() -> void:
	# 延迟一帧，确保所有子节点都已加载
	await get_tree().process_frame
	_setup_tutorial_labels()

func _setup_tutorial_labels() -> void:
	# 查找所有RichTextLabel子节点
	_find_rich_text_labels(self)
	
	# 为每个RichTextLabel创建美化容器
	for label in _rich_text_labels:
		_setup_label(label)

func _find_rich_text_labels(node: Node) -> void:
	"""递归查找所有RichTextLabel节点"""
	for child in node.get_children():
		if child is RichTextLabel:
			_rich_text_labels.append(child)
		else:
			_find_rich_text_labels(child)

func _setup_label(label: RichTextLabel) -> void:
	"""为单个RichTextLabel设置美化样式和动画"""
	# 保存原始文本
	var original_text = label.text
	var original_position = label.position
	var original_size = label.size
	
	# 创建容器来包装RichTextLabel
	var container = Control.new()
	container.name = label.name + "_Container"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 创建背景面板
	var background = Panel.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 创建样式框
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = background_color
	style_box.border_color = border_color
	style_box.border_width_left = border_width
	style_box.border_width_top = border_width
	style_box.border_width_right = border_width
	style_box.border_width_bottom = border_width
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius
	style_box.shadow_color = shadow_color
	style_box.shadow_offset = shadow_offset
	style_box.shadow_size = 4
	
	background.add_theme_stylebox_override("panel", style_box)
	container.add_child(background)
	
	# 创建阴影层（额外的阴影效果）
	var shadow = ColorRect.new()
	shadow.name = "Shadow"
	shadow.color = shadow_color
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.z_index = -1
	container.add_child(shadow)
	
	# 调整label设置
	label.text = ""  # 清空文本，准备动画
	label.add_theme_color_override("default_color", text_color)
	if font_size > 0:
		label.add_theme_font_size_override("normal_font_size", font_size)
	
	# 将label添加到容器中
	var label_parent = label.get_parent()
	label.get_parent().remove_child(label)
	container.add_child(label)
	
	# 设置label在容器中的位置（添加padding）
	label.position = padding
	label.size = original_size - padding * 2
	
	# 调整容器大小以包含padding
	container.size = original_size + padding * 2
	container.position = original_position - padding
	
	# 将容器添加到原label的父节点
	label_parent.add_child(container)
	container.move_child(background, 0)  # 确保背景在最底层
	
	# 调整阴影位置和大小
	shadow.position = shadow_offset
	shadow.size = container.size
	
	# 设置初始透明度为0（用于淡入动画）
	container.modulate.a = 0.0
	_label_containers.append(container)
	
	# 启动动画
	var index = _label_containers.size() - 1
	_start_label_animation(container, label, original_text, index)

func _start_label_animation(container: Control, label: RichTextLabel, text: String, index: int) -> void:
	"""启动标签的动画效果"""
	# 计算延迟时间
	var delay = index * fade_in_delay_per_label
	
	# 如果有延迟，先等待
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	# 淡入动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 淡入容器
	tween.tween_property(container, "modulate:a", 1.0, fade_in_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 可选：从下方滑入
	var start_y = container.position.y + 20
	var end_y = container.position.y
	container.position.y = start_y
	tween.tween_property(container, "position:y", end_y, fade_in_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 等待淡入完成后再显示文本
	await tween.finished
	
	# 显示文本（打字机效果或直接显示）
	if enable_typewriter:
		_typewriter_effect(label, text)
	else:
		label.text = text
	
	# 可选的脉冲动画
	if enable_pulse:
		_start_pulse_animation(container)

func _typewriter_effect(label: RichTextLabel, text: String) -> void:
	"""打字机效果：逐字符显示文本"""
	label.text = text
	label.visible_characters = 0
	
	for i in range(text.length()):
		label.visible_characters += 1
		await get_tree().create_timer(typewriter_speed).timeout

func _start_pulse_animation(container: Control) -> void:
	"""启动脉冲动画：轻微的缩放效果"""
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var original_scale = container.scale
	tween.tween_property(container, "scale", original_scale * pulse_scale, pulse_duration / 2)
	tween.tween_property(container, "scale", original_scale, pulse_duration / 2)
