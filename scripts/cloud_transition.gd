extends Control

signal finished

@export var duration_in: float = 0.7
@export var hold_time: float = 0.3
@export var duration_out: float = 0.7
@export var cloud_count: int = 6
@export var cloud_color: Color = Color(1, 1, 1, 0.95)

var _offset: float = 0.0
var _vw: float = 0.0
var _vh: float = 0.0
var _shapes: Array = []
var _running: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_offset = 0.0

func _process(_delta: float) -> void:
	if visible and _running:
		queue_redraw()

func _draw() -> void:
	if _shapes.is_empty():
		return
	for s in _shapes:
		var cx: float = float(s[0]) + _offset
		var cy: float = float(s[1])
		var r: float = float(s[2])
		draw_circle(Vector2(cx, cy), r, cloud_color)

func _prepare_shapes() -> void:
	var rect := get_viewport_rect()
	_vw = rect.size.x
	_vh = rect.size.y
	_shapes.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(cloud_count):
		var cy := rng.randf_range(_vh * 0.2, _vh * 0.8)
		var r := rng.randf_range(_vh * 0.12, _vh * 0.22)
		var cx := rng.randf_range(-_vw, 0.0)
		_shapes.append([cx, cy, r])
		_shapes.append([cx + r * 0.8, cy - r * 0.35, r * 0.75])
		_shapes.append([cx - r * 0.7, cy - r * 0.2, r * 0.65])

func play() -> void:
	if _running:
		return
	_prepare_shapes()
	visible = true
	_running = true
	_offset = -_vw
	var tw := create_tween()
	tw.tween_property(self, "_offset", 0.0, duration_in).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold_time)
	tw.tween_property(self, "_offset", _vw, duration_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(Callable(self, "_finish"))

func _finish() -> void:
	_running = false
	visible = false
	finished.emit()
