extends Control

func _ready() -> void:
    visible = false
    var resume := get_node_or_null("VBox/ResumeButton")
    var restart := get_node_or_null("VBox/RestartButton")
    var menu := get_node_or_null("VBox/MenuButton")
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
    if bgm and bgm is HSlider:
        (bgm as HSlider).value_changed.connect(_on_bgm_changed)
    if sfx and sfx is HSlider:
        (sfx as HSlider).value_changed.connect(_on_sfx_changed)
    if bgm_mute and bgm_mute is CheckBox:
        (bgm_mute as CheckBox).toggled.connect(_on_bgm_mute_toggled)
    if sfx_mute and sfx_mute is CheckBox:
        (sfx_mute as CheckBox).toggled.connect(_on_sfx_mute_toggled)

func _on_resume_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("resume_game"):
        main.resume_game()

func _on_restart_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("restart_game"):
        var pm := self
        pm.visible = false
        main.restart_game()

func _on_menu_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("return_to_main_menu"):
        main.return_to_main_menu()

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
