extends Control

signal restart_requested

@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton

func _ready() -> void:
    if restart_button:
        restart_button.pressed.connect(_on_restart)

func show_screen() -> void:
    set_visible(true)

func hide_screen() -> void:
    set_visible(false)

func _on_restart() -> void:
    emit_signal("restart_requested")