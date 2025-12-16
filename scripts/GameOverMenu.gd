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
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("restart_game"):
        visible = false
        main.restart_game()

func _on_continue_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("try_rewarded_continue"):
        main.try_rewarded_continue()
