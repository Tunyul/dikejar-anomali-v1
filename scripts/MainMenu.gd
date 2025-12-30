extends Control


func _ready() -> void:
	var play := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/PlayButton")
	if play == null:
		play = get_node_or_null("UI/CenterContainer/VBox/PlayButton")
	var shop := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/ShopButton")
	var settings := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/SettingsButton")
	var player_hud := get_node_or_null("UI/PlayerHUD")
	var coin_hud := get_node_or_null("UI/CoinHUD")
	var score_hud := get_node_or_null("UI/ScoreHUD")
	var daily_button := get_node_or_null("UI/DailyButton")
	var ver := get_node_or_null("UI/VersionLabel")
	if play:
		play.pressed.connect(_on_play_pressed)
	if shop:
		shop.pressed.connect(_on_shop_pressed)
	if settings:
		settings.pressed.connect(_on_settings_pressed)
	if daily_button:
		(daily_button as BaseButton).pressed.connect(_on_daily_pressed)
	if coin_hud or score_hud or player_hud:
		var cfg := ConfigFile.new()
		var err := cfg.load("user://save.cfg")
		if err == OK:
			if coin_hud:
				var coins := int(cfg.get_value("progress", "total_coins", 0))
				var coin_label := coin_hud.get_node_or_null("CoinLabel") as Label
				if coin_label:
					coin_label.text = str(coins)
			if score_hud:
				var best := int(cfg.get_value("progress", "best_score", 0))
				var score_label := score_hud.get_node_or_null("ScoreLabel") as Label
				if score_label:
					score_label.text = str(best)
			if player_hud:
				var level := int(cfg.get_value("progress", "player_level", 1))
				var xp := int(cfg.get_value("progress", "player_xp", 0))
				var xp_required := int(cfg.get_value("progress", "player_xp_required", 100))
				var level_label := player_hud.get_node_or_null("LevelLabel") as Label
				var xp_bar := player_hud.get_node_or_null("XPBar") as ProgressBar
				var xp_label := player_hud.get_node_or_null("XPLabel") as Label
				if level_label:
					level_label.text = "Lv " + str(level)
				if xp_bar:
					if xp_required <= 0:
						xp_required = 1
					xp_bar.max_value = float(xp_required)
					xp_bar.value = clampf(float(xp), 0.0, float(xp_required))
				if xp_label:
					xp_label.text = str(xp) + "/" + str(xp_required) + " XP"
	if daily_button and daily_button is BaseButton:
		_refresh_daily_button_style(daily_button as BaseButton)
	if ver and ver is Label:
		(ver as Label).text = ProjectSettings.get_setting("application/config/version", "v0.1.0")
	var ground := get_node_or_null("Ground")
	if ground:
		if ground.has_method("set_title_mode"):
			ground.set_title_mode(true)
		if ground.has_method("generate_random"):
			ground.generate_random()
		if ground.has_method("set_movement_enabled"):
			ground.set_movement_enabled(true)
		if ground.has_method("set_speed_limits"):
			ground.set_speed_limits(0.0, 300.0)
		if ground.has_method("set_speed"):
			ground.set_speed(34.0)
	var parallax := get_node_or_null("ParallaxBackground")
	if parallax:
		if parallax.has_method("set_movement_enabled"):
			parallax.set_movement_enabled(true)
		if parallax.has_method("set_speed"):
			parallax.set_speed(200.0)
	var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
	if ui_font:
		_apply_ui_font(self, ui_font)

func _on_play_pressed() -> void:
	print("PlayButton ditekan")
	var ui := get_node_or_null("UI")
	if ui:
		ui.visible = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if Preloader and Preloader.has_method("set_next_scene"):
		Preloader.set_next_scene("res://scenes/Main.tscn")
	await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ShopMenu.tscn")

func _on_settings_pressed() -> void:
	var settings_menu := get_node_or_null("SettingsMenu")
	if settings_menu == null:
		var packed := load("res://scenes/SettingsMenu.tscn") as PackedScene
		if packed:
			settings_menu = packed.instantiate()
			(settings_menu as Node).name = "SettingsMenu"
			add_child(settings_menu)
	if settings_menu:
		if settings_menu.has_method("show_overlay"):
			settings_menu.show_overlay()
		else:
			(settings_menu as CanvasItem).visible = true

func _on_daily_pressed() -> void:
	var ui := get_node_or_null("UI")
	if ui:
		ui.visible = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if Preloader and Preloader.has_method("set_next_scene"):
		Preloader.set_next_scene("res://scenes/DailyMissionsMenu.tscn")
	await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _refresh_missions_panel(panel: Node) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		panel.visible = false
		return
	var missions_value = cfg.get_value("missions", "list", [])
	if not (missions_value is Array):
		panel.visible = false
		return
	var missions: Array = missions_value
	var max_slots := 3
	for i in range(max_slots):
		var slot := panel.get_node_or_null("Mission" + str(i + 1))
		if slot == null:
			continue
		if i >= missions.size():
			slot.visible = false
			continue
		var m = missions[i]
		if not (m is Dictionary):
			slot.visible = false
			continue
		var name_label := slot.get_node_or_null("Name") as Label
		var bar := slot.get_node_or_null("Bar") as ProgressBar
		var mname: String = String(m.get("name", ""))
		var target: float = float(m.get("target", 1))
		if target <= 0.0:
			target = 1.0
		var prog: float = float(m.get("progress", 0))
		if name_label:
			name_label.text = mname
		if bar:
			bar.max_value = target
			bar.value = clampf(prog, 0.0, target)

func _refresh_biome_label(label: Label) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	var max_distance: int = 0
	if err == OK:
		max_distance = int(cfg.get_value("missions", "max_distance", 0))
	var names: Array = ["Hills", "City", "Lab Anomali"]
	var thresholds: Array = [0, 1500, 3500]
	var current_index := 0
	if max_distance >= int(thresholds[2]):
		current_index = 2
	elif max_distance >= int(thresholds[1]):
		current_index = 1
	else:
		current_index = 0
	var lines: Array = []
	for i in range(names.size()):
		var status := "Terkunci"
		if max_distance >= int(thresholds[i]):
			status = "Terbuka"
		var active_marker := ""
		if i == current_index and max_distance >= int(thresholds[i]):
			active_marker = " (Aktif)"
		lines.append(String(names[i]) + " - " + status + active_marker)
	label.text = "\n".join(lines)

func _refresh_daily_button_style(button: BaseButton) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err != OK:
		return
	var missions_value = cfg.get_value("missions", "list", [])
	if not (missions_value is Array):
		return
	var missions: Array = missions_value
	var has_completed := false
	for m in missions:
		if not (m is Dictionary):
			continue
		var target: float = float(m.get("target", 0))
		if target <= 0.0:
			continue
		var prog: float = float(m.get("progress", 0))
		if prog >= target:
			has_completed = true
			break
	if not has_completed:
		return
	var tex := load("res://assets/tombol/tombol_mission_ceklis_202x168.png") as Texture2D
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	button.add_theme_stylebox_override("normal", sb)
	button.add_theme_stylebox_override("hover", sb)
	button.add_theme_stylebox_override("pressed", sb)
	button.add_theme_stylebox_override("focus", sb)

func _apply_ui_font(node: Node, font: Font) -> void:
	if node is Label:
		(node as Label).add_theme_font_override("font", font)
	elif node is BaseButton:
		(node as BaseButton).add_theme_font_override("font", font)
	for child in node.get_children():
		if child is Node:
			_apply_ui_font(child, font)
