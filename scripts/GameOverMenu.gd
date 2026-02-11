extends Control

@onready var score_label: Label = get_node_or_null("VBox/ScoreLabel")
@onready var distance_label: Label = get_node_or_null("VBox/DistanceLabel")
@onready var confirm_panel: Control = get_node_or_null("ConfirmPanel")
@onready var confirm_message: Label = get_node_or_null("ConfirmPanel/Message")
@onready var confirm_yes: BaseButton = get_node_or_null("ConfirmPanel/Buttons/YesButton")
@onready var confirm_no: BaseButton = get_node_or_null("ConfirmPanel/Buttons/NoButton")
@onready var _card_bg: Control = get_node_or_null("CardBackground")
@onready var _title: Control = get_node_or_null("Title")
@onready var _vbox: Control = get_node_or_null("VBox")

var _pending_action: String = ""
var _final_score: int = 0
var _final_distance: float = 0.0
var _last_viewport_size: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
    if name == "GameOverMenu":
        visible = false
    else:
        visible = true
    if confirm_message:
        confirm_message.add_theme_color_override("font_color", Color(0.2, 0.1, 0, 1))
        confirm_message.add_theme_font_size_override("font_size", 24)
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

    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        var title_label := get_node_or_null("Title") as Label
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
    if confirm_panel:
        confirm_panel.scale = s

func show_game_over(final_score: int, final_distance: float) -> void:
    _final_score = final_score
    _final_distance = final_distance
    _pending_action = ""
    if score_label:
        score_label.text = "%s: %s" % [tr("Score"), str(final_score)]
    if distance_label:
        distance_label.text = "%s: %s" % [tr("Distance"), str(int(round(final_distance)))]
    if confirm_panel:
        confirm_panel.visible = false
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
    if confirm_panel and confirm_message:
        confirm_message.text = tr("Kembali ke menu utama?\nRun ini akan diakhiri.")
        confirm_panel.visible = true

func _on_bonus_continue_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _pending_action = "bonus"
    if confirm_panel and confirm_message:
        confirm_message.text = tr("Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini.")
        confirm_panel.visible = true

func _on_confirm_yes_pressed() -> void:
    TransitionManager.play_sfx(&"click")
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
    TransitionManager.play_sfx(&"click")
    _pending_action = ""
    if confirm_panel:
        confirm_panel.visible = false
