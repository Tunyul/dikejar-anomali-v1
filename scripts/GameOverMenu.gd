extends Control

@onready var score_label: Label = get_node_or_null("VBox/ScoreLabel")
@onready var distance_label: Label = get_node_or_null("VBox/DistanceLabel")
@onready var confirm_panel: Control = get_node_or_null("ConfirmPanel")
@onready var confirm_message: Label = get_node_or_null("ConfirmPanel/Message")
@onready var confirm_yes: BaseButton = get_node_or_null("ConfirmPanel/Buttons/YesButton")
@onready var confirm_no: BaseButton = get_node_or_null("ConfirmPanel/Buttons/NoButton")

var _pending_action: String = ""
var _final_score: int = 0
var _final_distance: float = 0.0

func _ready() -> void:
    if name == "GameOverMenu":
        visible = false
    else:
        visible = true
    if confirm_message:
        confirm_message.add_theme_color_override("font_color", Color(0, 0, 0, 1))
    var retry := get_node_or_null("VBox/ButtonRow/RetryButton")
    var cont := get_node_or_null("VBox/ButtonRow/ContinueButton")
    var bonus := get_node_or_null("VBox/ButtonRow/BonusContinueButton")
    if retry:
        retry.pressed.connect(_on_retry_pressed)
    if cont:
        cont.pressed.connect(_on_continue_pressed)
    if bonus:
        bonus.pressed.connect(_on_bonus_continue_pressed)
    if confirm_yes:
        confirm_yes.pressed.connect(_on_confirm_yes_pressed)
    if confirm_no:
        confirm_no.pressed.connect(_on_confirm_no_pressed)

func show_game_over(final_score: int, final_distance: float) -> void:
    _final_score = final_score
    _final_distance = final_distance
    _pending_action = ""
    if score_label:
        score_label.text = "Score: " + str(final_score)
    if distance_label:
        distance_label.text = "Distance: " + str(int(round(final_distance)))
    if confirm_panel:
        confirm_panel.visible = false
    visible = true

func _on_retry_pressed() -> void:
    visible = false
    _pending_action = ""
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/Main.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_continue_pressed() -> void:
    _pending_action = "home"
    if confirm_panel and confirm_message:
        confirm_message.text = "Kembali ke menu utama?\nRun ini akan diakhiri."
        confirm_panel.visible = true

func _on_bonus_continue_pressed() -> void:
    _pending_action = "bonus"
    if confirm_panel and confirm_message:
        confirm_message.text = "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini."
        confirm_panel.visible = true

func _on_confirm_yes_pressed() -> void:
    match _pending_action:
        "home":
            visible = false
            _pending_action = ""
            if Preloader and Preloader.has_method("set_next_scene"):
                Preloader.set_next_scene("res://scenes/MainMenu.tscn")
            await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
        "bonus":
            var main := get_tree().get_root().get_node_or_null("Main")
            if main and main.has_method("try_rewarded_continue"):
                visible = false
                _pending_action = ""
                main.try_rewarded_continue()
    if confirm_panel:
        confirm_panel.visible = false

func _on_confirm_no_pressed() -> void:
    _pending_action = ""
    if confirm_panel:
        confirm_panel.visible = false
