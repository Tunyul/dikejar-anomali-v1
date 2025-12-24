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
@export var always_magnet: bool = false

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

func _find_player() -> Node2D:
    var root := get_tree().get_root()
    var main := root.get_node_or_null("Main")
    if main:
        var from_main := main.get_node_or_null("Player") as Node2D
        if from_main:
            return from_main
    for child in root.get_children():
        if child is Node2D and child.name == "Player":
            return child
        if child is Node and child.has_node("Player"):
            var nested := child.get_node_or_null("Player") as Node2D
            if nested:
                return nested
    return null

func _physics_process(delta: float) -> void:
    _t += delta
    var root := get_tree().get_root()
    var main := root.get_node_or_null("Main")
    var mag: bool = always_magnet
    if main and main.has_method("get") and not mag:
        mag = bool(main.get("magnet_enabled"))
    if not mag:
        position.y = _base_y + abs(sin(_t * TAU * osc_frequency)) * osc_amplitude
        return
    var pl := _find_player()
    if pl == null:
        return
    var pw := pl.global_position
    var cw := global_position
    var dx := pw.x - cw.x
    var dy := pw.y - cw.y
    var dist: float = sqrt(dx * dx + dy * dy)
    if not always_magnet and dist >= magnet_radius:
        return
    var step: float = magnet_speed * delta
    if dist <= step:
        global_position = pw
    else:
        var safe_dist: float = dist
        if safe_dist < 0.001:
            safe_dist = 0.001
        var dirx: float = dx / safe_dist
        var diry: float = dy / safe_dist
        global_position.x += dirx * step
        global_position.y += diry * step

func _on_body_entered(_body: Node) -> void:
    if _collected:
        return
    _collected = true
    set_deferred("monitoring", false)
    collected.emit(source_segment)
    queue_free()
