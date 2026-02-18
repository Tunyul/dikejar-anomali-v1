extends Control

@export var load_duration: float = 2.5
@export var player_speed: float = 320.0
@export var player_start_x: float = -120.0
@export var player_y: float = 440.0
@export var player_offset_from_left: float = 220.0
@export var anomaly_offset_x: float = -160.0

var progress: float = 0.0
var _transition_started: bool = false
var _use_remote_content: bool = false
var _remote_failed: bool = false
var _remote_status: String = ""

@onready var player_sprite: AnimatedSprite2D = $Characters/PlayerSprite
@onready var anomaly_sprite: AnimatedSprite2D = $Characters/AnomalySprite
@onready var loading_label: Label = $LoadingLabel

func _ready() -> void:
    if player_sprite:
        player_sprite.play("run")
    if anomaly_sprite:
        anomaly_sprite.play("run")
    progress = 0.0
    if loading_label:
        loading_label.text = "%s 0%%" % tr("Loading")

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
            preloader_node.progress_changed.connect(_on_preloader_progress)
            preloader_node.all_ready.connect(_on_preloader_ready)
    else:
        _use_remote_content = false
        print("[LoadingScreen] Remote content disabled (base_url empty or node missing)")
        # Hubungkan ke Preloader jika remote content tidak digunakan
        if has_node("/root/Preloader"):
            var preloader_node = get_node("/root/Preloader")
            preloader_node.progress_changed.connect(_on_preloader_progress)
            preloader_node.all_ready.connect(_on_preloader_ready)
            if preloader_node.has_method("start_preloading"):
                preloader_node.start_preloading()

    var start_x := player_start_x
    var y := player_y

    if player_sprite:
        player_sprite.position = Vector2(start_x + player_offset_from_left, y)
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position = Vector2(player_sprite.position.x + anomaly_offset_x, y)
    set_process(true)

func _process(delta: float) -> void:
    _update_progress(delta)
    _update_characters(delta)
    _check_transition()

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
    if _use_remote_content:
        # Jika pakai remote, preloader adalah 50% terakhir (50-100%)
        progress = 50.0 + (p * 50.0)
    else:
        # Jika tidak pakai remote, preloader adalah 0-100%
        progress = p * 100.0

func _on_preloader_ready() -> void:
    progress = 100.0

func _on_remote_progress(p: float) -> void:
    # Jika pakai remote, remote content adalah 50% pertama (0-50%)
    progress = p * 0.5

func _check_transition() -> void:
    if _transition_started:
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
    var width := 1024.0

    if player_sprite:
        player_sprite.position.x += player_speed * delta
        var wrap_limit := width + 120.0
        if player_sprite.position.x > wrap_limit:
            player_sprite.position.x = -120.0
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position.x = player_sprite.position.x + anomaly_offset_x
        anomaly_sprite.position.y = player_sprite.position.y
