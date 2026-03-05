extends Area2D

class_name SpeedBoostPowerup

@export var duration_sec: float = 5.0
@export var multiplier: float = 1.5
var _picked: bool = false

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    _picked = false
    body_entered.connect(_on_body_entered)

func reset() -> void:
    _picked = false
    visible = true
    collision_layer = 8
    collision_mask = 2
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
    collision_layer = 0
    collision_mask = 0
    set_deferred("monitoring", false)
    var ground := _find_ground_pool_owner()
    if ground and bool(ground.call("return_spawned_node_to_pool", self)):
        return
    queue_free()

func _on_body_entered(body: Node) -> void:
    if _picked:
        return
    _picked = true
    if body is Node:
        var gm := get_tree().get_root().get_node_or_null("GameManager")
        if gm != null and gm.has_method("activate_skill"):
            gm.activate_skill("speed_boost_run", "pickup", duration_sec, multiplier)
            TransitionManager.play_sfx(&"speed_boost_pickup")
    _despawn_self()
