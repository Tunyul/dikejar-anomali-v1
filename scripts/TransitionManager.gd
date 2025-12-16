extends CanvasLayer

var _overlay: ColorRect
var _tween_active: bool = false
var _cloud_layer: Control
var _rng := RandomNumberGenerator.new()
@export var transition_duration: float = 1.2
@export var cloud_count: int = 18
@export var row_height_px: float = 96.0
@export var col_width_px: float = 160.0
@export var min_rows: int = 6
@export var min_cols: int = 8
@export var scale_min: float = 0.8
@export var scale_max: float = 1.4
@export var margin_min: float = 100.0
@export var margin_max: float = 400.0
@export var delay_factor: float = 0.35
@export var direction_mode: int = 0
@export var preview_in_editor: bool = false: set = _set_preview_enabled
@export var preview_use_sprite: bool = true
@export var live_update_in_editor: bool = false
@export var transition_mode: int = 1
var _last_preview_sig: String = ""
var _cloud_textures := [
    load("res://assets/Background/png/Clouds/512x512/Cloud_1.png"),
    load("res://assets/Background/png/Clouds/512x512/Cloud_2.png"),
    load("res://assets/Background/png/Clouds/256x256/Cloud_1.png"),
    load("res://assets/Background/png/Clouds/256x256/Cloud_2.png"),
    load("res://assets/Background/png/Clouds/128x128/Cloud_1.png"),
    load("res://assets/Background/png/Clouds/128x128/Cloud_2.png")
]

func _ready() -> void:
    layer = 1000
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 1)
    _overlay.modulate.a = 0.0
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_overlay)
    if Engine.is_editor_hint() and preview_in_editor and _is_transition_scene_open():
        _spawn_preview_clouds()
        _last_preview_sig = _make_preview_signature()

func fade_out(duration: float = 0.5) -> void:
    var t := create_tween()
    _tween_active = true
    t.tween_property(_overlay, "modulate:a", 1.0, duration)
    await t.finished
    _tween_active = false

func fade_in(duration: float = 0.5) -> void:
    var t := create_tween()
    _tween_active = true
    t.tween_property(_overlay, "modulate:a", 0.0, duration)
    await t.finished
    _tween_active = false

func fade_to_scene(scene_path: String, duration: float = 0.5) -> void:
    var packed_scene: PackedScene = null
    if Engine.has_singleton("Preloader"):
        var p := Preloader
        if p and p.has_method("get_packed"):
            packed_scene = p.get_packed(scene_path)
    if packed_scene == null:
        var res := load(scene_path)
        if res is PackedScene:
            packed_scene = res
    await fade_out(duration)
    if packed_scene != null:
        var err := get_tree().change_scene_to_packed(packed_scene)
        if err != OK:
            get_tree().change_scene_to_file(scene_path)
    else:
        get_tree().change_scene_to_file(scene_path)
    await fade_in(duration)

