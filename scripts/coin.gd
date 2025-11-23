extends Area2D

signal collected(segment: String)

@export var source_segment: String = ""
@export var tint: Color = Color(1, 1, 1, 1)
@export var is_stack: bool = false
@export var osc_amplitude: float = 12.0
@export var osc_frequency: float = 1.2
@export var anim_fps: float = 12.0

var _base_y: float = 0.0
var _t: float = 0.0
var _collected: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.animation = "spin"
		anim.play()
		anim.speed_scale = anim_fps / 12.0
		anim.modulate = tint
	call_deferred("_capture_base_y")
	body_entered.connect(_on_body_entered)

func _capture_base_y() -> void:
	_base_y = position.y

func _physics_process(delta: float) -> void:
	_t += delta
	position.y = _base_y + abs(sin(_t * TAU * osc_frequency)) * osc_amplitude


func _on_body_entered(_body: Node) -> void:
	if _collected:
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(source_segment)
	queue_free()
