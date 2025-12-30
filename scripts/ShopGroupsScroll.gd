extends ScrollContainer

var dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var scroll_start: float = 0.0

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            dragging = true
            drag_start_pos = event.position
            scroll_start = scroll_horizontal
        else:
            dragging = false
    elif dragging and event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        var delta_x: float = motion.position.x - drag_start_pos.x
        scroll_horizontal = int(scroll_start - delta_x)