func cloud_sweep_to_scene(scene_path: String, duration: float = -1.0, count: int = -1) -> void:
    _rng.randomize()
    var vs := get_viewport().get_visible_rect().size
    _cloud_layer = Control.new()
    _cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    _cloud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _cloud_layer.modulate.a = 1.0
    add_child(_cloud_layer)
    var packed_scene: PackedScene = null
    if Engine.has_singleton("Preloader"):
        var p := Preloader
        if p and p.has_method("get_packed"):
            packed_scene = p.get_packed(scene_path)
    if packed_scene == null:
        var res := load(scene_path)
        if res is PackedScene:
            packed_scene = res
    var dur: float = (transition_duration if duration <= 0.0 else duration)
    var base_count: int = (cloud_count if count <= 0 else count)
    var rows: int = max(min_rows, int(ceil(vs.y / row_height_px)))
    var cols: int = max(min_cols, int(ceil(vs.x / col_width_px)))
    var grid_total: int = rows * cols
    var total: int = min(base_count, grid_total)
    total = int(clamp(total, 16.0, 48.0))
    for i in range(total):
        var tx: Texture2D = _cloud_textures[_rng.randi_range(0, _cloud_textures.size() - 1)]
        var cloud_rect := TextureRect.new()
        cloud_rect.texture = tx
        cloud_rect.stretch_mode = TextureRect.STRETCH_SCALE
        var base_w := tx.get_width()
        var base_h := tx.get_height()
        var scale_factor: float = _rng.randf_range(scale_min, scale_max)
        cloud_rect.custom_minimum_size = Vector2(base_w * scale_factor, base_h * scale_factor)
        var dir_rand := (_rng.randi() % 2) == 0
        var start_left := (direction_mode == 0 and dir_rand) or (direction_mode == 1)
        var start_x := -base_w * scale_factor - _rng.randf_range(margin_min, margin_max)
        var end_x := vs.x + base_w * scale_factor + _rng.randf_range(margin_min, margin_max)
        if not start_left:
            start_x = vs.x + base_w * scale_factor + _rng.randf_range(margin_min, margin_max)
            end_x = -base_w * scale_factor - _rng.randf_range(margin_min, margin_max)
        var row_index: int = i % rows
        var row_h: float = vs.y / float(rows)
        var y: float = clamp(row_h * row_index + _rng.randf_range(0.0, row_h - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
        cloud_rect.position = Vector2(start_x, y)
        _cloud_layer.add_child(cloud_rect)
        var delay: float = _rng.randf_range(0.0, dur * delay_factor)
        var t := create_tween()
        t.tween_property(cloud_rect, "position:x", end_x, dur).set_delay(delay)
    await get_tree().create_timer(dur + 0.4).timeout
    await fade_out(0.2)
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
    if packed_scene != null:
        get_tree().change_scene_to_packed(packed_scene)
    else:
        get_tree().change_scene_to_file(scene_path)
    await get_tree().create_timer(0.01).timeout
    await fade_in(0.2)

func play_transition_to_scene(scene_path: String) -> void:
    var use_clouds := true
    if transition_mode == 1:
        use_clouds = false
    elif transition_mode == 2:
        use_clouds = cloud_count <= 32
    if not Engine.is_editor_hint():
        use_clouds = false
    if use_clouds:
        await cloud_sweep_to_scene(scene_path)
    else:
        await fade_to_scene(scene_path, 0.4)

func _spawn_preview_clouds() -> void:
    _rng.randomize()
    var vs: Vector2 = get_viewport().get_visible_rect().size
    if vs.x <= 1.0 or vs.y <= 1.0:
        var vw := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
        var vh := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
        vs = Vector2(float(vw), float(vh))
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
    _cloud_layer = Control.new()
    _cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_cloud_layer)
    var rows: int = max(min_rows, int(ceil(vs.y / row_height_px)))
    var cols: int = max(min_cols, int(ceil(vs.x / col_width_px)))
    var total: int = min(64, rows * cols)
    for i in range(total):
        var tx: Texture2D = _cloud_textures[_rng.randi_range(0, _cloud_textures.size() - 1)]
        var base_w := tx.get_width()
        var base_h := tx.get_height()
        var scale_factor: float = _rng.randf_range(scale_min, scale_max)
        if preview_use_sprite:
            var spr := Sprite2D.new()
            spr.texture = tx
            spr.centered = false
            spr.scale = Vector2(scale_factor, scale_factor)
            var row_index: int = i % rows
            var row_h: float = vs.y / float(rows)
            var y: float = clamp(row_h * row_index + _rng.randf_range(0.0, row_h - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
            var x: float = _rng.randf_range(0.0, vs.x - base_w * scale_factor)
            spr.position = Vector2(x, y)
            _cloud_layer.add_child(spr)
        else:
            var cloud_rect := TextureRect.new()
            cloud_rect.texture = tx
            cloud_rect.stretch_mode = TextureRect.STRETCH_SCALE
            cloud_rect.custom_minimum_size = Vector2(base_w * scale_factor, base_h * scale_factor)
            var row_index2: int = i % rows
            var row_h2: float = vs.y / float(rows)
            var y2: float = clamp(row_h2 * row_index2 + _rng.randf_range(0.0, row_h2 - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
            var x2: float = _rng.randf_range(0.0, vs.x - base_w * scale_factor)
            cloud_rect.position = Vector2(x2, y2)
            _cloud_layer.add_child(cloud_rect)

func _clear_preview_clouds() -> void:
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
        _cloud_layer = null

func _set_preview_enabled(v: bool) -> void:
    preview_in_editor = v
    if Engine.is_editor_hint():
        if preview_in_editor and _is_transition_scene_open():
            _spawn_preview_clouds()
            _last_preview_sig = _make_preview_signature()
        else:
            _clear_preview_clouds()

func _make_preview_signature() -> String:
    return str(transition_duration) + ":" + str(cloud_count) + ":" + str(row_height_px) + ":" + str(col_width_px) + ":" + str(min_rows) + ":" + str(min_cols) + ":" + str(scale_min) + ":" + str(scale_max) + ":" + str(margin_min) + ":" + str(margin_max) + ":" + str(delay_factor) + ":" + str(direction_mode) + ":" + str(preview_use_sprite)

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() and preview_in_editor and live_update_in_editor and _is_transition_scene_open():
        var sig := _make_preview_signature()
        if sig != _last_preview_sig:
            _clear_preview_clouds()
            _spawn_preview_clouds()
            _last_preview_sig = sig

func _is_transition_scene_open() -> bool:
    var cs := get_tree().get_current_scene()
    if cs == null:
        return false
    var path := cs.get_scene_file_path()
    return path.ends_with("/scenes/TransitionManager.tscn")
