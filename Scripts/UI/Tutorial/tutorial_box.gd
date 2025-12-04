@tool
extends Control
class_name TutorialBox

## Custom Tutorial Box
## Allows free resizing of the border independent of text content.
## Features: Typewriter effect, Pop-up animation, Custom styling.

signal text_finished

@export_group("Content")
@export_multiline var text: String = "Enter tutorial text here...":
	set(value):
		text = value
		if _label:
			_label.text = value
			if Engine.is_editor_hint():
				_label.visible_ratio = 1.0

@export var auto_start: bool = true

@export_group("Box Style")
@export var box_size: Vector2 = Vector2(300, 150):
	set(value):
		box_size = value
		custom_minimum_size = value
		size = value
		if _panel: _update_style()

@export var bg_color: Color = Color("1aa6bd57"):
	set(value):
		bg_color = value
		if _panel: _update_style()

@export var border_color: Color = Color("ffffff3f"):
	set(value):
		border_color = value
		if _panel: _update_style()

@export var border_width: int = 2:
	set(value):
		border_width = value
		if _panel: _update_style()

@export var corner_radius: int = 10:
	set(value):
		corner_radius = value
		if _panel: _update_style()

@export var padding: int = 16:
	set(value):
		padding = value
		if _label: _update_style()

@export_group("Text Style")
@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		if _label: _update_style()

@export var font_size: int = 16:
	set(value):
		font_size = value
		if _label: _update_style()

@export_group("Animation")
@export var appear_duration: float = 0.5
@export var typewriter_speed: float = 0.03
@export var animate_scale: bool = true

# Internal nodes
var _panel: Panel
var _label: RichTextLabel
var _style_box: StyleBoxFlat

func _ready() -> void:
	_setup_nodes()
	_update_style()
	
	if not Engine.is_editor_hint():
		if auto_start:
			play_appear()

func _setup_nodes() -> void:
	# Setup Panel (Background)
	if has_node("BackgroundPanel"):
		_panel = get_node("BackgroundPanel")
	else:
		_panel = Panel.new()
		_panel.name = "BackgroundPanel"
		add_child(_panel)
		_panel.move_to_front() 
	
	# Setup Label
	if has_node("ContentLabel"):
		_label = get_node("ContentLabel")
	else:
		_label = RichTextLabel.new()
		_label.name = "ContentLabel"
		add_child(_label)
	
	# Ensure Label is above Panel
	_label.move_to_front()
	
	# Default Setup
	_label.scroll_active = false
	_label.clip_contents = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Anchor Setup
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Label Anchor with margins (padding)
	_label.anchor_left = 0
	_label.anchor_top = 0
	_label.anchor_right = 1
	_label.anchor_bottom = 1

func _update_style() -> void:
	if not _panel or not _label: return
	
	# Update Size
	custom_minimum_size = box_size
	size = box_size
	
	# Update StyleBox
	if not _style_box:
		_style_box = StyleBoxFlat.new()
	
	_style_box.bg_color = bg_color
	_style_box.border_color = border_color
	_style_box.set_border_width_all(border_width)
	_style_box.set_corner_radius_all(corner_radius)
	
	_panel.add_theme_stylebox_override("panel", _style_box)
	
	# Update Text Style
	_label.add_theme_color_override("default_color", text_color)
	_label.add_theme_font_size_override("normal_font_size", font_size)
	
	# Update Padding (Margins)
	_label.offset_left = padding
	_label.offset_top = padding
	_label.offset_right = -padding
	_label.offset_bottom = -padding
	
	# Text content
	if _label.text != text:
		_label.text = text

func play_appear() -> void:
	if animate_scale:
		pivot_offset = size / 2
		scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, appear_duration)
		await tween.finished
	
	play_typewriter()

func play_typewriter() -> void:
	_label.visible_ratio = 0.0
	var tween = create_tween()
	var duration = text.length() * typewriter_speed
	tween.tween_property(_label, "visible_ratio", 1.0, duration)
	await tween.finished
	text_finished.emit()
