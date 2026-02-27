extends Area2D

signal collected(segment: String, currency: String, amount: int)

@export var source_segment: String = ""
@export var currency: String = "coins"
@export var amount: int = 1
@export var tint: Color = Color(1, 1, 1, 1)
@export var is_stack: bool = false
@export var osc_amplitude: float = 12.0
@export var osc_frequency: float = 1.2
@export var anim_fps: float = 12.0
@export var gem_sprite_scale: float = 0.25
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

static var _diamond_frames: SpriteFrames = null

static func _get_diamond_frames() -> SpriteFrames:
    if _diamond_frames != null:
        return _diamond_frames
    var packed := load("res://scenes/Diamond.tscn") as PackedScene
    if packed:
        var inst := packed.instantiate()
        var anim := inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
        if anim and anim.sprite_frames:
            _diamond_frames = anim.sprite_frames
        inst.free()
    if _diamond_frames == null:
        _diamond_frames = SpriteFrames.new()
    return _diamond_frames

func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
    if anim:
        if currency == "gems":
            var has_scene_frames: bool = anim.sprite_frames != null and anim.sprite_frames.has_animation("diamond")
            if has_scene_frames:
                anim.animation = "diamond"
            else:
                anim.sprite_frames = _get_diamond_frames()
                if anim.sprite_frames and anim.sprite_frames.has_animation("diamond"):
                    anim.animation = "diamond"
                elif anim.sprite_frames and anim.sprite_frames.has_animation("spin"):
                    anim.animation = "spin"
                anim.scale = Vector2.ONE * gem_sprite_scale
        else:
            anim.animation = "spin"
        anim.play()
        anim.speed_scale = anim_fps / 12.0
        anim.modulate = tint
    var cs: CollisionShape2D = get_node_or_null("CollisionShape2D")
    var root := get_tree().get_root()
    var _main_node := root.get_node_or_null("Main")
    var pickup_bonus: float = 0.0
    if _main_node and _main_node.has_method("get"):
        pickup_bonus = float(_main_node.get("pickup_range_bonus"))
    if pickup_bonus > 0.0 and cs and cs.shape:
        cs.shape = cs.shape.duplicate()
        if cs.shape is RectangleShape2D:
            var rs := cs.shape as RectangleShape2D
            var add := Vector2(16.0, 16.0) * pickup_bonus
            rs.size = Vector2(maxf(rs.size.x + add.x, 1.0), maxf(rs.size.y + add.y, 1.0))
        elif cs.shape is CircleShape2D:
            var cir := cs.shape as CircleShape2D
            cir.radius = maxf(cir.radius + 8.0 * pickup_bonus, 1.0)
    if override_radius and cs and cs.shape is CircleShape2D:
        var r: float = base_radius_px
        if use_texture_radius and anim and anim.sprite_frames:
            var anim_name := ""
            if anim.sprite_frames.has_animation("spin"):
                anim_name = "spin"
            elif anim.sprite_frames.has_animation("diamond"):
                anim_name = "diamond"
            var tex := anim.sprite_frames.get_frame_texture(anim_name, 0) if not anim_name.is_empty() else null
            if tex:
                r = min(float(tex.get_width()), float(tex.get_height())) * texture_radius_factor
        (cs.shape as CircleShape2D).radius = r
    call_deferred("_capture_base_y")
    body_entered.connect(_on_body_entered)

func reset() -> void:
    _base_y = position.y
    _t = 0.0
    _collected = false
    monitoring = true
    var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
    if anim:
        anim.play()
    visible = true
    # Force immediate base_y capture instead of deferred
    _capture_base_y()

func _capture_base_y() -> void:
    _base_y = position.y

func _find_player() -> Node2D:
    var root := get_tree().get_root()
    var _main_node := root.get_node_or_null("Main")
    if _main_node:
        var from_main := _main_node.get_node_or_null("Player") as Node2D
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
    if not is_inside_tree():
        return
    _t += delta
    var root := get_tree().get_root()
    var _main_node := root.get_node_or_null("Main")
    var mag: bool = always_magnet
    if _main_node and _main_node.has_method("get") and not mag:
        mag = bool(_main_node.get("magnet_enabled"))
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
    TransitionManager.play_sfx(&"coin")
    var a := amount
    if a <= 0:
        a = 1
    var c := currency
    if c.is_empty():
        c = "coins"
    collected.emit(source_segment, c, a)
    queue_free()
