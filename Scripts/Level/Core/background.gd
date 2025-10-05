@tool
extends Node2D

@export_custom(PROPERTY_HINT_LINK, "") var background_scale : Vector2 = Vector2(1.0, 1.0) : set = set_background_scale

var background_layers : Array[Node] = []

func _ready() -> void:
    _set_background_layers()
    set_background_scale(background_scale)
    
func _set_background_layers() -> void:
    if is_inside_tree():
        background_layers = get_tree().get_nodes_in_group("BackgroundLayer")

func set_background_scale(value: Vector2) -> void:
    _set_background_layers()
    background_scale = value
    for layer in background_layers:
        layer.scale = value
        if layer is ColorRect:
            layer.position = layer.size * -0.5 * value
