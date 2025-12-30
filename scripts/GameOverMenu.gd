extends Control

@onready var score_label: Label = get_node_or_null("VBox/ScoreLabel")
@onready var distance_label: Label = get_node_or_null("VBox/DistanceLabel")
@onready var confirm_dialog: ConfirmationDialog = get_node_or_null("ConfirmDialog")

var _pending_action: String = ""
var _final_score: int = 0
var _final_distance: float = 0.0

func _ready() -> void:
    if name == "GameOverMenu":
        visible = false
    else:
        visible = true
    var retry := get_node_or_null("VBox/ButtonRow/RetryButton")
    var cont := get_node_or_null("VBox/ButtonRow/ContinueButton")
    var bonus := get_node_or_null("VBox/ButtonRow/BonusContinueButton")
    if confirm_dialog:
        confirm_dialog.confirmed.connect(_on_confirm_dialog_confirmed)
    if retry:
        retry.pressed.connect(_on_retry_pressed)
    if cont:
        cont.pressed.connect(_on_continue_pressed)
    if bonus:
        bonus.pressed.connect(_on_bonus_continue_pressed)

func show_game_over(final_score: int, final_distance: float) -> void:
    _final_score = final_score
    _final_distance = final_distance
    _pending_action = ""
    if score_label:
        score_label.text = "Score: " + str(final_score)
    if distance_label:
        distance_label.text = "Distance: " + str(int(round(final_distance)))
    visible = true

func _on_retry_pressed() -> void:
    if confirm_dialog == null:
        visible = false
        _pending_action = ""
        if Preloader and Preloader.has_method("set_next_scene"):
            Preloader.set_next_scene("res://scenes/Main.tscn")
        await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
        return
    _pending_action = "retry"
    confirm_dialog.dialog_text = "Mulai dari awal?\nProgress run ini akan direset."
    confirm_dialog.popup_centered()

func _on_continue_pressed() -> void:
    if confirm_dialog == null:
        visible = false
        _pending_action = ""
        if Preloader and Preloader.has_method("set_next_scene"):
            Preloader.set_next_scene("res://scenes/MainMenu.tscn")
        await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
        return
    _pending_action = "home"
    confirm_dialog.dialog_text = "Kembali ke menu utama?\nRun ini akan diakhiri."
    confirm_dialog.popup_centered()

func _on_bonus_continue_pressed() -> void:
    if confirm_dialog == null:
        var main := get_tree().get_root().get_node_or_null("Main")
        if main and main.has_method("try_rewarded_continue"):
            visible = false
            _pending_action = ""
            main.try_rewarded_continue()
        return
    _pending_action = "bonus"
    confirm_dialog.dialog_text = "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini."
    confirm_dialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
    match _pending_action:
        "retry":
            visible = false
            _pending_action = ""
            if Preloader and Preloader.has_method("set_next_scene"):
                Preloader.set_next_scene("res://scenes/Main.tscn")
            await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
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
