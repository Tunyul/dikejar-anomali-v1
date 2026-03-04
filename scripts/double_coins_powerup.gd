extends Area2D

class_name DoubleCoinsPowerup

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node) -> void:
    var gm := get_tree().get_root().get_node_or_null("GameManager")
    if gm != null and gm.has_method("activate_skill"):
        gm.activate_skill("double_coins_run", "pickup", 0.0, 0.0)
        TransitionManager.play_sfx(&"double_coins_pickup")
    queue_free()
