extends Area2D

@export var speed: float = 200.0
@export var damage_on_hit: int = 40

func _try_consume_shield_hit() -> bool:
    var _main_node := get_tree().get_root().get_node_or_null("Main")
    if _main_node and _main_node.has_method("try_consume_shield_hit"):
        return bool(_main_node.call("try_consume_shield_hit"))
    if _main_node and _main_node.has_method("is_shield_active"):
        return bool(_main_node.call("is_shield_active"))
    return false

func _ready() -> void:
    collision_layer = 4
    collision_mask = 2
    if has_node("CollisionShape2D"):
        var cs = $CollisionShape2D
        if cs.shape == null:
            var rect := RectangleShape2D.new()
            rect.size = Vector2(64, 64)
            cs.shape = rect
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position.x -= speed * delta
    if position.x < -200:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body is Player:
        var player := body as Player
        if _try_consume_shield_hit():
            collision_layer = 0
            collision_mask = 0
            queue_free()
            return
        if player.has_method("apply_damage"):
            player.apply_damage(damage_on_hit)
        if player.has_method("apply_hit_reaction"):
            player.apply_hit_reaction(global_position)
        collision_layer = 0
        collision_mask = 0
        queue_free()
