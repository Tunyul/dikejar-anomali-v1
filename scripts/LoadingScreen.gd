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
    else:
        _use_remote_content = false
        print("[LoadingScreen] Remote content disabled (base_url empty or node missing)")

    var viewport_size := get_viewport().get_visible_rect().size
    var start_x := player_start_x
    if viewport_size.x > 0.0:
        start_x = -viewport_size.x * 0.2
    var y := player_y
    if viewport_size.y > 0.0:
        y = viewport_size.y * 0.7638889
        y = clampf(y, 220.0, max(viewport_size.y - 64.0, 0.0))
    if player_sprite:
        player_sprite.position = Vector2(start_x + player_offset_from_left, y)
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position = Vector2(player_sprite.position.x + anomaly_offset_x, y)
    set_process(true)

func _process(delta: float) -> void:
    _update_progress(delta)
    _update_characters(delta)
    _check_transition()

func _update_progress(delta: float) -> void:
    if _use_remote_content:
        if has_node("/root/RemoteContent"):
            var remote_node = get_node("/root/RemoteContent")
            progress = remote_node.get_progress()
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
    if load_duration <= 0.01:
        load_duration = 0.01
    if progress < 100.0:
        progress += (delta / load_duration) * 100.0
        if progress > 100.0:
            progress = 100.0
        if loading_label:
            loading_label.text = "%s %d%%" % [tr("Loading"), int(progress)]

func _check_transition() -> void:
    if _transition_started:
        return
    if _use_remote_content and has_node("/root/RemoteContent"):
        var remote_node = get_node("/root/RemoteContent")
        if remote_node.is_failed():
            return
        if not remote_node.is_ready():
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

func _on_remote_progress(p: float) -> void:
    progress = p

func _on_remote_status(s: String) -> void:
    _remote_status = s

func _on_remote_ready() -> void:
    _remote_failed = false

func _on_remote_failed(message: String) -> void:
    _remote_failed = true
    if loading_label:
        loading_label.text = tr(message)

func _update_characters(delta: float) -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    var width := viewport_size.x
    if width <= 0.0:
        width = 1024.0
    if player_sprite:
        player_sprite.position.x += player_speed * delta
        var wrap_limit := width + 120.0
        if player_sprite.position.x > wrap_limit:
            player_sprite.position.x = -120.0
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position.x = player_sprite.position.x + anomaly_offset_x
        anomaly_sprite.position.y = player_sprite.position.y
