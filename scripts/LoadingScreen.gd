extends Control

@export var load_duration: float = 2.5
@export var player_speed: float = 320.0
@export var player_start_x: float = -120.0
@export var player_y: float = 440.0
@export var player_offset_from_left: float = 220.0
@export var anomaly_offset_x: float = -160.0
@export var min_visible_time_sec: float = 0.8

var progress: float = 0.0
var _transition_started: bool = false
var _use_remote_content: bool = false
var _remote_failed: bool = false
var _remote_status: String = ""
var _visible_elapsed_sec: float = 0.0
var _viewport_width: float = 1024.0
var _run_line_y: float = 440.0
var _require_deferred_for_target: bool = false
var _warmup_started: bool = false
var _warmup_done: bool = false

@onready var player_sprite: AnimatedSprite2D = $Characters/PlayerSprite
@onready var anomaly_sprite: AnimatedSprite2D = $Characters/AnomalySprite
@onready var loading_label: Label = $LoadingLabel

func _bind_preloader_signals(preloader_node: Node) -> void:
    if preloader_node == null:
        return
    if preloader_node.has_signal("progress_changed"):
        var cb_progress := Callable(self, "_on_preloader_progress")
        if not preloader_node.progress_changed.is_connected(cb_progress):
            preloader_node.progress_changed.connect(cb_progress)
    if preloader_node.has_signal("all_ready"):
        var cb_ready := Callable(self, "_on_preloader_ready")
        if not preloader_node.all_ready.is_connected(cb_ready):
            preloader_node.all_ready.connect(cb_ready)
    if preloader_node.has_signal("deferred_progress_changed"):
        var cb_def := Callable(self, "_on_preloader_deferred_progress")
        if not preloader_node.deferred_progress_changed.is_connected(cb_def):
            preloader_node.deferred_progress_changed.connect(cb_def)
    if preloader_node.has_signal("warmup_ready"):
        var cb_warmup := Callable(self, "_on_preloader_warmup_ready")
        if not preloader_node.warmup_ready.is_connected(cb_warmup):
            preloader_node.warmup_ready.connect(cb_warmup)

func _ready() -> void:
    if player_sprite:
        player_sprite.play("run")
    if anomaly_sprite:
        anomaly_sprite.play("run")
    progress = 0.0
    _visible_elapsed_sec = 0.0
    _warmup_started = false
    _warmup_done = false
    _require_deferred_for_target = _should_wait_for_deferred()
    if loading_label:
        loading_label.text = "%s 0%%" % tr("Loading")
    if has_node("/root/TransitionManager"):
        var tm_node = get_node("/root/TransitionManager")
        if tm_node and tm_node.has_method("warmup_runtime_assets"):
            tm_node.warmup_runtime_assets()

    var remote_node = get_node_or_null("/root/RemoteContent")
    var base_url := str(ProjectSettings.get_setting("remote_content/base_url", ""))

    if remote_node and base_url != "":
        _use_remote_content = true
        remote_node.progress_changed.connect(_on_remote_progress)
        remote_node.status_changed.connect(_on_remote_status)
        remote_node.content_ready.connect(_on_remote_ready)
        remote_node.failed.connect(_on_remote_failed)
        remote_node.start()
        # Preloader tetap dihubungkan untuk tracking progress lokal nanti
        if has_node("/root/Preloader"):
            var preloader_node = get_node("/root/Preloader")
            _bind_preloader_signals(preloader_node)
    else:
        _use_remote_content = false
        print("[LoadingScreen] Remote content disabled (base_url empty or node missing)")
        # Hubungkan ke Preloader jika remote content tidak digunakan
        if has_node("/root/Preloader"):
            var preloader_node = get_node("/root/Preloader")
            _bind_preloader_signals(preloader_node)
            if preloader_node.has_method("start_preloading"):
                preloader_node.start_preloading()

    _connect_viewport_resize()
    _refresh_character_layout()
    set_process(true)

func _process(delta: float) -> void:
    if not is_inside_tree():
        return
    _visible_elapsed_sec += delta
    _update_progress(delta)
    _update_characters(delta)
    _check_transition()

func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)

func _on_viewport_size_changed() -> void:
    _refresh_character_layout()

func _refresh_character_layout() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var visible_size := vp.get_visible_rect().size
    _viewport_width = maxf(visible_size.x, 320.0)
    # Keep sprites near the lower part but always visible on short displays.
    _run_line_y = clampf(visible_size.y * 0.78, 120.0, visible_size.y - 72.0)

    if player_sprite:
        player_sprite.position = Vector2(player_start_x + player_offset_from_left, _run_line_y)
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position = Vector2(player_sprite.position.x + anomaly_offset_x, _run_line_y)

