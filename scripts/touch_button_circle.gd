extends Node2D

@export var radius: float = 48.0
@export var color: Color = Color(0.1, 0.4, 1.0)
@export var border_color: Color = Color(1, 1, 1, 0.85)
@export var border_width: float = 4.0
@export var label_text: String = ""
@export var label_color: Color = Color(1, 1, 1)

func _ready() -> void:
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, color)
    if border_width > 0.0:
        draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, border_color, border_width, true)
