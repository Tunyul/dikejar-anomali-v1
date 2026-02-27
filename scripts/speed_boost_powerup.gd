extends Area2D

class_name SpeedBoostPowerup

@export var duration_sec: float = 5.0
@export var multiplier: float = 1.5

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is Node:
        var _main_node := get_tree().get_root().get_node_or_null("Main")
        if _main_node != null and _main_node.has_method("activate_speed_boost"):
            _main_node.activate_speed_boost(duration_sec, multiplier)
            TransitionManager.play_sfx(&"speed_boost_pickup")
    queue_free()