func _update_progress(_delta: float) -> void:
    if _use_remote_content:
        if has_node("/root/RemoteContent"):
            var remote_node = get_node("/root/RemoteContent")
            var status: String = remote_node.get_status()
            if status == "":
                status = "Loading"
            if _remote_status != "":
                status = _remote_status
            if loading_label:
                if _remote_failed:
                    loading_label.text = tr(status)
                else:
                    loading_label.text = "%s %d%%" % [tr(status), int(progress)]
        return

    # Progress untuk preloader diupdate via signal _on_preloader_progress
    if loading_label:
        loading_label.text = "%s %d%%" % [tr("Loading"), int(progress)]

func _on_preloader_progress(p: float) -> void:
    if _require_deferred_for_target:
        progress = p * 85.0
        return
    if _use_remote_content:
        # Jika pakai remote, preloader adalah 50% terakhir (50-100%)
        progress = 50.0 + (p * 50.0)
    else:
        # Jika tidak pakai remote, preloader adalah 0-100%
        progress = p * 100.0

func _on_preloader_ready() -> void:
    if _require_deferred_for_target:
        progress = maxf(progress, 85.0)
        return
    progress = 100.0

func _on_preloader_deferred_progress(p: float) -> void:
    if not _require_deferred_for_target:
        return
    progress = 85.0 + (clampf(p, 0.0, 1.0) * 10.0)
    if p >= 1.0:
        _try_start_warmup()

func _on_preloader_warmup_ready() -> void:
    _warmup_done = true
    if _require_deferred_for_target:
        progress = 100.0

func _on_remote_progress(p: float) -> void:
    # Jika pakai remote, remote content adalah 50% pertama (0-50%)
    progress = p * 0.5

func _should_wait_for_deferred() -> bool:
    if not has_node("/root/Preloader"):
        return false
    var preloader_node = get_node("/root/Preloader")
    if preloader_node == null:
        return false
    if preloader_node.has_method("peek_next_scene"):
        var pending: String = String(preloader_node.peek_next_scene()).strip_edges()
        if pending == "res://scenes/Main.tscn":
            return true
    return false

func _try_start_warmup() -> void:
    if _warmup_started:
        return
    _warmup_started = true
    if has_node("/root/Preloader"):
        var preloader_node = get_node("/root/Preloader")
        if preloader_node and preloader_node.has_method("start_warmup"):
            preloader_node.start_warmup()
            return
    _warmup_done = true
    if _require_deferred_for_target:
        progress = 100.0

func _check_transition() -> void:
    if _transition_started:
        return
    if _visible_elapsed_sec < maxf(min_visible_time_sec, 0.0):
        return

    # Cek RemoteContent jika digunakan
    if _use_remote_content and has_node("/root/RemoteContent"):
        var remote_node = get_node("/root/RemoteContent")
        if remote_node.is_failed():
            return
        if not remote_node.is_ready():
            return

    # Cek Preloader
    if has_node("/root/Preloader"):
        var preloader_node = get_node("/root/Preloader")
        if not preloader_node.is_ready():
            return
        if _require_deferred_for_target:
            if preloader_node.has_method("is_deferred_ready") and not bool(preloader_node.is_deferred_ready()):
                return
            _try_start_warmup()
            if preloader_node.has_method("is_warmup_ready"):
                if not bool(preloader_node.is_warmup_ready()):
                    return
                _warmup_done = true
            if not _warmup_done:
                return

    if progress < 100.0:
        return

    _transition_started = true
    var target_path := "res://scenes/MainMenu.tscn"
    if has_node("/root/Preloader"):
        var preloader_node = get_node("/root/Preloader")
        if preloader_node.has_method("consume_next_scene"):
            var next_path: String = preloader_node.consume_next_scene()
            if next_path != "":
                target_path = next_path
    if has_node("/root/TransitionManager"):
        var tm_node = get_node("/root/TransitionManager")
        tm_node.play_transition_to_scene(target_path)
    else:
        get_tree().change_scene_to_file(target_path)

func _on_remote_status(s: String) -> void:
    _remote_status = s

func _on_remote_ready() -> void:
    _remote_failed = false
    # Setelah remote ready, mulai preloading aset lokal
    if has_node("/root/Preloader"):
        var preloader_node = get_node("/root/Preloader")
        if preloader_node.has_method("start_preloading"):
            preloader_node.start_preloading()

func _on_remote_failed(message: String) -> void:
    _remote_failed = true
    if loading_label:
        loading_label.text = tr(message)

func _update_characters(delta: float) -> void:
    var width := _viewport_width

    if player_sprite:
        player_sprite.position.x += player_speed * delta
        var wrap_limit := width + 120.0
        if player_sprite.position.x > wrap_limit:
            player_sprite.position.x = -120.0
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position.x = player_sprite.position.x + anomaly_offset_x
        anomaly_sprite.position.y = player_sprite.position.y
