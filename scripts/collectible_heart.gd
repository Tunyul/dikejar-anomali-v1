extends Area2D

@export var bob_amplitude: float = 8.0
@export var bob_frequency: float = 1.2

var _base_y: float = 0.0
var _t: float = 0.0

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    _base_y = position.y
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    _t += delta
    position.y = _base_y + sin(_t * TAU * bob_frequency) * bob_amplitude

func _on_body_entered(_body: Node) -> void:
    queue_free()
