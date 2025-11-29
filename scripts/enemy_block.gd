extends Node2D

@export var anim_scale: float = 0.5
@export var anim_fps: float = 0.0

func _ready() -> void:
    var spr: AnimatedSprite2D = $AnimatedSprite2D
    if spr != null:
        if anim_scale > 0.0:
            spr.scale = Vector2(anim_scale, anim_scale)
        if anim_fps > 0.0 and spr.sprite_frames != null:
            spr.sprite_frames.set_animation_speed("idle", anim_fps)
        spr.play("idle")
