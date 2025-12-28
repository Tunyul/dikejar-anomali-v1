extends Control

func _ready() -> void:
	var bgm_slider := get_node_or_null("UI/VBox/BGMSlider") as HSlider
	var sfx_slider := get_node_or_null("UI/VBox/SFXSlider") as HSlider
	var bgm_mute := get_node_or_null("UI/VBox/BGMMute") as CheckBox
	var sfx_mute := get_node_or_null("UI/VBox/SFXMute") as CheckBox
	var close_btn := get_node_or_null("UI/Panel/CloseButton") as BaseButton
	var bgm_volume: float = 0.8
	var sfx_volume: float = 0.8
	var bgm_muted: bool = false
	var sfx_muted: bool = false
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err == OK:
		bgm_volume = float(cfg.get_value("settings", "bgm_volume", 0.8))
		sfx_volume = float(cfg.get_value("settings", "sfx_volume", 0.8))
		bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))
		sfx_muted = bool(cfg.get_value("settings", "sfx_muted", false))
	if bgm_slider:
		bgm_slider.min_value = 0.0
		bgm_slider.max_value = 1.0
		bgm_slider.step = 0.01
		bgm_slider.value = bgm_volume
		bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	if sfx_slider:
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.step = 0.01
		sfx_slider.value = sfx_volume
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if bgm_mute:
		bgm_mute.button_pressed = bgm_muted
		bgm_mute.toggled.connect(_on_bgm_mute_toggled)
	if sfx_mute:
		sfx_mute.button_pressed = sfx_muted
		sfx_mute.toggled.connect(_on_sfx_mute_toggled)
	if close_btn:
		close_btn.pressed.connect(_on_back_pressed)
	if get_tree().current_scene != self:
		var ui := get_node_or_null("UI")
		if ui:
			ui.visible = false
		visible = false
	var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
	var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
	if ui_font:
		_apply_ui_font(self, ui_font)
	if title_font:
		var title_label := get_node_or_null("UI/VBox/TitleLabel") as Label
		if title_label:
			title_label.add_theme_font_override("font", title_font)

func _on_bgm_volume_changed(v: float) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "bgm_volume", v)
	cfg.save("user://save.cfg")

func _on_sfx_volume_changed(v: float) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "sfx_volume", v)
	cfg.save("user://save.cfg")

func _on_bgm_mute_toggled(pressed: bool) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "bgm_muted", pressed)
	cfg.save("user://save.cfg")

func _on_sfx_mute_toggled(pressed: bool) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "sfx_muted", pressed)
	cfg.save("user://save.cfg")

func show_overlay() -> void:
	var ui := get_node_or_null("UI")
	if ui:
		ui.visible = true
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().current_scene == self:
		return
	if not visible:
		return
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var panel := get_node_or_null("UI/Panel") as Control
	if panel == null:
		return
	var rect := panel.get_global_rect()
	if rect.has_point(mb.position):
		return
	_on_back_pressed()

func _on_back_pressed() -> void:
	if get_tree().current_scene == self:
		if Preloader and Preloader.has_method("set_next_scene"):
			Preloader.set_next_scene("res://scenes/MainMenu.tscn")
		await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
		return
	var ui := get_node_or_null("UI")
	if ui:
		ui.visible = false
	visible = false

func _apply_ui_font(node: Node, font: Font) -> void:
	if node is Label:
		(node as Label).add_theme_font_override("font", font)
	elif node is BaseButton:
		(node as BaseButton).add_theme_font_override("font", font)
	for child in node.get_children():
		if child is Node:
			_apply_ui_font(child, font)
