extends Area2D

signal collected(segment: String)

@export var source_segment: String = ""
@export var tint: Color = Color(1, 1, 1, 1)
@export var is_stack: bool = false
@export var osc_amplitude: float = 12.0
@export var osc_frequency: float = 1.2
@export var anim_fps: float = 12.0
@export var magnet_speed: float = 160.0
@export var magnet_radius: float = 180.0
@export var override_radius: bool = false
@export var use_texture_radius: bool = false
@export var texture_radius_factor: float = 0.35
@export var base_radius_px: float = 14.0

var _base_y: float = 0.0
var _t: float = 0.0
var _collected: bool = false

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
    if anim:
        anim.animation = "spin"
        anim.play()
        anim.speed_scale = anim_fps / 12.0
        anim.modulate = tint
    var cs: CollisionShape2D = get_node_or_null("CollisionShape2D")
    if override_radius and cs and cs.shape is CircleShape2D:
        var r: float = base_radius_px
        if use_texture_radius and anim and anim.sprite_frames and anim.sprite_frames.has_animation("spin"):
            var tex := anim.sprite_frames.get_frame_texture("spin", 0)
            if tex:
                r = min(float(tex.get_width()), float(tex.get_height())) * texture_radius_factor
        (cs.shape as CircleShape2D).radius = r
    call_deferred("_capture_base_y")
    body_entered.connect(_on_body_entered)

func _capture_base_y() -> void:
    _base_y = position.y

func _physics_process(delta: float) -> void:
    _t += delta
    position.y = _base_y + abs(sin(_t * TAU * osc_frequency)) * osc_amplitude
    var main := get_tree().get_root().get_node_or_null("Main")
    if main:
        var mag := false
        if main.has_method("get"):
            mag = bool(main.get("magnet_enabled"))
        if mag:
            var pl := main.get_node_or_null("Player")
            if pl and pl is Node2D:
                var pw := (pl as Node2D).global_position
                var cw := global_position
                var dx := pw.x - cw.x
                var dy := pw.y - cw.y
                var dist := sqrt(dx * dx + dy * dy)
                if dist < magnet_radius:
                    var step := magnet_speed * delta
                    if dist <= step:
                        global_position = pw
                    else:
                        var dirx: float = dx / max(dist, 0.001)
                        var diry: float = dy / max(dist, 0.001)
                        global_position.x += dirx * step
                        global_position.y += diry * step

func _on_body_entered(_body: Node) -> void:
    if _collected:
        return
    _collected = true
    set_deferred("monitoring", false)
    collected.emit(source_segment)
    queue_free()
