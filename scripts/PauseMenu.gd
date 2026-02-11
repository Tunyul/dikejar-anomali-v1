extends Control

var _title: Control = null
var _vbox: Control = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
    visible = false
    _title = get_node_or_null("Title") as Control
    _vbox = get_node_or_null("VBox") as Control
    var resume := get_node_or_null("VBox/ResumeButton")
    var restart := get_node_or_null("VBox/RestartButton")
    var menu := get_node_or_null("VBox/MenuButton")
    var missions := get_node_or_null("VBox/MissionsButton")
    var bgm := get_node_or_null("VBox/BGMVolume")
    var sfx := get_node_or_null("VBox/SFXVolume")
    var bgm_mute := get_node_or_null("VBox/BGMMute")
    var sfx_mute := get_node_or_null("VBox/SFXMute")
    if resume:
        resume.pressed.connect(_on_resume_pressed)
    if restart:
        restart.pressed.connect(_on_restart_pressed)
    if menu:
        menu.pressed.connect(_on_menu_pressed)
    if missions:
        missions.pressed.connect(_on_missions_pressed)
    if bgm and bgm is HSlider:
        (bgm as HSlider).value_changed.connect(_on_bgm_changed)
    if sfx and sfx is HSlider:
        (sfx as HSlider).value_changed.connect(_on_sfx_changed)
    if bgm_mute and bgm_mute is CheckBox:
        (bgm_mute as CheckBox).toggled.connect(_on_bgm_mute_toggled)
    if sfx_mute and sfx_mute is CheckBox:
        (sfx_mute as CheckBox).toggled.connect(_on_sfx_mute_toggled)

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
    if _title == null or _vbox == null:
        return
    var safe := Rect2(Vector2.ZERO, vp)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))

    var margin := 16.0
    var safe_size := Vector2(maxf(safe.size.x - margin * 2.0, 1.0), maxf(safe.size.y - margin * 2.0, 1.0))
    var base_size := Vector2(592.0, 400.0)
    var fit: float = minf(safe_size.x / base_size.x, safe_size.y / base_size.y)
    fit = clampf(fit, 0.6, 1.0)
    var s := Vector2(fit, fit)
    _title.scale = s
    _vbox.scale = s

func _on_resume_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("resume_game"):
        main.resume_game()

func _on_restart_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("restart_game"):
        var pm := self
        pm.visible = false
        main.restart_game()

func _on_menu_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("return_to_main_menu"):
        main.return_to_main_menu()

func _on_missions_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("open_missions_menu"):
        main.open_missions_menu()

func _on_bgm_changed(v: float) -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("set_bgm_volume"):
        main.set_bgm_volume(v)

func _on_sfx_changed(v: float) -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("set_sfx_volume"):
        main.set_sfx_volume(v)

func _on_bgm_mute_toggled(pressed: bool) -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("set_bgm_muted"):
        main.set_bgm_muted(pressed)

func _on_sfx_mute_toggled(pressed: bool) -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("set_sfx_muted"):
        main.set_sfx_muted(pressed)
