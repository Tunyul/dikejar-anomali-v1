extends Control

@export var load_duration: float = 2.5
@export var player_speed: float = 320.0
@export var player_start_x: float = -120.0
@export var player_y: float = 440.0
@export var player_offset_from_left: float = 220.0
@export var anomaly_offset_x: float = -160.0

var progress: float = 0.0
var _transition_started: bool = false

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
        loading_label.text = "Loading 0%"
    var viewport_size := get_viewport().get_visible_rect().size
    var start_x := player_start_x
    if viewport_size.x > 0.0:
        start_x = -viewport_size.x * 0.2
    if player_sprite:
        player_sprite.position = Vector2(start_x + player_offset_from_left, player_y)
    if anomaly_sprite and player_sprite:
        anomaly_sprite.position = Vector2(player_sprite.position.x + anomaly_offset_x, player_y)
    set_process(true)

func _process(delta: float) -> void:
    _update_progress(delta)
    _update_characters(delta)
    _check_transition()

func _update_progress(delta: float) -> void:
    if load_duration <= 0.01:
        load_duration = 0.01
    if progress < 100.0:
        progress += (delta / load_duration) * 100.0
        if progress > 100.0:
            progress = 100.0
        if loading_label:
            loading_label.text = "Loading %d%%" % int(progress)

func _check_transition() -> void:
    if _transition_started:
        return
    if progress < 100.0:
        return
    _transition_started = true
    var target_path := "res://scenes/MainMenu.tscn"
    if Preloader and Preloader.has_method("consume_next_scene"):
        var next_path: String = Preloader.consume_next_scene()
        if next_path != "":
            target_path = next_path
    if Engine.has_singleton("TransitionManager"):
        TransitionManager.play_transition_to_scene(target_path)
    else:
        get_tree().change_scene_to_file(target_path)

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
