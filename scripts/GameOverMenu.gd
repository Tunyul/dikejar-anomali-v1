extends Control

func _ready() -> void:
    visible = false
    var retry := get_node_or_null("VBox/RetryButton")
    var cont := get_node_or_null("VBox/ContinueButton")
    if retry:
        retry.pressed.connect(_on_retry_pressed)
    if cont:
        cont.pressed.connect(_on_continue_pressed)

func _on_retry_pressed() -> void:
    visible = false
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/Main.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_continue_pressed() -> void:
    visible = false
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/MainMenu.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
