extends Area2D

@export var speed: float = 200.0
@export var damage_on_hit: int = 100

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
        if body.has_method("trigger_game_over"):
            body.trigger_game_over("hit_obstacle")