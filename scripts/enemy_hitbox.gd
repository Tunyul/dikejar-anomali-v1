extends Area2D

func _ready() -> void:
    collision_layer = 4
    collision_mask = 2
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if not (body is Player):
        return
    var player := body as Player
    if player.attack_active:
        var enemy_node := get_parent()
        if enemy_node and enemy_node.has_method("on_player_attack_hit"):
            enemy_node.call("on_player_attack_hit", player)
        return
    if player.has_method("trigger_game_over"):
        player.trigger_game_over("hit_enemy")
