extends Control

@onready var _score_label: Label = %ScoreLabel
@onready var _distance_label: Label = %DistanceLabel
@onready var _confirm_panel: Control = %ConfirmPanel if has_node("%ConfirmPanel") else null
@onready var _confirm_message: Label = _confirm_panel.get_node("%Message") if _confirm_panel and _confirm_panel.has_node("%Message") else null
@onready var _confirm_yes: BaseButton = _confirm_panel.get_node("%YesButton") if _confirm_panel and _confirm_panel.has_node("%YesButton") else null
@onready var _confirm_no: BaseButton = _confirm_panel.get_node("%NoButton") if _confirm_panel and _confirm_panel.has_node("%NoButton") else null
@onready var _card_bg: Control = %CardBackground
@onready var _title: Control = %Title
@onready var _vbox: Control = %VBox
@onready var _retry_button: BaseButton = %RetryButton
@onready var _continue_button: BaseButton = %ContinueButton
@onready var _bonus_continue_button: BaseButton = %BonusContinueButton

var _pending_action: String = ""
var _final_score: int = 0
var _final_distance: float = 0.0
var _last_viewport_size: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
    if name == "GameOverMenu":
        visible = false
    else:
        visible = true
    if _confirm_message:
        _confirm_message.add_theme_color_override("font_color", Color(0.2, 0.1, 0, 1))
        _confirm_message.add_theme_font_size_override("font_size", 24)

    if _retry_button:
        _retry_button.pressed.connect(_on_retry_pressed)
    if _continue_button:
        _continue_button.pressed.connect(_on_continue_pressed)
    if _bonus_continue_button:
        _bonus_continue_button.pressed.connect(_on_bonus_continue_pressed)
    if _confirm_yes:
        _confirm_yes.pressed.connect(_on_confirm_yes_pressed)
    if _confirm_no:
        _confirm_no.pressed.connect(_on_confirm_no_pressed)

    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        var title_label := _title as Label
        if title_label:
            title_label.add_theme_font_override("font", title_font)
            title_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
            title_label.add_theme_constant_override("outline_size", 3)
            title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
            title_label.add_theme_font_size_override("font_size", 44)

    _connect_viewport_resize()


func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)


func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)
    call_deferred("_on_viewport_size_changed")


func _on_viewport_size_changed() -> void:
    var vp := get_viewport().get_visible_rect().size
    var vp_i := Vector2i(int(vp.x), int(vp.y))
    if vp_i == _last_viewport_size:
        return
    _last_viewport_size = vp_i
    _apply_responsive_layout(vp)


func _apply_responsive_layout(vp: Vector2) -> void:
    if _card_bg == null or _vbox == null or _title == null:
        return
    var safe := Rect2(Vector2.ZERO, vp)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))

    var margin := 16.0
    var safe_size := Vector2(maxf(safe.size.x - margin * 2.0, 1.0), maxf(safe.size.y - margin * 2.0, 1.0))
    var base_size := Vector2(686.0, 356.0)
    var fit: float = minf(safe_size.x / base_size.x, safe_size.y / base_size.y)
    fit = clampf(fit, 0.6, 1.0)
    var s := Vector2(fit, fit)
    _card_bg.scale = s
    _title.scale = s
    _vbox.scale = s
    if _confirm_panel:
        _confirm_panel.scale = s

func show_game_over(final_score: int, final_distance: float) -> void:
    _final_score = final_score
    _final_distance = final_distance
    _pending_action = ""
    if _score_label:
        _score_label.text = "%s: %s" % [tr("Score"), str(final_score)]
    if _distance_label:
        _distance_label.text = "%s: %s" % [tr("Distance"), str(int(round(final_distance)))]
    if _confirm_panel:
        _confirm_panel.visible = false
    visible = true

func _on_retry_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    visible = false
    _pending_action = ""
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/Main.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_continue_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _pending_action = "home"
    if _confirm_panel and _confirm_message:
        _confirm_message.text = tr("Kembali ke menu utama?\nRun ini akan diakhiri.")
        _confirm_panel.visible = true

func _on_bonus_continue_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var _main_node = get_tree().current_scene
    if _main_node and _main_node.has_method("try_rewarded_continue"):
        _main_node.try_rewarded_continue()

func _on_confirm_yes_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    match _pending_action:
        "home":
            visible = false
            _pending_action = ""
            if Preloader and Preloader.has_method("set_next_scene"):
                Preloader.set_next_scene("res://scenes/MainMenu.tscn")
            await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
    if _confirm_panel:
        _confirm_panel.visible = false

func _on_confirm_no_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _pending_action = ""
    if _confirm_panel:
        _confirm_panel.visible = false
