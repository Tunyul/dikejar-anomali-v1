extends Area2D

class_name HeartPickup

@export var heal_amount: int = 25
@export var osc_amplitude: float = 10.0
@export var osc_frequency: float = 1.0

var _base_y: float = 0.0
var _t: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	var anim := get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play()
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _initialized:
		_base_y = position.y
		_initialized = true
	_t += delta
	position.y = _base_y + sin(_t * TAU * osc_frequency) * osc_amplitude

func _on_body_entered(body: Node) -> void:
	if body is Player:
		var p := body as Player
		if p.has_method("heal"):
			p.heal(heal_amount)
		queue_free()
		return
	if body and body.has_method("heal"):
		body.heal(heal_amount)
	queue_free()
