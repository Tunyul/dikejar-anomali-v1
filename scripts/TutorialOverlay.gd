extends Control

func _ready() -> void:
    visible = false
    var ok := get_node_or_null("VBox/OKButton")
    if ok:
        ok.pressed.connect(_on_ok_pressed)

func _on_ok_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("on_tutorial_dismiss"):
        main.on_tutorial_dismiss()
