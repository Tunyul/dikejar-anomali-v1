extends Node2D

@export var anim_scale: float = 0.5
@export var anim_fps: float = 0.0
@export var hitbox_size: Vector2 = Vector2(44, 44)
@export var hitbox_offset: Vector2 = Vector2(0, -12)

func _ready() -> void:
    var spr: AnimatedSprite2D = $AnimatedSprite2D
    if spr != null:
        if anim_scale > 0.0:
            spr.scale = Vector2(anim_scale, anim_scale)
        if anim_fps > 0.0 and spr.sprite_frames != null:
            spr.sprite_frames.set_animation_speed("idle", anim_fps)
        spr.play("idle")
    var cs: CollisionShape2D = get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
    if cs != null and cs.shape is RectangleShape2D:
        var rs := cs.shape as RectangleShape2D
        if hitbox_size.x > 0.0 and hitbox_size.y > 0.0:
            rs.size = hitbox_size
        cs.position = hitbox_offset
