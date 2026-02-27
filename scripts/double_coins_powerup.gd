extends Area2D

class_name DoubleCoinsPowerup

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node) -> void:
    var _main_node := get_tree().get_root().get_node_or_null("Main")
    if _main_node != null and _main_node.has_method("activate_double_coins_run"):
        _main_node.activate_double_coins_run()
        TransitionManager.play_sfx(&"double_coins_pickup")
    queue_free()
