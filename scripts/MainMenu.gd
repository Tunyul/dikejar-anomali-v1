extends Control


func _ready() -> void:
	var play := get_node_or_null("UI/CenterContainer/VBox/PlayButton")
	var quit := get_node_or_null("UI/CenterContainer/VBox/QuitButton")
	var stats := get_node_or_null("UI/CenterContainer/VBox/StatsLabel")
	if play:
		play.pressed.connect(_on_play_pressed)
	if quit:
		quit.pressed.connect(_on_quit_pressed)
	if stats and stats is Label:
		var cfg := ConfigFile.new()
		var err := cfg.load("user://save.cfg")
		if err == OK:
			var best := int(cfg.get_value("progress", "best_score", 0))
			var coins := int(cfg.get_value("progress", "total_coins", 0))
			(stats as Label).text = "Best: " + str(best) + " | Coins: " + str(coins)
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

func _on_quit_pressed() -> void:
	print("QuitButton ditekan")
	get_tree().quit()
