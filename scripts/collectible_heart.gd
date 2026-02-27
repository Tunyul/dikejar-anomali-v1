extends Area2D
# class_name HeartPickup

@export var bob_amplitude: float = 8.0
@export var bob_frequency: float = 1.2
@export var enable_bobbing: bool = true
@export var enable_pickup: bool = true

var _base_y: float = 0.0
var _t: float = 0.0

func _ready() -> void:
    _base_y = position.y
    add_to_group("heart_pickup")
    if enable_pickup:
        collision_layer = 8
        collision_mask = 2
        body_entered.connect(_on_body_entered)
    else:
        collision_layer = 0
        collision_mask = 0

func reset() -> void:
    _base_y = position.y
    _t = 0.0
    visible = true
    set_deferred("monitoring", true)

func _physics_process(delta: float) -> void:
    if not enable_bobbing:
        return
    _t += delta
    position.y = _base_y + sin(_t * TAU * bob_frequency) * bob_amplitude

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        if body.has_method("heal"):
            body.heal(1)
            if has_node("/root/TransitionManager"):
                get_node("/root/TransitionManager").play_sfx("heart_pickup")
    queue_free()
