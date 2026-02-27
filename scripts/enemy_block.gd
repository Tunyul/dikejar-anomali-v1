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
@export var enemy_gem_drop_chance: float = 0.08
@export var enemy_gem_amount: int = 1
@export var enemy_gem_tint: Color = Color(0.35, 0.8, 1.0, 1.0)
@export var coin_scene: PackedScene = preload("res://scenes/Coin.tscn")
@export var diamond_scene: PackedScene = preload("res://scenes/Diamond.tscn")

var _velocity: Vector2 = Vector2.ZERO
var _alive: bool = true

func _ready() -> void:
    var spr: AnimatedSprite2D = $AnimatedSprite2D
    if spr != null:
        # Jika parent (Ground) memiliki skala (misal 0.5), kita perlu mengimbangi
        # agar visual tetap terlihat sesuai target anim_scale relatif terhadap WORLD.
        # Namun untuk saat ini kita pastikan local scale sprite konsisten dulu.
        if anim_scale > 0.0:
            spr.scale = Vector2(anim_scale, anim_scale)

        # Hitbox juga perlu disesuaikan skalanya jika anim_scale berubah
        var hitbox := get_node_or_null("Hitbox") as Area2D
        if hitbox:
            hitbox.scale = Vector2.ONE # Reset ke 1.0 agar tidak terpengaruh scale sprite lama

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
    call_deferred("_on_enemy_killed")

func _on_enemy_killed() -> void:
    TransitionManager.play_sfx(&"enemy_kill")
    var root := get_tree().get_root()
    var _main_node := root.get_node_or_null("Main")
    if _main_node and _main_node.has_method("on_enemy_killed_by_player"):
        _main_node.call("on_enemy_killed_by_player")
    _spawn_coins()

func _spawn_coins() -> void:
    if coin_scene == null:
        return
    var _main_node := get_tree().get_root().get_node_or_null("Main")
    var seg := "A"
    if _main_node and _main_node.has_method("get_active_segment_name"):
        var sn := str(_main_node.call("get_active_segment_name"))
        if sn.ends_with("B"):
            seg = "B"
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var count := rng.randi_range(5, 8)
    for i in range(count):
        _spawn_pickup(seg, rng, false)
    if enemy_gem_drop_chance > 0.0 and rng.randf() < enemy_gem_drop_chance:
        _spawn_pickup(seg, rng, true)

func _spawn_pickup(seg: String, rng: RandomNumberGenerator, is_gem: bool) -> void:
    if coin_scene == null:
        return
    var scene_to_spawn: PackedScene = coin_scene
    if is_gem and diamond_scene != null:
        scene_to_spawn = diamond_scene
    var pickup := scene_to_spawn.instantiate()
    if pickup == null:
        return
    pickup.scale = Vector2.ONE * _get_coin_scale_from_ground()
    pickup.z_index = 100
    pickup.set("magnet_speed", enemy_coin_magnet_speed)
    pickup.set("source_segment", seg)
    pickup.set("always_magnet", true)
    if is_gem:
        var a := enemy_gem_amount
        if a <= 0:
            a = 1
        pickup.set("currency", "gems")
        pickup.set("amount", a)
        pickup.set("tint", enemy_gem_tint)
    var root := get_tree().get_root()
    var main_node := root.get_node_or_null("Main")
    if main_node:
        main_node.add_child(pickup)
    else:
        root.add_child(pickup)
    if main_node and main_node.has_method("on_coin_collected") and pickup.has_signal("collected"):
        pickup.collected.connect(Callable(main_node, "on_coin_collected"))
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
    pickup.global_position = origin + offset

func _get_coin_scale_from_ground() -> float:
    var root := get_tree().get_root()
    var _main_node := root.get_node_or_null("Main")
    if _main_node != null:
        var ground := _main_node.get_node_or_null("Ground")
        if ground != null:
            if ground.has_method("get"):
                var value = ground.get("coin_scale")
                if typeof(value) == TYPE_FLOAT:
                    return float(value)
    return enemy_coin_scale
