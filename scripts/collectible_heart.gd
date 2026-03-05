extends Area2D
class_name HeartPickup

@export var heal_amount: int = 25
@export var heal_percent: float = 0.0
@export var bob_amplitude: float = 8.0
@export var bob_frequency: float = 1.2
@export var enable_bobbing: bool = true
@export var enable_pickup: bool = true

var _base_y: float = 0.0
var _t: float = 0.0
var _collected: bool = false

func _ready() -> void:
    _base_y = position.y
    _collected = false
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
    _collected = false
    visible = true
    set_deferred("monitoring", true)

func _find_ground_pool_owner() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    var cs := tree.current_scene
    if cs:
        var direct := cs.get_node_or_null("Ground")
        if direct and direct.has_method("return_spawned_node_to_pool"):
            return direct
        var found := cs.find_child("Ground", true, false)
        if found and found.has_method("return_spawned_node_to_pool"):
            return found
    return null

func _despawn_self() -> void:
    visible = false
    set_deferred("monitoring", false)
    var ground := _find_ground_pool_owner()
    if ground and bool(ground.call("return_spawned_node_to_pool", self)):
        return
    queue_free()

func _physics_process(delta: float) -> void:
    if not enable_bobbing:
        return
    _t += delta
    position.y = _base_y + sin(_t * TAU * bob_frequency) * bob_amplitude

func _on_body_entered(body: Node) -> void:
    if _collected:
        return
    _collected = true
    if body.is_in_group("player") or body is Player:
        if body.has_method("heal"):
            var amount: int = heal_amount
            if heal_percent > 0.0 and body.has_method("get"):
                var max_h: int = int(body.get("max_health"))
                if max_h > 0:
                    amount = int(round(float(max_h) * heal_percent))
                    if amount <= 0: amount = 1
            body.heal(amount)
            if has_node("/root/TransitionManager"):
                get_node("/root/TransitionManager").play_sfx("heart_pickup")
    _despawn_self()
