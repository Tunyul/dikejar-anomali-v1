@tool
extends CharacterBody2D

@export var offset_x: float = 24.0
@export var follow_speed_y: float = 400.0
@export var entry_duration_sec: float = 0.8
@export var entry_offset_extra: float = -64.0
@export var hover_height_px: float = 20.0
@export var collision_size: Vector2 = Vector2(64, 64)

var _player: Node2D
var _camera: Camera2D
var _entry_timer: float = -1.0
var _has_caught_player: bool = false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var ground_ray: RayCast2D = $GroundRay

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    var main := get_tree().get_root().get_node_or_null("Main")
    if main:
        _player = main.get_node_or_null("Player")
        _camera = main.get_node_or_null("Camera2D")
    collision_layer = 4
    collision_mask = 1
    if collider:
        var rect := RectangleShape2D.new()
        rect.size = collision_size
        collider.shape = rect
    if ground_ray:
        ground_ray.enabled = true
        ground_ray.collision_mask = 1
        ground_ray.target_position = Vector2(0, 200)
    if _player:
        global_position.y = _player.global_position.y
    _ensure_sprite_frames()
    _ensure_playing()

func _process(delta: float) -> void:
    if not is_inside_tree():
        return
    if Engine.is_editor_hint():
        return
    if _camera == null:
        return
    var vp := get_viewport().get_visible_rect().size
    var left_world := _camera.position.x - vp.x * 0.5
    var extra := 0.0
    if _entry_timer >= 0.0:
        var denom: float = entry_duration_sec
        if denom < 0.0001:
            denom = 0.0001
        var p: float = clamp(_entry_timer / denom, 0.0, 1.0)
        extra = lerp(entry_offset_extra, 0.0, p)
        _entry_timer += delta
    global_position.x = left_world + offset_x + extra
    if _player != null:
        var ty := _player.global_position.y
        var gy := ty
        if ground_ray and ground_ray.is_enabled():
            ground_ray.global_position = Vector2(global_position.x, global_position.y)
            if ground_ray.is_colliding():
                var cp := ground_ray.get_collision_point()
                gy = min(ty, cp.y - hover_height_px)
        var dy := gy - global_position.y
        var ms := follow_speed_y * delta
        if abs(dy) <= ms:
            global_position.y = gy
        else:
            global_position.y += sign(dy) * ms
    if _player != null and not _has_caught_player:
        var dx: float = _player.global_position.x - global_position.x
        var dy2: float = absf(_player.global_position.y - global_position.y)
        if absf(dx) < collision_size.x * 0.5 and dy2 < collision_size.y * 0.75:
            if _player.has_method("on_anomaly_contact"):
                _player.on_anomaly_contact()
            _has_caught_player = true

func start_appear() -> void:
    if Engine.is_editor_hint():
        return
    _entry_timer = 0.0
    _has_caught_player = false
    if _player != null:
        global_position.y = _player.global_position.y
    var vp := get_viewport().get_visible_rect().size
    var left_world := 0.0
    if _camera != null:
        left_world = _camera.position.x - vp.x * 0.5
    global_position.x = left_world + offset_x + entry_offset_extra
    _ensure_playing()

func _ensure_sprite_frames() -> void:
    if sprite == null:
        return
    var need := sprite.sprite_frames == null or sprite.sprite_frames.get_animation_names().is_empty()
    if not need:
        return
    var tex: Texture2D = ResourceLoader.load(sprite_sheet_path) as Texture2D
    if tex == null:
        return
    var sf := SpriteFrames.new()
    sf.add_animation(animation_name)
    sf.set_animation_loop(animation_name, true)
    var w: int = tex.get_width()
    var h: int = tex.get_height()
    var cnt: int = max(frame_count, 1)
    var fw_exact: float = float(w) / float(cnt)
    for i in range(cnt):
        var start_x: int = int(round(float(i) * fw_exact))
        var end_x: int = int(round(float(i + 1) * fw_exact))
        var frame_w: int = max(1, end_x - start_x)
        var at := AtlasTexture.new()
        at.atlas = tex
        at.region = Rect2(start_x, 0, frame_w, h)
        sf.add_frame(animation_name, at)
    sprite.sprite_frames = sf
    sprite.play(animation_name)
    if animation_fps > 0.0:
        sprite.speed_scale = animation_fps / 12.0

func _ensure_playing() -> void:
    if sprite == null:
        return
    if sprite.sprite_frames == null:
        return
    var names := sprite.sprite_frames.get_animation_names()
    if names.size() == 0:
        return
    var anim: String = animation_name
    if not names.has(animation_name):
        anim = names[0]
    if sprite.animation != anim or not sprite.is_playing():
        sprite.play(anim)
    if animation_fps > 0.0:
        sprite.speed_scale = animation_fps / 12.0
@export var sprite_sheet_path: String = "res://assets/enemy/sprite-256px-36.png"
@export var frame_count: int = 36
@export var animation_name: String = "run"
@export var animation_fps: float = 12.0
