extends Area2D

class_name MagnetPowerup

@export var duration_sec: float = 30.0

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    var anim := $AnimatedSprite2D
    if anim:
        anim.play()
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is Node:
        var _main_node := get_tree().get_root().get_node_or_null("Main")
        if _main_node != null and _main_node.has_method("activate_magnet"):
            _main_node.activate_magnet(duration_sec)
            TransitionManager.play_sfx(&"magnet_pickup")
    queue_free()
