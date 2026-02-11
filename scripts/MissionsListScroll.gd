@tool
extends ScrollContainer


@export var drag_threshold: float = 6.0

var _pressing: bool = false
var _dragging: bool = false
var _start_pos: Vector2 = Vector2.ZERO
var _scroll_start: float = 0.0


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var vsb := get_v_scroll_bar()
	if vsb:
		vsb.visible = false
		vsb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hsb := get_h_scroll_bar()
	if hsb:
		hsb.visible = false
		hsb.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_dragging = false
			_start_pos = event.position
			_scroll_start = scroll_vertical
		else:
			_pressing = false
			if _dragging:
				accept_event()
			_dragging = false
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_pressing = true
			_dragging = false
			_start_pos = st.position
			_scroll_start = scroll_vertical
		else:
			_pressing = false
			if _dragging:
				accept_event()
			_dragging = false
		return

	if not _pressing:
		return

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_apply_drag_delta(motion.position.y - _start_pos.y)
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_apply_drag_delta(sd.position.y - _start_pos.y)


func _apply_drag_delta(delta_y: float) -> void:
	if not _dragging:
		if absf(delta_y) < drag_threshold:
			return
		_dragging = true
		accept_event()
	scroll_vertical = int(_scroll_start - delta_y)
	accept_event()
