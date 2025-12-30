extends Area2D

@export var damage_on_hit: int = 25

func _is_shield_active() -> bool:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("is_shield_active"):
        return main.is_shield_active()
    return false

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
    var shield_active := _is_shield_active()
    if shield_active:
        var enemy_node2 := get_parent()
        if enemy_node2 and enemy_node2.has_method("on_player_attack_hit"):
            enemy_node2.call("on_player_attack_hit", player)
        return
    if player.has_method("apply_damage"):
        player.apply_damage(damage_on_hit)
    if player.has_method("apply_hit_reaction"):
        player.apply_hit_reaction(global_position)
