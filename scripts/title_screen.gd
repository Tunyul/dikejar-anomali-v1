extends Control

@export var title_text: String = "DIKEJAR ANOMALI"
@export var title_texture: Texture2D
@export var base_width: int = 1280
@export var base_height: int = 720
@export var start_button_text: String = "MULAI"
@export var quit_button_text: String = "KELUAR"

@onready var title_label: TextureRect = $CenterContainer/VBoxContainer/TitleLabel
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
@onready var coins_label: Label = $CenterContainer/VBoxContainer/CoinsLabel
@onready var hint_label: Label = $CenterContainer/VBoxContainer/HintLabel
@onready var content_panel: Panel = $CenterContainer/ContentPanel

signal start_game_requested
signal quit_game_requested

func _ready() -> void:
	if title_label:
		if title_texture != null:
			title_label.texture = title_texture
	
	if start_button:
		start_button.text = start_button_text
		start_button.pressed.connect(_on_start_pressed)
	
	if quit_button:
		quit_button.text = quit_button_text
		quit_button.pressed.connect(_on_quit_pressed)
	if stats_label:
		stats_label.text = "Skor Terakhir: 0 | Skor Terbaik: 0"
	if coins_label:
		coins_label.text = "Koin Terakhir: 0 | Total Koin: 0"

	_apply_responsive_layout()
	var vp := get_viewport()
	if vp != null:
		vp.size_changed.connect(_apply_responsive_layout)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_ENTER or key == KEY_SPACE:
			_on_start_pressed()

func _on_start_pressed() -> void:
	emit_signal("start_game_requested")
	hide()

func _on_quit_pressed() -> void:
	emit_signal("quit_game_requested")

func show_title() -> void:
	show()
	if start_button:
		start_button.grab_focus()

func hide_title() -> void:
	hide()

func set_stats(best_score: int, last_score: int, last_coins: int, total_coins: int) -> void:
	if stats_label:
		stats_label.text = "Skor Terakhir: %d | Skor Terbaik: %d" % [last_score, best_score]
	if coins_label:
		coins_label.text = "Koin Terakhir: %d | Total Koin: %d" % [last_coins, total_coins]

func _apply_responsive_layout() -> void:
	var rect := get_viewport().get_visible_rect()
	var vw: float = rect.size.x
	var vh: float = rect.size.y
	var sx: float = vw / float(base_width)
	var sy: float = vh / float(base_height)
	var s: float = max(0.6, min(1.8, min(sx, sy)))
	var vbox: VBoxContainer = $CenterContainer/VBoxContainer
	if vbox:
		vbox.set("theme_override_constants/separation", int(40 * s))
	if title_label:
		var tw: float = vw * 0.35
		var th: float = vh * 0.18
		title_label.custom_minimum_size = Vector2(tw, th)
	if stats_label:
		stats_label.add_theme_font_size_override("font_size", int(26 * s))
	if coins_label:
		coins_label.add_theme_font_size_override("font_size", int(26 * s))
	if hint_label:
		hint_label.add_theme_font_size_override("font_size", int(20 * s))
	if start_button:
		start_button.custom_minimum_size = Vector2(vw * 0.4, vh * 0.09)
		start_button.add_theme_font_size_override("font_size", int(32 * s))
	if quit_button:
		quit_button.custom_minimum_size = Vector2(vw * 0.4, vh * 0.09)
		quit_button.add_theme_font_size_override("font_size", int(32 * s))
	if content_panel:
		content_panel.custom_minimum_size = Vector2(vw * 0.65, vh * 0.55)
