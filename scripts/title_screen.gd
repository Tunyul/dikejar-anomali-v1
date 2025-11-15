extends Control

@export var title_text: String = "DIKEJAR ANOMALI"
@export var start_button_text: String = "MULAI"
@export var quit_button_text: String = "KELUAR"

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

signal start_game_requested
signal quit_game_requested

func _ready() -> void:
    if title_label:
        title_label.text = title_text
    
    if start_button:
        start_button.text = start_button_text
        start_button.pressed.connect(_on_start_pressed)
    
    if quit_button:
        quit_button.text = quit_button_text
        quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
    emit_signal("start_game_requested")
    hide()

func _on_quit_pressed() -> void:
    emit_signal("quit_game_requested")

func show_title() -> void:
    show()
    if start_button:
        start_button.grab_focus()

func hide_title() -> void:
    hide()