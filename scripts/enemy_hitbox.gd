extends Area2D

func _ready() -> void:
    collision_layer = 4
    collision_mask = 2
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is Player:
        if body.has_method("trigger_game_over"):
            body.trigger_game_over("hit_enemy")
