extends Node2D

@export var anim_scale: float = 0.5
@export var anim_fps: float = 0.0
@export var hitbox_size: Vector2 = Vector2(44, 44)
@export var hitbox_offset: Vector2 = Vector2(0, -12)
@export var sprite_offset_y: float = 0.0
@export var knockback_force: Vector2 = Vector2(120, -420)
@export var gravity: float = 900.0
@export var enemy_coin_scale: float = 0.3
@export var enemy_coin_magnet_speed: float = 480.0
@export var coin_scene: PackedScene = preload("res://scenes/Coin.tscn")

var _velocity: Vector2 = Vector2.ZERO
var _alive: bool = true

func _ready() -> void:
    var spr: AnimatedSprite2D = $AnimatedSprite2D
    if spr != null:
        if anim_scale > 0.0:
            spr.scale = Vector2(anim_scale, anim_scale)
        if anim_fps > 0.0 and spr.sprite_frames != null:
            spr.sprite_frames.set_animation_speed("idle", anim_fps)
        if sprite_offset_y != 0.0:
            spr.position.y += sprite_offset_y
        spr.play("idle")
    var cs: CollisionShape2D = get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
    if cs != null and cs.shape is RectangleShape2D:
        var rs := cs.shape as RectangleShape2D
        if hitbox_size.x > 0.0 and hitbox_size.y > 0.0:
            rs.size = hitbox_size
        cs.position = hitbox_offset

func _physics_process(delta: float) -> void:
    if not _alive:
        _velocity.y += gravity * delta
        global_position += _velocity * delta
        var viewport := get_viewport().get_visible_rect()
        if global_position.y - 64.0 > float(viewport.size.y) + 200.0:
            queue_free()

func on_player_attack_hit(player: Player) -> void:
    if not _alive:
        return
    _alive = false
    var hitbox := get_node_or_null("Hitbox") as Area2D
    if hitbox:
        hitbox.set_deferred("monitoring", false)
        hitbox.set_deferred("collision_layer", 0)
        hitbox.set_deferred("collision_mask", 0)
    var dir: float = 1.0
    if player and player.global_position.x > global_position.x:
        dir = -1.0
    _velocity = Vector2(knockback_force.x * dir, knockback_force.y)
    call_deferred("_spawn_coins")

func _spawn_coins() -> void:
    if coin_scene == null:
        return
    var main := get_tree().get_root().get_node_or_null("Main")
    var seg := "A"
    if main and main.has_method("get_active_segment_name"):
        var sn := str(main.call("get_active_segment_name"))
        if sn.ends_with("B"):
            seg = "B"
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var count := rng.randi_range(5, 8)
    for i in range(count):
        var coin := coin_scene.instantiate()
        if coin == null:
            continue
        coin.scale = Vector2.ONE * enemy_coin_scale
        coin.z_index = 100
        coin.set("magnet_speed", enemy_coin_magnet_speed)
        coin.set("source_segment", seg)
        coin.set("always_magnet", true)
        var root := get_tree().get_root()
        var main_node := root.get_node_or_null("Main")
        if main_node:
            main_node.add_child(coin)
        else:
            root.add_child(coin)
        var origin := global_position
        var hitbox_node := get_node_or_null("Hitbox") as Node2D
        if hitbox_node:
            var half_h: float = hitbox_size.y * 0.5
            if half_h < 0.0:
                half_h = 0.0
            origin = hitbox_node.global_position + Vector2(0.0, half_h)
        var dir := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.2, 0.2))
        if dir.length_squared() < 0.01:
            dir = Vector2(1.0, 0.0)
        dir = dir.normalized()
        var radius_min: float = 48.0
        var radius_max: float = 96.0
        var radius := rng.randf_range(radius_min, radius_max)
        var offset := dir * radius
        coin.global_position = origin + offset
