extends Control

func _ready() -> void:
	var back := get_node_or_null("UI/VBox/BackButton") as BaseButton
	if back:
		back.pressed.connect(_on_back_pressed)
	var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
	var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
	if ui_font:
		_apply_ui_font(self, ui_font)
	if title_font:
		var title_label := get_node_or_null("UI/VBox/TitleLabel") as Label
		if title_label:
			title_label.add_theme_font_override("font", title_font)

func _on_back_pressed() -> void:
	if Preloader and Preloader.has_method("set_next_scene"):
		Preloader.set_next_scene("res://scenes/MainMenu.tscn")
	await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _apply_ui_font(node: Node, font: Font) -> void:
	if node is Label:
		(node as Label).add_theme_font_override("font", font)
	elif node is BaseButton:
		(node as BaseButton).add_theme_font_override("font", font)
	for child in node.get_children():
		if child is Node:
			_apply_ui_font(child, font)
